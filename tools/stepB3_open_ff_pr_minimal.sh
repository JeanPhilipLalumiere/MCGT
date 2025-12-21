#!/usr/bin/env bash
# File: stepB3_open_ff_pr_minimal.sh
set -euo pipefail
VERSION="${VERSION:-v0.3.x}"
BASE_BRANCH="${BASE_BRANCH:-main}"
FF_BRANCH="ff/${BASE_BRANCH}-to-${VERSION}-$(date -u +%Y%m%dT%H%M%SZ)"

need(){ command -v "$1" >/dev/null || { echo "[ERR] $1 manquant"; exit 2; }; }
for b in git gh; do need "$b"; done

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
  echo "[ERR] Fast-forward NON possible (divergence). Ouvre une PR de merge classique."
  exit 1
fi

git switch -c "${FF_BRANCH}" "${TAG_SHA}"
git push -u origin "${FF_BRANCH}"

TITLE="FF ${BASE_BRANCH} → ${VERSION} (align with released snapshot)"
BODY=$(
cat <<'EOF'
Fast-forward main to the released tag.

- No code changes vs tag
- Aligns default branch with the published state
- Keeps history linear (no force-push)
EOF
)
gh pr create --base "${BASE_BRANCH}" --head "${FF_BRANCH}" --title "${TITLE}" --body "${BODY}"
echo "[DONE] PR ouverte."
