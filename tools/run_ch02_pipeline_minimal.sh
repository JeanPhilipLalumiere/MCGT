#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] CH02 pipeline interrompu (code $code)";
  echo "[ASTUCE] Vérifie le log ci-dessus pour identifier l étape qui a échoué.";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

echo "== CH02 – PIPELINE MINIMAL : validation-chronologique =="
echo

echo "[1/2] Génération des données..."
python scripts/02_primordial_spectrum/generate_data_chapter02.py

echo
echo "[2/2] Génération des figures..."
python scripts/02_primordial_spectrum/plot_fig00_spectrum.py
python scripts/02_primordial_spectrum/plot_fig01_P_vs_T_evolution.py
python scripts/02_primordial_spectrum/plot_fig02_calibration.py
python scripts/02_primordial_spectrum/plot_fig03_relative_errors.py
python scripts/02_primordial_spectrum/plot_fig04_pipeline_diagram.py
python scripts/02_primordial_spectrum/plot_fig05_FG_series.py
python scripts/02_primordial_spectrum/plot_fig06_alpha_fit.py

echo
echo "[OK] CH02 pipeline minimal terminé sans erreur."
read -rp "Appuie sur Entrée pour revenir au shell..." _
