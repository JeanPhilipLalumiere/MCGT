#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: scripts/verify_tag.sh <tag ex: v0.2.28>"
  exit 2
fi

TAG="$1"
echo "==> Vérification du contenu du tag ${TAG}"
SHA="$(git rev-parse "${TAG}")" || { echo "❌ Tag introuvable"; exit 1; }
echo "    ${TAG} -> ${SHA}"

WF_PATH=".github/workflows/publish.yml"
if git ls-tree -r "$SHA" --name-only | grep -q "^${WF_PATH}$"; then
  echo "✅ ${WF_PATH} présent dans l'arbre du tag."
else
  echo "❌ ${WF_PATH} MANQUANT dans le tag. Retag sur HEAD..."
  test -f "${WF_PATH}" || { echo "❌ ${WF_PATH} absent sur HEAD aussi. Abandon."; exit 1; }
  git tag -f "${TAG}"
  git push -f origin "${TAG}"
  echo "🔁 Tag ${TAG} replacé sur HEAD et poussé."
fi
