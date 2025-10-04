#!/usr/bin/env bash
# shellcheck source=/dev/null
. .ci-helpers/guard.sh
set -Eeuo pipefail

ROOT=".ci-out"
BUNDLE="$ROOT/_bundle_all_ciout.txt"

if [ ! -d "$ROOT" ]; then
  echo "❌ Dossier $ROOT introuvable. Lance d'abord tes scans."
  exit 1
fi

# vide/remplace le bundle
: >"$BUNDLE"

# tri stable, parcours récursif
mapfile -t FILES < <(find "$ROOT" -type f -not -name "$(basename "$BUNDLE")" | sort)

if [ "${#FILES[@]}" -eq 0 ]; then
  echo "ℹ️ Aucun fichier dans $ROOT."
  exit 0
fi

for f in "${FILES[@]}"; do
  echo
  echo "========================================================================"
  echo ">>> FILE: $f"
  echo "========================================================================"
  # impression dans le terminal
  # - on assume texte ; si jamais binaire, on affiche quand même (les tiens sont textuels)
  cat -- "$f" || true

  # ajoute aussi au bundle
  {
    echo
    echo "========================================================================"
    echo ">>> FILE: $f"
    echo "========================================================================"
    cat -- "$f" || true
  } >>"$BUNDLE"
done

echo
echo "✅ Affichage terminé."
echo "🧾 Bundle prêt pour copy/paste: $BUNDLE"
