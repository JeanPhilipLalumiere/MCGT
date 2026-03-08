#!/usr/bin/env bash
set -euo pipefail

COMMIT_MSG="Release Gold 4.0: Refonte POO complète, intégration BBN/ISW, tests unitaires et résolution simultanée H0/S8"
TAG_NAME="v4.0.0"
TAG_MSG="Version utilisée pour la soumission de l'article fondateur PsiTMG"

BRANCH="$(git rev-parse --abbrev-ref HEAD)"

git add .
git commit -m "$COMMIT_MSG"
git tag -a "$TAG_NAME" -m "$TAG_MSG"
git push origin "$BRANCH"
git push origin "$TAG_NAME"

echo "Release pushed on origin/$BRANCH with tag $TAG_NAME"
