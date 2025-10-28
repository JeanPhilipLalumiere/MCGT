#!/usr/bin/env bash
# File: stepB_open_ff_pr_main_from_tag.sh
# Objet: créer une PR "fast-forward main -> v0.3.x" de manière sûre, sans force-push
set -euo pipefail

VERSION="${VERSION:-v0.3.x}"
BASE_BRANCH="${BASE_BRANCH:-main}"
FF_BRANCH="ff/${BASE_BRANCH}-to-${VERSION}-$(date -u +%Y%m%dT%H%M%SZ)"

need(){ command -v "$1" >/dev/null 2>&1 || { echo "[ERR] manquant: $1"; exit 2; }; }
for b in git gh; do need "$b"; done

echo "[INFO] Fetch…"
git fetch --all --tags --prune

echo "[INFO] Résous commits…"
TAG_SHA="$(git rev-list -n1 "${VERSION}")"
MAIN_SHA="$(git rev-parse origin/${BASE_BRANCH})"
echo "[INFO] ${VERSION}=${TAG_SHA}"
echo "[INFO] origin/${BASE_BRANCH}=${MAIN_SHA}"

# Vérifie si main est ancêtre du tag (fast-forward possible)
if git merge-base --is-ancestor "${MAIN_SHA}" "${TAG_SHA}"; then
  echo "[OK] Fast-forward possible: ${BASE_BRANCH} -> ${VERSION}"
else
  echo "[ERR] Fast-forward NON possible (divergence). Ouvrir PR de merge classique."
  exit 1
fi

# Crée branche de source au tag
git switch -c "${FF_BRANCH}" "${TAG_SHA}"

# Pousse et ouvre PR
git push -u origin "${FF_BRANCH}"

TITLE="FF ${BASE_BRANCH} → ${VERSION} (align release state, no code changes)"
BODY=$(
cat <<EOF
This PR fast-forwards **${BASE_BRANCH}** to tag **${VERSION}**.

- No code changes vs tag.
- Aligns default branch with the released snapshot.
- Keeps history linear; no force-push.

After merge:
- Enable/confirm branch protection (no force-push).
- Keep tag protection for v* patterns.
EOF
)

echo "[INFO] Ouverture PR…"
gh pr create \
  --base "${BASE_BRANCH}" \
  --head "${FF_BRANCH}" \
  --title "${TITLE}" \
  --body "${BODY}"

echo "[DONE] PR ouverte. Merge FF dès que les checks passent."
