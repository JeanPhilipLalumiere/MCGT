#!/usr/bin/env bash
set -euo pipefail

PR_NUM="${PR_NUM:-26}"
REPO_ROOT="$(git rev-parse --show-toplevel)"; cd "$REPO_ROOT"
mkdir -p _logs _tmp
TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG="_logs/merge_conv_guard_${PR_NUM}_${TS}.log"

NWO="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
OWNER="${NWO%%/*}"; REPO="${NWO##*/}"
BR="$(gh pr view "$PR_NUM" --json headRefName -q .headRefName)"
[[ "$BR" == "main" ]] && { echo "[ABORT] Refus d'opérer sur main" | tee -a "$LOG"; read -r -p $'ENTER…\n' _ </dev/tty || true; exit 2; }

echo "[INFO] Repo=$OWNER/$REPO | PR #$PR_NUM | branch=$BR" | tee -a "$LOG"

# ── Protections actuelles
gh api repos/:owner/:repo/branches/main/protection \
| jq '{strict: .required_status_checks.strict,
      checks: (.required_status_checks.checks|map(.context)),
      reviews: .required_pull_request_reviews.required_approving_review_count,
      conv_resolve: .required_conversation_resolution.enabled}' | tee -a "$LOG"

# ── État PR (mergeable, review, checks)
echo "[INFO] Inspect PR status…" | tee -a "$LOG"
PR_JSON="$(gh pr view "$PR_NUM" --json mergeable,mergeStateStatus,reviewDecision,isDraft,statusCheckRollup,headRefOid,baseRefName,headRefName,url)"
echo "$PR_JSON" | jq '{
  url, headRefName, baseRefName, headRefOid,
  mergeable, mergeStateStatus, reviewDecision, isDraft,
  checks: ( .statusCheckRollup[]? | {name:.name, app:(.app.name), status, conclusion} )
}' | tee -a "$LOG"

# ── Threads NON résolus (GraphQL sans "states:")
echo "[INFO] Query reviewThreads (all) then filter unresolved… " | tee -a "$LOG"
GQL='
query($owner:String!, $name:String!, $num:Int!){
  repository(owner:$owner, name:$name){
    pullRequest(number:$num){
      url
      reviewThreads(first:100){
        totalCount
        nodes{
          isResolved
          comments(first:1){
            nodes{ url author{login} bodyText }
          }
        }
      }
    }
  }
}'
set +e
RAW="$(gh api graphql -f query="$GQL" -F owner="$OWNER" -F name="$REPO" -F num="$PR_NUM" 2>>"$LOG")"
RC=$?
set -e
if [[ $RC -ne 0 || -z "$RAW" ]]; then
  echo "[WARN] GraphQL a échoué; on continue sans listing détaillé." | tee -a "$LOG"
  UNRESOLVED=0
else
  UNRESOLVED="$(echo "$RAW" | jq '[.data.repository.pullRequest.reviewThreads.nodes[]? | select(.isResolved==false)] | length')"
  echo "[INFO] Unresolved threads: $UNRESOLVED" | tee -a "$LOG"
  if [[ "${UNRESOLVED:-0}" -gt 0 ]]; then
    echo "[LIST] First comments of unresolved:" | tee -a "$LOG"
    echo "$RAW" | jq -r '
      .data.repository.pullRequest.reviewThreads.nodes[]
      | select(.isResolved==false)
      | "- \(.comments.nodes[0].url // "no-url") (\(.comments.nodes[0].author.login // "unknown"))"
    ' | tee -a "$LOG"
  fi
fi

# ── Décision
MERGEABLE="$(echo "$PR_JSON" | jq -r '.mergeable')"
MSTATE="$(echo "$PR_JSON" | jq -r '.mergeStateStatus')"
RDEC="$(echo "$PR_JSON" | jq -r '.reviewDecision')"

echo
echo "[DECISION] mergeable=$MERGEABLE | mergeStateStatus=$MSTATE | reviewDecision=$RDEC | unresolved=$UNRESOLVED" | tee -a "$LOG"

