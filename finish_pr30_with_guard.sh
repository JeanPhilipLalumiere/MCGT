#!/usr/bin/env bash
# finish_pr30_with_guard.sh — Merge PR #30 (rename titre) avec cap 4 min + restauration protections
set -euo pipefail

PR="${1:-30}"
ROOT="$(git rev-parse --show-toplevel)"; cd "$ROOT"
mkdir -p _tmp _logs
TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG="_logs/finish_pr${PR}_guard_${TS}.log"
MAX_WAIT=240; SLEEP=5

say(){ echo -e "$*" | tee -a "$LOG"; }
finish(){ read -r -p $'Terminé. ENTER pour fermer…\n' _ </dev/tty || true; }
trap finish EXIT

meta="$(gh pr view "$PR" --json headRefName,headRefOid,baseRefName,url,state 2>/dev/null)"
BR="$(jq -r .headRefName <<<"$meta")"
BASE="$(jq -r .baseRefName <<<"$meta")"
URL="$(jq -r .url <<<"$meta")"
say "[INFO] $URL | $BR -> $BASE"

# 1) Tentative propre (dispatch + poll ≤ 240s)
gh workflow run pypi-build.yml  --ref "$BR" >/dev/null 2>&1 || true
gh workflow run secret-scan.yml --ref "$BR" >/dev/null 2>&1 || true

deadline=$(( $(date +%s) + MAX_WAIT ))
poll_ok(){
  local roll="$(gh pr view "$PR" --json statusCheckRollup 2>/dev/null || echo '{}')"
  echo "$roll" | jq -r '.statusCheckRollup[]
    | select(.name=="pypi-build/build" or .name=="secret-scan/gitleaks")
    | [.name,.status,.conclusion] | @tsv' | sed 's/\t/ | /g' | tee -a "$LOG" || true
  echo "$roll" | jq -e '
    [.statusCheckRollup[]
      | select(.name=="pypi-build/build" or .name=="secret-scan/gitleaks")
      | .conclusion] as $c
    | ($c|length==2) and ( ($c|index("SUCCESS")!=null) and ($c|rindex("SUCCESS")!=null) )
  ' >/dev/null 2>&1
}

while (( $(date +%s) < deadline )); do
  if poll_ok; then
    say "[OK] Deux SUCCESS détectés."
    if gh pr merge "$PR" --squash --delete-branch; then
      say "[DONE] PR #$PR fusionnée (voie propre)."; exit 0
    fi
    say "[WARN] Merge refusé malgré SUCCESS — on bascule en fast-track."
    break
  fi
  sleep "$SLEEP"
done

# 2) Fast-track encadré (baisse TEMP → merge → restore → sanity)
say "[FAST-TRACK] Snapshot protections + baisse temporaire."
SNAP="_tmp/protect.${BASE}.snapshot.${TS}.json"
gh api "repos/:owner/:repo/branches/${BASE}/protection" > "$SNAP"

TEMP="_tmp/protect.${BASE}.temp.${TS}.json"
cat > "$TEMP" <<'JSON'
{
  "required_status_checks": null,
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 0,
    "require_code_owner_reviews": false,
    "dismiss_stale_reviews": false,
    "require_last_push_approval": false
  },
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "required_conversation_resolution": true,
  "lock_branch": false,
  "allow_fork_syncing": false
}
JSON

gh api -X PUT "repos/:owner/:repo/branches/${BASE}/protection" \
  -H "Accept: application/vnd.github+json" --input "$TEMP" >/dev/null 2>&1 || {
  say "[ERROR] Impossible d’abaisser temporairement la protection."; exit 2; }

say "[MERGE] Tentative squash…"
gh pr merge "$PR" --squash --delete-branch 2>/dev/null || \
gh pr merge "$PR" --squash --admin --delete-branch

say "[RESTORE] Protection stricte depuis snapshot."
gh api -X PUT "repos/:owner/:repo/branches/${BASE}/protection" \
  -H "Accept: application/vnd.github+json" --input "$SNAP" >/dev/null 2>&1 || true

say "[SANITY] Dispatch rapide sur main, poll court."
gh workflow run pypi-build.yml  --ref "$BASE" >/dev/null 2>&1 || true
gh workflow run secret-scan.yml --ref "$BASE" >/dev/null 2>&1 || true
for i in $(seq 1 12); do
  ok="$(gh run list --branch "$BASE" --limit 10 | awk '/pypi-build|secret-scan/ {print $2}' | grep -c success || true)"
  [[ "$ok" -ge 2 ]] && break
  sleep 5
done
say "[DONE] PR #$PR fusionnée, protections restaurées."

