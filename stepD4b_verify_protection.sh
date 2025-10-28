#!/usr/bin/env bash
# File: stepD4b_verify_protection.sh
set -euo pipefail
OWNER_REPO="${OWNER_REPO:-JeanPhilipLalumiere/MCGT}"
BASE_BRANCH="${BASE_BRANCH:-main}"
for b in gh jq; do command -v "$b" >/dev/null || { echo "[ERR] $b manquant"; exit 2; }; done

JSON="$(gh api -H 'Accept: application/vnd.github+json' \
  "repos/${OWNER_REPO}/branches/${BASE_BRANCH}/protection")"

echo "$JSON" | jq '{
  enforce_admins: .enforce_admins.enabled,
  required_linear_history: .required_linear_history.enabled,
  required_conversation_resolution: .required_conversation_resolution.enabled,
  allow_force_pushes: .allow_force_pushes.enabled,
  allow_deletions: .allow_deletions.enabled,
  required_approving_review_count: .required_pull_request_reviews.required_approving_review_count,
  checks: (.required_status_checks.checks // []) | map(.context)
}'
