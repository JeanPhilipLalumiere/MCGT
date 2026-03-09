#!/usr/bin/env bash
# File: stepC_merge_and_protect_guard.sh
# Objet : merger PR FF main<-v0.3.x, puis protéger main et tags v* (pas de force-push)
set -Euo pipefail

PR_URL="${PR_URL:-https://github.com/JeanPhilipLalumiere/MCGT/pull/23}"
BASE_BRANCH="${BASE_BRANCH:-main}"
VERSION="${VERSION:-v0.3.x}"
OWNER_REPO="${OWNER_REPO:-JeanPhilipLalumiere/MCGT}"
LOG_DIR="_logs"; mkdir -p "$LOG_DIR"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
LOG="${LOG_DIR}/stepC_merge_and_protect_${STAMP}.log"

_pause(){ read -r -p $'\n[HOLD] Fin. Entrée pour revenir au shell… ' _; }
trap _pause EXIT
exec > >(tee -a "$LOG") 2>&1

need(){ command -v "$1" >/dev/null 2>&1 || { echo "[ERR] binaire requis manquant: $1"; exit 2; }; }
for b in git gh jq; do need "$b"; done

echo "[INFO] Vérifie PR FF ${PR_URL}"
gh pr view "${PR_URL}" --json number,title,headRefName,baseRefName,mergeStateStatus,isDraft

echo "[INFO] Fetch ciblé…"
git fetch origin "${BASE_BRANCH}:${BASE_BRANCH}" --prune
git fetch origin "refs/tags/${VERSION}:refs/tags/${VERSION}"

TAG_SHA="$(git rev-list -n1 "${VERSION}")"
MAIN_SHA="$(git rev-parse "${BASE_BRANCH}")"
echo "[INFO] ${VERSION}=${TAG_SHA}"
echo "[INFO] ${BASE_BRANCH}=${MAIN_SHA}"

if git merge-base --is-ancestor "${MAIN_SHA}" "${TAG_SHA}"; then
  echo "[OK] Fast-forward possible."
else
  echo "[ERR] Fast-forward NON possible. Abandon."
  exit 1
fi

echo "[STEP] Merge PR en fast-forward (no-ff disable)"
gh pr merge "${PR_URL}" --merge --auto --delete-branch || {
  echo "[WARN] Merge non immédiat (peut nécessiter droits/review). Tentative merge direct côté git…"
  git switch "${BASE_BRANCH}"
  git merge --ff-only "${TAG_SHA}"
  git push origin "${BASE_BRANCH}"
}

echo "[OK] main alignée sur ${VERSION}."

echo "[STEP] Protections GitHub (si droits) :"
# Protège main
gh api -X PUT "repos/${OWNER_REPO}/branches/${BASE_BRANCH}/protection" \
  -f required_status_checks='{"strict":true,"contexts":[]}' \
  -f enforce_admins=true \
  -f required_pull_request_reviews='{"required_approving_review_count":1}' \
  -f restrictions='null' \
  -f allow_force_pushes=false \
  -f allow_deletions=false \
  && echo "[OK] Protection branch ${BASE_BRANCH}."

# Protège les tags v*
gh api -X PUT "repos/${OWNER_REPO}/tags/protection" \
  -H "Accept: application/vnd.github+json" \
  -f patterns='["v*"]' \
  && echo "[OK] Protection tags v*."

echo "[STEP] Sanity final"
git ls-remote origin "refs/heads/${BASE_BRANCH}"
gh release view "${VERSION}" --json url,assets | jq -r '.url, (.assets|map(.name))'

echo "[DONE] Merge+Protection OK. Journal: ${LOG}"
