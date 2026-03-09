#!/usr/bin/env bash
set -Eeuo pipefail

echo "== CH06 – PIPELINE FIGURES ONLY : rayonnement-cmb =="

# Se placer à la racine du dépôt
cd "$(dirname "${BASH_SOURCE[0]}")/.."

echo
echo "[*] Génération des figures uniquement (les données doivent déjà exister)."
echo

# Fichiers de base attendus pour les figures
required=(
  "assets/zz-data/06_early_growth_jwst/06_cls_spectrum.dat"
  "assets/zz-data/06_early_growth_jwst/06_cls_lcdm_spectrum.dat"
  "assets/zz-data/06_early_growth_jwst/06_delta_rs_scan.csv"
  "assets/zz-data/06_early_growth_jwst/06_delta_rs_scan_2d.csv"
  "assets/zz-data/06_early_growth_jwst/06_cmb_chi2_scan_2d.csv"
)
missing=0
for f in "${required[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "[WARN] Fichier manquant pour les figures: $f"
    missing=1
  fi
done

if [[ "$missing" -ne 0 ]]; then
  echo
  echo "[WARN] Certains fichiers nécessaires aux figures sont absents."
  echo "       Si besoin, relance d'abord la génération complète des données pour CH06."
  echo
fi

echo "[1/1] Génération des figures CH06..."

python scripts/06_early_growth_jwst/plot_fig01_cmb_dataflow_diagram.py
python scripts/06_early_growth_jwst/plot_fig02_cls_lcdm_vs_mcgt.py
python scripts/06_early_growth_jwst/plot_fig03_delta_cls_relative.py
python scripts/06_early_growth_jwst/plot_fig04_delta_rs_vs_params.py
python scripts/06_early_growth_jwst/plot_fig05_delta_chi2_heatmap.py

echo
echo "[OK] CH06 figures-only terminé sans erreur."
