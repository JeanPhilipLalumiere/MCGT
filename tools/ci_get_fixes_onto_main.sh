#!/usr/bin/env bash
set -euo pipefail

TARGET_BRANCH="${1:-main}"
CUR="$(git rev-parse --abbrev-ref HEAD)"

echo "[INFO] Branche courante: $CUR"
git status --porcelain
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "[ERREUR] L’arbre de travail n’est pas propre. Committez ou stash avant de continuer." >&2
  exit 1
fi

git fetch --all --prune
git switch "$TARGET_BRANCH"
git pull --ff-only

# Si on vient d’une autre branche que TARGET_BRANCH, essayer un fast-forward merge
if [[ "$CUR" != "$TARGET_BRANCH" ]]; then
  set +e
  git merge --ff-only "$CUR"
  rc=$?
  set -e
  if [[ $rc -ne 0 ]]; then
    echo "[WARN] Merge fast-forward impossible. Tentative de cherry-pick du dernier commit de $CUR…"
    LAST="$(git rev-parse "$CUR")"
    git cherry-pick "$LAST" || {
      echo "[ERREUR] cherry-pick impossible. Créez une PR manuelle:" >&2
      echo "  gh pr create -B $TARGET_BRANCH -H $CUR -t 'ci: actionlint fixes' -b 'Fix SC2015 et SC2129'" >&2
      exit 1
    }
  fi
fi

git push -u origin "$TARGET_BRANCH"

if command -v gh >/dev/null 2>&1; then
  echo "[INFO] Déclenchement du workflow ci-pre-commit.yml sur ${TARGET_BRANCH}…"
  gh workflow run ci-pre-commit.yml -r "$TARGET_BRANCH" >/dev/null

  RID="$(gh run list --workflow ci-pre-commit.yml --branch "$TARGET_BRANCH" --limit 1 \
        --json databaseId -q '.[0].databaseId')"
  echo "[INFO] RID=$RID"

  # Attente (ne bloque pas la CI si échec) puis affichage du tronçon intéressant des logs
  gh run watch --exit-status "$RID" || true
  echo
  echo "=== LOG (depuis 'Run pre-commit (all files)') ==="
  gh run view "$RID" --log | sed -n '/Run pre-commit (all files)/,$p' || true
else
  echo "[INFO] GitHub CLI (gh) non détecté. Push effectué. Lancez la CI depuis l’UI GitHub."
fi

echo "[OK] Correctifs présents sur ${TARGET_BRANCH}."
