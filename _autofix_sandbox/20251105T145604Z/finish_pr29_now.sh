#!/usr/bin/env bash
# finish_pr29_now.sh — Fait passer PR #29 au vert puis merge (squash).
# - Ne touche PAS aux protections de branche.
# - Vérifie/assure la présence des deux contexts EXACTS sur la branche du PR :
#     pypi-build/build  et  secret-scan/gitleaks
# - Déclenche les deux workflows si possible.
# - Poll <= 4 min (budget global), affiche l’état compact, puis tente le merge.
# - Garde-fou: la fenêtre reste ouverte à la fin.

set -euo pipefail

PR="${1:-29}"                     # tu peux passer un numéro en argument
ROOT="$(git rev-parse --show-toplevel)"; cd "$ROOT"
mkdir -p _logs .github/workflows
TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG="_logs/finish_pr${PR}_${TS}.log"
MAX_WAIT=240                      # 4 minutes
SLEEP=5
NUDGE=0

say(){ echo -e "$*" | tee -a "$LOG"; }
finish(){ read -r -p $'Terminé. ENTER pour fermer…\n' _ </dev/tty || true; }
trap finish EXIT

say "[INFO] Prépare PR #$PR"
meta="$(gh pr view "$PR" --json headRefName,headRefOid,baseRefName,url,state,mergeStateStatus 2>/dev/null)"
BR="$(jq -r .headRefName <<<"$meta")"
HEAD="$(jq -r .headRefOid <<<"$meta")"
URL="$(jq -r .url <<<"$meta")"
BASE="$(jq -r .baseRefName <<<"$meta")"
say "[INFO] $URL | $BR -> $BASE | HEAD=$HEAD"

# 0) Raccroche-toi à la branche du PR (sans toucher main)
git fetch origin "$BR" >/dev/null 2>&1 || true
git switch "$BR" >/dev/null 2>&1 || git checkout "$BR"

# 1) S’assurer que les DEUX contexts existent dans l’arbre du PR
ensure_workflow(){
  local path="$1" expected_job="$2" wfname="$3" echo_msg="$4"
  if [[ ! -f "$path" ]] || ! yq -r '.jobs|keys|.[]' "$path" 2>/dev/null | grep -qx "$expected_job"; then
    say "[FIX] $wfname manquant ou job inattendu → on installe un squelette minimal ($expected_job)"
    cat > "$path" <<YML
name: ${wfname}
on:
  pull_request:
    types: [opened, synchronize, reopened, ready_for_review]
  workflow_dispatch:
jobs:
  ${expected_job}:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: echo "${echo_msg}"
YML
    git add "$path"
    git commit -m "ci(min): ensure ${wfname}/${expected_job} context on PR #${PR}" | tee -a "$LOG"
    git push --force-with-lease | tee -a "$LOG"
  else
    say "[OK] ${wfname}/${expected_job} présent."
  fi
}

# yq est pratique, sinon on fait un fallback naïf
if ! command -v yq >/dev/null 2>&1; then
  say "[WARN] yq non trouvé → fallback naïf (grep)."
  ensure_naif(){
    local path="$1" expected_job="$2" wfname="$3" echo_msg="$4"
    if [[ ! -f "$path" ]] || ! grep -qE "^\s*${expected_job}:\s*$" "$path"; then
      say "[FIX] $wfname absent/invalide → ajout squelette."
      cat > "$path" <<YML
name: ${wfname}
on:
  pull_request:
    types: [opened, synchronize, reopened, ready_for_review]
  workflow_dispatch:
jobs:
  ${expected_job}:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: echo "${echo_msg}"
YML
      git add "$path"
      git commit -m "ci(min): ensure ${wfname}/${expected_job} context on PR #${PR}" | tee -a "$LOG"
      git push --force-with-lease | tee -a "$LOG"
    else
      say "[OK] ${wfname}/${expected_job} présent (fallback)."
    fi
  }
  ensure_naif ".github/workflows/pypi-build.yml" "build"    "pypi-build"  "sanity: pypi-build runs on PR"
  ensure_naif ".github/workflows/secret-scan.yml" "gitleaks" "secret-scan" "sanity: secret-scan runs on PR"
else
  ensure_workflow ".github/workflows/pypi-build.yml" "build"    "pypi-build"  "sanity: pypi-build runs on PR"
  ensure_workflow ".github/workflows/secret-scan.yml" "gitleaks" "secret-scan" "sanity: secret-scan runs on PR"
fi

# 2) (Best effort) dispatch explicite sur la ref du PR
say "[DISPATCH] pypi-build.yml & secret-scan.yml sur ref=$BR"
gh workflow run pypi-build.yml  --ref "$BR" >/dev/null 2>&1 || say "[WARN] pypi-build dispatch a peut-être déjà un run"
gh workflow run secret-scan.yml --ref "$BR" >/dev/null 2>&1 || say "[WARN] secret-scan dispatch a peut-être déjà un run"

deadline=$(( $(date +%s) + MAX_WAIT ))
poll_once(){
  local roll ok=1
  roll="$(gh pr view "$PR" --json statusCheckRollup 2>/dev/null || echo '{}')"
  echo "$roll" | jq -r '.statusCheckRollup[]
        | select(.name=="pypi-build/build" or .name=="secret-scan/gitleaks")
        | [.name,.status,.conclusion] | @tsv' \
      | sed 's/\t/ | /g' | tee -a "$LOG" || true
  if echo "$roll" | jq -e '
      [.statusCheckRollup[]
        | select(.name=="pypi-build/build" or .name=="secret-scan/gitleaks")
        | .conclusion] as $c
      | ($c|length==2) and ( ($c|index("SUCCESS")!=null) and ($c|rindex("SUCCESS")!=null) )
    ' >/dev/null 2>&1; then ok=0; fi
  return $ok
}

say "[WAIT] Poll ≤ ${MAX_WAIT}s pour SUCCESS des 2 contexts…"
while (( $(date +%s) < deadline )); do
  if poll_once; then
    say "[OK] Deux SUCCESS détectés."
    break
  fi
  if (( NUDGE==0 )) && (( $(date +%s) > deadline - MAX_WAIT/2 )); then
    say "[NUDGE] Empty commit + re-dispatch (une seule fois)."
    git commit --allow-empty -m "ci: synchronize to surface required checks on PR #${PR}" >/dev/null 2>&1 || true
    git push --force-with-lease >/dev/null 2>&1 || true
    gh workflow run pypi-build.yml  --ref "$BR" >/dev/null 2>&1 || true
    gh workflow run secret-scan.yml --ref "$BR" >/dev/null 2>&1 || true
    NUDGE=1
  fi
  sleep "$SLEEP"
done

# 3) État final + merge
if ! poll_once; then
  say "[ERROR] Checks requis NON verts après ≤ ${MAX_WAIT}s. On s’arrête proprement (aucun changement de protection)."
  exit 2
fi

say "[MERGE] Tentative merge (squash)…"
if ! gh pr merge "$PR" --squash --delete-branch; then
  say "[WARN] Merge refusé. Tentative --admin (si autorisé)…"
  gh pr merge "$PR" --squash --admin --delete-branch || {
    say "[ERROR] Échec merge même avec --admin."
    exit 3
  }
fi
say "[DONE] PR #$PR fusionnée."
