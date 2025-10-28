#!/usr/bin/env bash
# File: stepD4_verify_branch_protection.sh
set -euo pipefail
OWNER_REPO="${OWNER_REPO:-JeanPhilipLalumiere/MCGT}"
BASE_BRANCH="${BASE_BRANCH:-main}"
need(){ command -v "$1" >/dev/null 2>&1 || { echo "[ERR] manquant: $1"; exit 2; }; }
for b in gh jq; do need "$b"; done

JSON="$(gh api -H 'Accept: application/vnd.github+json' \
  "repos/${OWNER_REPO}/branches/${BASE_BRANCH}/protection")"

echo "$JSON" | jq '{
  enforce_admins, 
  required_linear_history, 
  required_conversation_resolution, 
  allow_force_pushes, 
  allow_deletions,
  required_pull_request_reviews: {
    required_approving_review_count: .required_pull_request_reviews.required_approving_review_count,
    require_code_owner_reviews: .required_pull_request_reviews.require_code_owner_reviews
  },
  checks: (.required_status_checks.checks // [] ) | map(.context)
}'
