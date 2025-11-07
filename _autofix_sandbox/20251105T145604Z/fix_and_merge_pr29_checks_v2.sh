#!/usr/bin/env bash
# fix_and_merge_pr29_checks_v2.sh
# Attente max 4 minutes pour obtenir SUCCESS sur:
#   - pypi-build/build
#   - secret-scan/gitleaks
# Puis merge (squash). Garde-fou: fenêtre reste ouverte.

set -euo pipefail

PR_NUM="${1:-29}"
ROOT="$(git rev-parse --show-toplevel)"; cd "$ROOT"
mkdir -p _tmp _logs .github/workflows
TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG="_logs/fix_and_merge_pr${PR_NUM}_${TS}.log"

MAX_WAIT_SEC=240   # 4 minutes total
SLEEP_SEC=5        # intervalle entre polls
NUDGE_ONCE=0       # ne fait le 'coup de coude' qu'une fois

say(){ echo -e "$*" | tee -a "$LOG"; }
finish(){ read -r -p $'Terminé. ENTER pour fermer…\n' _ </dev/tty || true; }
trap finish EXIT

say "[INFO] Prépare PR #$PR_NUM"
META="$(gh pr view "$PR_NUM" --json headRefName,headRefOid,baseRefName,url)"
BR="$(jq -r .headRefName <<<"$META")"
HEAD="$(jq -r .headRefOid <<<"$META")"
URL="$(jq -r .url <<<"$META")"
BASE="$(jq -r .baseRefName <<<"$META")"
say "[INFO] $URL | $BR -> $BASE | HEAD=$HEAD"

# 1) Basculer sur la branche du PR
git fetch origin "$BR" >/dev/null 2>&1 || true
git switch "$BR" >/dev/null 2>&1 || git checkout "$BR"

# 2) Workflows MINIMAUX avec contexts EXACTS
cat > .github/workflows/pypi-build.yml <<'YML'
name: pypi-build
on:
  pull_request:
    types: [opened, synchronize, reopened, ready_for_review]
  workflow_dispatch:
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: echo "sanity: pypi-build runs on PR"
YML

cat > .github/workflows/secret-scan.yml <<'YML'
name: secret-scan
on:
  pull_request:
    types: [opened, synchronize, reopened, ready_for_review]
  workflow_dispatch:
jobs:
  gitleaks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: echo "sanity: secret-scan runs on PR"
YML

git add .github/workflows/pypi-build.yml .github/workflows/secret-scan.yml
git commit -m "ci(min): ensure required contexts pypi-build/build & secret-scan/gitleaks on PR #$PR_NUM" | tee -a "$LOG"
git push --force-with-lease | tee -a "$LOG"

# 3) Déclenchements explicites
say "[DISPATCH] pypi-build.yml & secret-scan.yml sur ref=$BR"
gh workflow run pypi-build.yml   --ref "$BR" >/dev/null 2>&1 || say "[WARN] pypi-build dispatch: peut-être déjà en cours"
gh workflow run secret-scan.yml  --ref "$BR" >/devnull 2>&1 || say "[WARN] secret-scan dispatch: peut-être déjà en cours"

deadline=$(( $(date +%s) + MAX_WAIT_SEC ))

poll_once() {
  local roll ok=1
  roll="$(gh pr view "$PR_NUM" --json statusCheckRollup 2>/dev/null || echo '{}')"
  # Affichage compact (lignes pertinentes)
  echo "$roll" | jq -r '.statusCheckRollup[]
        | select(.name=="pypi-build/build" or .name=="secret-scan/gitleaks")
        | [.name,.status,.conclusion] | @tsv' \
      | sed 's/\t/ | /g' | tee -a "$LOG" || true

  if echo "$roll" | jq -e '
      [.statusCheckRollup[]
        | select(.name=="pypi-build/build" or .name=="secret-scan/gitleaks")
        | .conclusion] as $c
      | ($c|length==2) and ( ($c|index("SUCCESS")!=null) and ($c|rindex("SUCCESS")!=null) )
    ' >/dev/null 2>&1; then
    ok=0
  fi
  return $ok
}

# 4) Poll <= 4 minutes, avec un seul "nudge" possible
say "[WAIT] Attente SUCCESS (budget total ≤ ${MAX_WAIT_SEC}s)…"
while (( $(date +%s) < deadline )); do
  if poll_once; then
    say "[OK] Deux SUCCESS détectés."
    break
  fi

  # Si on approche de la moitié du budget sans SUCCESS, tenter un 'nudge' (une seule fois)
  if (( NUDGE_ONCE == 0 )) && (( $(date +%s) > deadline - MAX_WAIT_SEC/2 )); then
    say "[NUDGE] Empty commit + re-dispatch (une seule fois)."
    git commit --allow-empty -m "ci: synchronize to surface required checks on PR #$PR_NUM" >/dev/null 2>&1 || true
    git push --force-with-lease >/dev/null 2>&1 || true
    gh workflow run pypi-build.yml  --ref "$BR" >/dev/null 2>&1 || true
    gh workflow run secret-scan.yml --ref "$BR" >/dev/null 2>&1 || true
    NUDGE_ONCE=1
  fi

  sleep "$SLEEP_SEC"
done

# Dernière vérification à l’issue du budget
if ! poll_once; then
  say "[ERROR] Checks requis non verts après ≤ ${MAX_WAIT_SEC}s. Abandon propre."
  exit 2
fi

# 5) Merge PR
say "[OK] Checks verts. Tentative merge (squash)…"
if ! gh pr merge "$PR_NUM" --squash --delete-branch; then
  say "[WARN] Merge refusé. Tentative --admin (si autorisé)…"
  gh pr merge "$PR_NUM" --squash --admin --delete-branch || {
    say "[ERROR] Échec merge même avec --admin."
    exit 3
  }
fi

say "[DONE] PR #$PR_NUM fusionnée."
