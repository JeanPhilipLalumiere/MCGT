#!/usr/bin/env bash
set -euo pipefail
need() { command -v "$1" >/dev/null 2>&1 || {
  echo "ERR: '$1' introuvable"
  exit 1
}; }
need gh

# Déduire owner/repo
slug="$(git config --get remote.origin.url | sed -E 's#.*github\.com[:/ ]([^/]+/[^/.]+)(\.git)?$#\1#')"
: "${slug:?Slug repo introuvable}"

echo "[protect] Applying minimal branch protection on ${slug}@main"
gh api -X PUT "repos/${slug}/branches/main/protection" \
  -H "Accept: application/vnd.github+json" \
  -F required_status_checks.strict=true \
  -F required_status_checks.contexts[]="sanity-main" \
  -F enforce_admins=true \
  -F required_pull_request_reviews.required_approving_review_count=1 \
  -F restrictions= ||
  echo "WARN: protection call failed (insufficient rights?)"

echo "[protect] Done"