# Helper: PUT protection
put_protection() {
  local json="$1"
  gh api -X PUT repos/:owner/:repo/branches/main/protection \
    -H "Accept: application/vnd.github+json" --input "$json" | tee -a "$LOG" >/dev/null
}

# Plans:
# P0: tout est OK → merge
# P1: review manquante (reviewDecision != APPROVED) → baisser review=0 temporairement
# P2: conversations non résolues (UNRESOLVED>0 & conv_resolve=true) → désactiver temporairement conv_resolve
# Les deux peuvent être combinés si nécessaire.

# Récupère profil actuel pour checks existants
CUR_PROT="$(gh api repos/:owner/:repo/branches/main/protection)"
CHECKS_JSON="$(echo "$CUR_PROT" | jq '.required_status_checks.checks')"
REV_REQ="$(echo "$CUR_PROT" | jq '.required_pull_request_reviews.required_approving_review_count')"
CONV_REQ="$(echo "$CUR_PROT" | jq '.required_conversation_resolution.enabled')"

need_lower_review=false
need_disable_conv=false

if [[ "$RDEC" != "APPROVED" && "${REV_REQ}" != "0" ]]; then
  need_lower_review=true
fi
if [[ "${UNRESOLVED:-0}" -gt 0 && "$CONV_REQ" == "true" ]]; then
  need_disable_conv=true
fi

# ── Appliquer bascules temporaires si requis
if $need_lower_review || $need_disable_conv; then
  echo "[PLAN] Bascules temporaires: lower_review=$need_lower_review ; disable_conv=$need_disable_conv" | tee -a "$LOG"
  TMP_JSON="_tmp/protect_tmp_${TS}.json"
  jq -n --argjson checks "$CHECKS_JSON" \
        --argjson reviews "$( $need_lower_review && echo 0 || echo "$REV_REQ" )" \
        --argjson conv    "$( $need_disable_conv && echo false || echo "$CONV_REQ" )" '
  {
    enforce_admins: true,
    required_linear_history: true,
    required_conversation_resolution: $conv,
    allow_force_pushes: false,
    allow_deletions: false,
    restrictions: null,
    required_pull_request_reviews: {
      required_approving_review_count: $reviews,
      require_code_owner_reviews: false,
      dismiss_stale_reviews: false,
      require_last_push_approval: false
    },
    required_status_checks: {
      strict: true,
      checks: $checks
    }
  }' > "$TMP_JSON"
  put_protection "$TMP_JSON"
fi

# ── Merge (rebase) — laissez GitHub vérifier les règles mises à jour
set +e
gh pr merge "$PR_NUM" --rebase | tee -a "$LOG"
RC_M=$?
set -e

# ── Restauration stricte si on a modifié quelque chose
if $need_lower_review || $need_disable_conv; then
  echo "[RESTORE] Restauration profil strict (review=1, conv_resolve=true)" | tee -a "$LOG"
  REST_JSON="_tmp/protect_restore_${TS}.json"
  jq -n --argjson checks "$CHECKS_JSON" '
  {
    enforce_admins: true,
    required_linear_history: true,
    required_conversation_resolution: true,
    allow_force_pushes: false,
    allow_deletions: false,
    restrictions: null,
    required_pull_request_reviews: {
      required_approving_review_count: 1,
      require_code_owner_reviews: false,
      dismiss_stale_reviews: false,
      require_last_push_approval: false
    },
    required_status_checks: {
      strict: true,
      checks: $checks
    }
  }' > "$REST_JSON"
  put_protection "$REST_JSON"
fi

if [[ $RC_M -ne 0 ]]; then
  echo "[WARN] Merge refusé. Causes possibles: conflits, méthode interdite, ou état transitoire mergeable=UNKNOWN/CONFLICTING." | tee -a "$LOG"
  echo "[HINT] Si nécessaire, rebase local: gh pr checkout $PR_NUM && git fetch origin main && git rebase origin/main && git push --force-with-lease" | tee -a "$LOG"
else
  echo "[DONE] Merge réussi." | tee -a "$LOG"
fi

read -r -p $'Fin. ENTER pour fermer…\n' _ </dev/tty || true
