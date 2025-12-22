#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] CH09 pipeline interrompu (code $code)";
  echo "[ASTUCE] Vérifie le log ci-dessus pour identifier l étape qui a échoué.";
  exit "$code"' ERR

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "== CH09 – PIPELINE MINIMAL : phase-ondes-gravitationnelles =="

echo
echo "[1/2] Génération des données..."
python scripts/09_dark_energy_cpl/generate_data_chapter09.py

echo
echo "✅ Génération Chapter 9 OK"

echo
echo "[2/2] Génération des figures..."
python scripts/09_dark_energy_cpl/plot_fig01_phase_overlay.py
python scripts/09_dark_energy_cpl/plot_fig02_residual_phase.py

echo
echo "[OK] CH09 pipeline minimal terminé sans erreur."
