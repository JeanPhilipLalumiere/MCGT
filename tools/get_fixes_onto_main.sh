#!/usr/bin/env bash
set -Eeuo pipefail

cleanup() {
  local rc="$1"
  echo
  echo "=== FIN DU SCRIPT (code=$rc) ==="
  if [[ "${PAUSE_ON_EXIT:-1}" != "0" && -t 1 && -t 0 ]]; then
    read -rp "Appuyez sur Entrée pour fermer cette fenêtre..." _ || true
  fi
}
trap 'cleanup $?' EXIT

TARGET_BRANCH="${1:-main}"
command -v gh >/dev/null 2>&1 || {
  echo "[ERREUR] GitHub CLI 'gh' requis." >&2
  exit 1
}

# 1) Arbre propre
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "[ERREUR] L’arbre de travail n’est pas propre. Committez/stashez avant." >&2
  exit 1
fi

# 2) FF propre si on n'est pas déjà sur la branche cible
CUR_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$CUR_BRANCH" != "$TARGET_BRANCH" ]]; then
  git fetch origin "$TARGET_BRANCH"
  git checkout "$TARGET_BRANCH"
  git merge --ff-only "$CUR_BRANCH"
fi

# 3) Push
echo "=== PUSH sur $TARGET_BRANCH ==="
git push -u origin "$TARGET_BRANCH"

# 4) Déclenchement du workflow
echo "[INFO] Déclenchement ci-pre-commit.yml…"
gh workflow run ci-pre-commit.yml -r "$TARGET_BRANCH" >/dev/null

# 5) Suivi du run correspondant au HEAD courant
"$(dirname "$0")/watch_head_ci.sh"
