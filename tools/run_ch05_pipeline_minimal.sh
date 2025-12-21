#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  if [ "$code" -ne 0 ]; then
    echo
    echo "[ERREUR] CH05 pipeline interrompu (code $code)"
    echo "[ASTUCE] Vérifie le log ci-dessus pour identifier l étape qui a échoué."
  fi
  exit $code
' ERR

echo "== CH05 – PIPELINE MINIMAL : nucleosynthese-primordiale =="
echo

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

echo "[1/2] Génération des données..."
python scripts/chapter05/generate_data_chapter05.py

echo
echo "[2/2] Génération des figures..."
python scripts/chapter05/plot_fig01_bbn_reaction_network.py
python scripts/chapter05/plot_fig02_dh_model_vs_obs.py
python scripts/chapter05/plot_fig03_yp_model_vs_obs.py
python scripts/chapter05/plot_fig04_chi2_vs_T.py

echo
echo "[OK] CH05 pipeline minimal terminé sans erreur."
