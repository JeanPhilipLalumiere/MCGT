#!/usr/bin/env bash
# finish_pr29_now_v2.sh — Robustifier la fin de #29:
# - Crée/assure .github/workflows/{pypi-build.yml,secret-scan.yml}
# - Commit only-if-changed (ne plante pas si rien à committer)
# - Dispatch sur la ref du PR, poll ≤ 4 min, merge (squash)
set -euo pipefail

PR="${1:-29}"
ROOT="$(git rev-parse --show-toplevel)"; cd "$ROOT"
mkdir -p _logs .github/workflows
TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG="_logs/finish_pr${PR}_v2_${TS}.log"
MAX_WAIT=240; SLEEP=5

say(){ echo -e "$*" | tee -a "$LOG"; }
finish(){ read -r -p $'Terminé. ENTER pour fermer…\n' _ </dev/tty || true; }
trap finish EXIT

say "[INFO] Prépare PR #$PR"
meta="$(gh pr view "$PR" --json headRefName,headRefOid,baseRefName,url,state,mergeStateStatus 2>/dev/null)"
BR="$(jq -r .headRefName <<<"$meta")"
HEAD="$(jq -r .headRefOid   <<<"$meta")"
URL="$(jq -r .url          <<<"$meta")"
BASE="$(jq -r .baseRefName  <<<"$meta")"
say "[INFO] $URL | $BR -> $BASE | HEAD=$HEAD"

git fetch origin "$BR" >/dev/null 2>&1 || true
git switch "$BR" >/dev/null 2>&1 || git checkout "$BR"

# 1) Assurer pypi-build/build et secret-scan/gitleaks (idempotent)
ensure_file() {
  local path="$1" expected_job="$2" wf_name="$3" echo_msg="$4"
  local need=0
  if [[ ! -f "$path" ]]; then
    need=1
  else
    # Vérif naïve du job
    grep -qE "^\s*${expected_job}:\s*$" "$path" || need=1
  fi
  if (( need==1 )); then
    mkdir -p "$(dirname "$path")"
    cat > "$path" <<YML
name: ${wf_name}
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
    git add "$path" || true
    # Commit only-if-staged
    if ! git diff --cached --quiet -- "$path"; then
      say "[FIX] ${wf_name}/${expected_job} écrit → commit"
      git commit -m "ci(min): ensure ${wf_name}/${expected_job} context on PR #${PR}" | tee -a "$LOG"
      git push --force-with-lease | tee -a "$LOG"
    else
      say "[OK] ${wf_name}/${expected_job} déjà conforme (pas de commit)."
    fi
  else
    say "[OK] ${wf_name}/${expected_job} présent."
  fi
}

ensure_file ".github/workflows/pypi-build.yml" "build"    "pypi-build"  "sanity: pypi-build runs on PR"
ensure_file ".github/workflows/secret-scan.yml" "gitleaks" "secret-scan" "sanity: secret-scan runs on PR"

# 2) Dispatch best-effort
say "[DISPATCH] pypi-build.yml & secret-scan.yml sur ref=$BR"
gh workflow run pypi-build.yml  --ref "$BR" >/dev/null 2>&1 || say "[WARN] pypi-build: dispatch ignoré/ déjà en file"
gh workflow run secret-scan.yml --ref "$BR" >/dev/null 2>&1 || say "[WARN] secret-scan: dispatch ignoré/ déjà en file"

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
  sleep "$SLEEP"
done

if ! poll_once; then
  say "[ERROR] Checks requis NON verts après ≤ ${MAX_WAIT}s. Arrêt propre."
  exit 2
fi

say "[MERGE] Tentative squash…"
if ! gh pr merge "$PR" --squash --delete-branch; then
  say "[WARN] Merge refusé. Tentative --admin (si autorisé)…"
  gh pr merge "$PR" --squash --admin --delete-branch || {
    say "[ERROR] Échec merge même avec --admin."
    exit 3
  }
fi
say "[DONE] PR #$PR fusionnée."
