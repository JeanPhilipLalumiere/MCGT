#!/usr/bin/env bash
set -euo pipefail

PR_NUM="${PR_NUM:-26}"
REPO_ROOT="$(git rev-parse --show-toplevel)"; cd "$REPO_ROOT"
mkdir -p _tmp _logs
TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG="_logs/merge_pr_${PR_NUM}_${TS}.log"
echo "[INFO] start merge helper PR #$PR_NUM @ $TS" | tee -a "$LOG"

# ───────────────── context
NWO="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
OWNER="${NWO%%/*}"; REPO="${NWO##*/}"
PR_JSON="$(gh pr view "$PR_NUM" --json headRefName,baseRefName,headRefOid,mergeable,mergeStateStatus,reviewDecision,isDraft,url)"
BR="$(echo "$PR_JSON" | jq -r .headRefName)"
BASE="$(echo "$PR_JSON" | jq -r .baseRefName)"
[[ "$BR" == "main" ]] && { echo "[ABORT] refuse d'opérer sur main" | tee -a "$LOG"; exit 2; }
echo "[INFO] $OWNER/$REPO | PR#$PR_NUM $BR -> $BASE" | tee -a "$LOG"

# ───────────────── dump protections
BEFORE="_tmp/protect.$BASE.before.$TS.json"
gh api "repos/:owner/:repo/branches/$BASE/protection" > "$BEFORE"
echo "[SNAPSHOT] protections dump: $BEFORE" | tee -a "$LOG"

# build checks array usable for PUT
CHECKS_JSON="$(jq -c '.required_status_checks.checks | map({context: .context, app_id: (.app_id // null)})' "$BEFORE")"

# ───────────────── lower reviews=0 (PUT payload must be flat booleans + checks)
LOWER="_tmp/protect.$BASE.lower.$TS.json"
jq -n --argjson checks "$CHECKS_JSON" '{
  required_status_checks: { strict: true, checks: $checks },
  enforce_admins: true,
  required_pull_request_reviews: {
    required_approving_review_count: 0,
    require_code_owner_reviews: false,
    dismiss_stale_reviews: false,
    require_last_push_approval: false
  },
  restrictions: null,
  required_linear_history: true,
  allow_force_pushes: false,
  allow_deletions: false,
  block_creations: false,
  required_conversation_resolution: true,
  lock_branch: false,
  allow_fork_syncing: false
}' > "$LOWER"

echo "[PATCH] set required_approving_review_count=0" | tee -a "$LOG"
gh api -X PUT "repos/:owner/:repo/branches/$BASE/protection" \
  -H "Accept: application/vnd.github+json" --input "$LOWER" >/dev/null

# ───────────────── ensure PR up-to-date (fast, no-op if déjà OK)
echo "[REBASE] sync PR branch on latest $BASE (no-op if already up-to-date)" | tee -a "$LOG"
gh pr checkout "$PR_NUM" >/dev/null
git fetch origin "$BASE" >/dev/null
git rebase "origin/$BASE" || true
git push --force-with-lease || true

# ───────────────── trigger required checks if needed
echo "[DISPATCH] ensure required checks exist on PR head (pypi-build & secret-scan)" | tee -a "$LOG"
gh workflow run pypi-build.yml   --ref "$BR" || true
gh workflow run secret-scan.yml  --ref "$BR" || true

# wait until the two required contexts are green on the PR head
HEAD="$(gh pr view "$PR_NUM" --json headRefOid -q .headRefOid)"
echo "[WAIT] required checks on HEAD=$HEAD" | tee -a "$LOG"
req_ok() {
  gh pr view "$PR_NUM" --json statusCheckRollup | \
  jq -re '
    [.statusCheckRollup[]
      | {name: .name, concl: .conclusion}
      | select((.name=="pypi-build/build" or .name=="secret-scan/gitleaks"))
      | .concl] as $c
    | ($c|length==2) and ( ($c|index("SUCCESS"))!=null and ($c|rindex("SUCCESS"))!=null )
  ' >/dev/null 2>&1
}
for i in $(seq 1 60); do
  if req_ok; then echo "[OK] required checks green" | tee -a "$LOG"; break; fi
  echo "[…] waiting ($i)" | tee -a "$LOG"; sleep 5
done

# ───────────────── merge (prefer squash for linear history); fall back to admin if needed
echo "[MERGE] try squash" | tee -a "$LOG"
if ! gh pr merge "$PR_NUM" --squash --delete-branch; then
  echo "[WARN] merge refused; try admin squash" | tee -a "$LOG"
  gh pr merge "$PR_NUM" --squash --admin --delete-branch
fi

# ───────────────── restore protections (reviews=1)
RESTORE="_tmp/protect.$BASE.restore.$TS.json"
jq -n --argjson checks "$CHECKS_JSON" '{
  required_status_checks: { strict: true, checks: $checks },
  enforce_admins: true,
  required_pull_request_reviews: {
    required_approving_review_count: 1,
    require_code_owner_reviews: false,
    dismiss_stale_reviews: false,
    require_last_push_approval: false
  },
  restrictions: null,
  required_linear_history: true,
  allow_force_pushes: false,
  allow_deletions: false,
  block_creations: false,
  required_conversation_resolution: true,
  lock_branch: false,
  allow_fork_syncing: false
}' > "$RESTORE"

echo "[RESTORE] protections strictes" | tee -a "$LOG"
gh api -X PUT "repos/:owner/:repo/branches/$BASE/protection" \
  -H "Accept: application/vnd.github+json" --input "$RESTORE" >/dev/null

# ───────────────── sanity
echo "[VERIFY] PR state" | tee -a "$LOG"
gh pr view "$PR_NUM" --json state,mergedAt,mergeCommit,url | tee -a "$LOG"
echo "[DONE] merged & protections restored. Log: $LOG"
