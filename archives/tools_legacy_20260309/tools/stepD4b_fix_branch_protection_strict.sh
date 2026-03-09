#!/usr/bin/env bash
# File: stepD4b_fix_branch_protection_strict.sh
# Restaure une protection stricte valide sur main (checks + 1 review).
set -Euo pipefail

OWNER_REPO="${OWNER_REPO:-JeanPhilipLalumiere/MCGT}"
BASE_BRANCH="${BASE_BRANCH:-main}"

need(){ command -v "$1" >/dev/null 2>&1 || { echo "[ERR] manquant: $1"; exit 2; }; }
need gh
mkdir -p _logs
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"

# IMPORTANT : n'utiliser QUE "checks" OU "contexts", pas les deux.
cat > _tmp_protect_strict_fix.json <<'JSON'
{
  "required_status_checks": {
    "strict": true,
    "checks": [
      { "context": "pypi-build/build" },
      { "context": "secret-scan/gitleaks" }
    ]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": false,
    "require_code_owner_reviews": false,
    "require_last_push_approval": false,
    "required_approving_review_count": 1
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

echo "[INFO] Applique protection stricte (checks + 1 review)…"
gh api -X PUT "repos/${OWNER_REPO}/branches/${BASE_BRANCH}/protection" \
  -H "Accept: application/vnd.github+json" \
  --input _tmp_protect_strict_fix.json \
  | tee "_logs/stepD4b_set_${STAMP}.json" >/dev/null

echo "[OK] Protection stricte appliquée."
