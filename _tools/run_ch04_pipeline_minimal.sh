#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] CH04 pipeline interrompu (code $code)";
  echo "[ASTUCE] Vérifie le log ci-dessus pour identifier l étape qui a échoué.";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

echo "== CH04 – PIPELINE MINIMAL : invariants-adimensionnels =="
echo

echo "[1/2] Génération des données..."
python zz-scripts/chapter04/generate_data_chapter04.py

echo
echo "[2/2] Génération des figures..."
python zz-scripts/chapter04/plot_fig01_invariants_schematic.py
python zz-scripts/chapter04/plot_fig02_invariants_histogram.py
python zz-scripts/chapter04/plot_fig03_invariants_vs_T.py
python zz-scripts/chapter04/plot_fig04_relative_deviations.py

echo
echo "[OK] CH04 pipeline minimal terminé sans erreur."
read -rp "Appuie sur Entrée pour revenir au shell..." _
