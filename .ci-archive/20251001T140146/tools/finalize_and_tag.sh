#!/usr/bin/env bash
set -euo pipefail

PAUSE="${PAUSE:-1}"
_pause(){ if [[ "${PAUSE}" != "0" && -t 0 ]]; then echo; read -r -p "✓ Terminé. Appuie sur Entrée pour fermer..." _; fi; }
trap _pause EXIT

echo "== Finalize & (optional) tag =="
[ -d .git ] || { echo "❌ Lance à la racine du dépôt (.git/)."; exit 2; }
branch="$(git rev-parse --abbrev-ref HEAD)"
echo "• Branche: ${branch}"

# Garde-fou contre .RECIPEPREFIX
tools/guard_no_recipeprefix.sh

# Dry-run Make côté manifest (assure la santé du Makefile)
make -n fix-manifest >/dev/null

# Pousse + tests (re-emploie ton script existant)
tools/push_all.sh

# Tag optionnel
if [[ "${TAG:-}" != "" ]]; then
  echo "🔖 Création du tag ${TAG}"
  git tag -a "${TAG}" -m "release ${TAG}"
  git push origin "${TAG}"
fi

echo "✅ Finalisation OK."
