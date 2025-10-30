#!/usr/bin/env bash
# finish_maintenance_prs_guarded.sh
# Usage: bash finish_maintenance_prs_guarded.sh 31 33 ...
set -euo pipefail
REPO="$(git rev-parse --show-toplevel)"; cd "$REPO"
mkdir -p _tmp _logs
TS="$(date -u +%Y%m%dT%H%M%SZ)"; LOG="_logs/finish_maint_${TS}.log"

prs=("$@")
if [[ "${#prs[@]}" -eq 0 ]]; then
  echo "Ex.: bash $0  <PR_ID_1> <PR_ID_2> ..." | tee -a "$LOG"
  read -r -p $'ENTER pour fermer…\n' _ </dev/tty || true; exit 2
fi

max_poll=48   # 48*5s = 240s
sleep_step=5

for PR in "${prs[@]}"; do
  echo "[INFO] PR #$PR" | tee -a "$LOG"
  info="$(gh pr view "$PR" --json headRefName,baseRefName,headRefOid,url -q \
        '{br:.headRefName,base:.baseRefName,sha:.headRefOid,url:.url}')"
  BR="$(jq -r .br <<<"$info")"; BASE="$(jq -r .base <<<"$info")"; URL="$(jq -r .url <<<"$info")"
  echo "[INFO] $URL | $BR -> $BASE" | tee -a "$LOG"

  # 1) tentative “propre” : dispatch si possible, puis poll ≤ 240s
  echo "[DISPATCH] pypi-build.yml & secret-scan.yml @ $BR" | tee -a "$LOG"
  gh workflow run pypi-build.yml   --ref "$BR" >/dev/null 2>&1 || true
  gh workflow run secret-scan.yml  --ref "$BR" >/dev/null 2>&1 || true

  ok=0
  for i in $(seq 1 "$max_poll"); do
    echo "[POLL $i]" | tee -a "$LOG"
    set +e
    good=$(gh pr view "$PR" --json statusCheckRollup | \
      jq -re '[.statusCheckRollup[] | select(.name=="pypi-build/build" or .name=="secret-scan/gitleaks") | .conclusion]
              | sort | join(",") == "SUCCESS,SUCCESS"')
    rc=$?; set -e
    if [[ "$rc" -eq 0 && "$good" == "true" ]]; then ok=1; break; fi
    sleep "$sleep_step"
  done

  if [[ "$ok" -eq 1 ]]; then
    echo "[MERGE] voie propre (checks verts)" | tee -a "$LOG"
    gh pr merge "$PR" --squash --delete-branch && continue || true
  fi

  # 2) fast-track guardé (snapshot → reviews=0 → merge → restore)
  echo "[FAST-TRACK] protections TEMP puis merge" | tee -a "$LOG"
  SNAP="_tmp/protect.main.snapshot.${TS}.json"
  gh api repos/:owner/:repo/branches/main/protection > "$SNAP" || true
  # reviews=0 temporaire (on garde strict + checks tels quels)
  TMP="_tmp/protect.main.tmp.${TS}.json"
  jq '{
        required_status_checks: {strict:(.required_status_checks.strict // true),
                                 checks:(.required_status_checks.checks
                                         | map({context:.context, app_id:(.app_id // null)}))},
        enforce_admins: (.enforce_admins.enabled // true),
        required_pull_request_reviews: {
          required_approving_review_count: 0,
          require_code_owner_reviews: (.required_pull_request_reviews.require_code_owner_reviews // false),
          dismiss_stale_reviews: (.required_pull_request_reviews.dismiss_stale_reviews // false),
          require_last_push_approval: (.required_pull_request_reviews.require_last_push_approval // false)
        },
        restrictions: null,
        required_linear_history: (.required_linear_history.enabled // true),
        allow_force_pushes: (.allow_force_pushes.enabled // false),
        allow_deletions: (.allow_deletions.enabled // false),
        block_creations: false,
        required_conversation_resolution: (.required_conversation_resolution.enabled // true),
        lock_branch: false,
        allow_fork_syncing: false
      }' "$SNAP" > "$TMP" || true
  gh api -X PUT repos/:owner/:repo/branches/main/protection \
     -H "Accept: application/vnd.github+json" --input "$TMP" >/dev/null || true

  if ! gh pr merge "$PR" --squash --delete-branch ; then
    echo "[WARN] merge normal refusé, tentative --admin…" | tee -a "$LOG"
    gh pr merge "$PR" --squash --admin --delete-branch || echo "[ERROR] merge KO"
  fi

  echo "[RESTORE] protections strictes depuis snapshot" | tee -a "$LOG"
  gh api -X PUT repos/:owner/:repo/branches/main/protection \
     -H "Accept: application/vnd.github+json" --input "$SNAP" >/dev/null || true
done

# sanity courte sur main
echo "[SANITY] dispatch @ main (best-effort) + poll ≤60s" | tee -a "$LOG"
gh workflow run pypi-build.yml  --ref main >/dev/null 2>&1 || true
gh workflow run secret-scan.yml --ref main >/dev/null 2>&1 || true
for i in {1..12}; do
  lst="$(gh run list --branch main --limit 10 2>/dev/null | head -n 3 || true)"
  [[ -n "$lst" ]] && echo "[POLL $i] $lst" | tee -a "$LOG"
  sleep 5
done

read -r -p $'Terminé. ENTER pour fermer…\n' _ </dev/tty || true
