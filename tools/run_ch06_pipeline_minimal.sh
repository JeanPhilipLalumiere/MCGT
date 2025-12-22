#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] CH06 pipeline interrompu (code $code)";
  echo "[ASTUCE] Vérifie le log ci-dessus pour identifier l étape qui a échoué.";
  exit $code
' ERR

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "== CH06 – PIPELINE MINIMAL : rayonnement-cmb =="
echo

# ----------------------------------------------------------------------
# [1/2] Génération des données
# ----------------------------------------------------------------------
echo "[1/2] Génération des données..."
python scripts/06_early_growth_jwst/generate_data_chapter06.py

# Bridge CH06 2D files si nécessaire (*_2d.csv -> *2D.csv)
if [ -x "tools/ch06_bridge_2d_files.sh" ]; then
  echo "[INFO] Bridge CH06 2D files (*_2d -> *2D) si nécessaire..."
  tools/ch06_bridge_2d_files.sh || echo "[WARN] ch06_bridge_2d_files.sh a retourné un code non nul"
fi

echo "✅ Génération Chapter 6 OK"
echo

# ----------------------------------------------------------------------
# [2/2] Génération des figures
# ----------------------------------------------------------------------
echo "[2/2] Génération des figures..."
python scripts/06_early_growth_jwst/plot_fig01_cmb_dataflow_diagram.py
python scripts/06_early_growth_jwst/plot_fig02_cls_lcdm_vs_mcgt.py
python scripts/06_early_growth_jwst/plot_fig03_delta_cls_relative.py
python scripts/06_early_growth_jwst/plot_fig04_delta_rs_vs_params.py
python scripts/06_early_growth_jwst/plot_fig05_delta_chi2_heatmap.py

echo
echo "[OK] CH06 pipeline minimal terminé sans erreur."
