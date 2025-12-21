#!/usr/bin/env bash
set -Eeuo pipefail

echo "== CH03 – PIPELINE MINIMAL : stabilite-fR =="
echo

echo "[1/2] Génération des données..."
python scripts/chapter03/generate_data_chapter03.py
echo "✅ Génération Chapitre 3 OK"
echo

echo "[2/2] Génération des figures..."
python scripts/chapter03/plot_fig01_fR_stability_domain.py
python scripts/chapter03/plot_fig02_fR_fRR_vs_f.py
python scripts/chapter03/plot_fig03_ms2_R0_vs_f.py
python scripts/chapter03/plot_fig04_fR_fRR_vs_f.py
python scripts/chapter03/plot_fig05_interpolated_milestones.py
python scripts/chapter03/plot_fig06_grid_quality.py
python scripts/chapter03/plot_fig07_ricci_fR_vs_z.py
python scripts/chapter03/plot_fig08_ricci_fR_vs_T.py

echo
echo "[OK] CH03 pipeline minimal terminé sans erreur."
