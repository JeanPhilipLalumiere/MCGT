#!/usr/bin/env bash
set -Eeuo pipefail

INI="zz-configuration/scalar_perturbations.ini"
LOGDIR="zz-logs"
OUTDIR_DATA="zz-data/chapter07"
OUTDIR_CH07="zz-out/chapter07"
OUTDIR_SMOKE_UTILS="zz-out/smoke/chapter07/utils"

mkdir -p "$LOGDIR" "$OUTDIR_DATA" "$OUTDIR_CH07" "$OUTDIR_SMOKE_UTILS"

echo "# Smoke minimal Chapitre 07 (profil canonique scalar_perturbations.ini)"
echo

# 1) Dry-run generate_data + solver
python zz-scripts/chapter07/generate_data_chapter07.py \
  -i "$INI" \
  --export-raw zz-out/smoke/chapter07/generate_data_chapter07_manual.csv \
  --dry-run \
  || echo "[WARN] generate_data_chapter07.py --dry-run a échoué (ce serait anormal, à inspecter)."

python zz-scripts/chapter07/launch_scalar_perturbations_solver.py \
  -i "$INI" \
  --export-raw zz-out/smoke/chapter07/launch_scalar_perturbations_solver_manual.csv \
  --dry-run \
  || echo "[WARN] launch_scalar_perturbations_solver.py --dry-run a échoué (ce serait anormal, à inspecter)."

echo
echo "# Pipeline minimal Chapitre 07 (profil canonique scalar_perturbations.ini)"
echo

echo "## 1) generate_data_chapter07.py -- run complet minimal"
echo "# NOTE : avec l'INI canonique actuelle, cette étape peut lever :"
echo "#   ValueError: c_s² hors-borne ou non-fini (attendu dans [0,1])."
echo "# Ce garde-fou est volontairement conservé."

python zz-scripts/chapter07/generate_data_chapter07.py \
  -i "$INI" \
  --export-raw "${OUTDIR_DATA}/07_scan_raw_minimal.csv" \
  --export-2d \
  --n-k 32 \
  --n-a 20 \
  --log-level INFO \
  --log-file "${OUTDIR_CH07}/generate_data_chapter07_minimal.log" \
  || echo "[ERREUR] generate_data_chapter07.py (run complet) a échoué (probablement c_s² hors-borne)."

echo
echo "## 2) launch_scalar_perturbations_solver.py -- run complet minimal"

python zz-scripts/chapter07/launch_scalar_perturbations_solver.py \
  -i "$INI" \
  --export-raw "${OUTDIR_DATA}/07_phase_run.csv" \
  --log-level INFO \
  --log-file "${OUTDIR_CH07}/launch_scalar_perturbations_solver_minimal.log" \
  || echo "[ERREUR] launch_scalar_perturbations_solver.py (run complet) a échoué (ce serait à investiguer)."

echo
echo "# Figures principales et utilitaires Chapitre 07"
echo

echo "## Figures 01 & 02 (heatmaps c_s² et delta_phi) -- devraient être OK"
python zz-scripts/chapter07/plot_fig01_cs2_heatmap.py \
  || echo "[ERREUR] plot_fig01_cs2_heatmap.py a échoué"

python zz-scripts/chapter07/plot_fig02_delta_phi_heatmap.py \
  || echo "[ERREUR] plot_fig02_delta_phi_heatmap.py a échoué"

echo
echo "## Figures 03 & 04 (invariants / dcs2_vs_k) -- dépendent de CSV dérivés"
python zz-scripts/chapter07/plot_fig03_invariant_i1.py \
  || echo "[WARN] plot_fig03_invariant_i1.py a échoué (probablement 07_invariant_i1.csv manquant)"

python zz-scripts/chapter07/plot_fig04_dcs2_vs_k.py \
  || echo "[WARN] plot_fig04_dcs2_vs_k.py a échoué (probablement 07_dcs2_dk.csv manquant)"

echo
echo "## Figures 05, 06, 07 (deltas / comparaison / invariant i2)"
python zz-scripts/chapter07/plot_fig05_ddelta_phi_vs_k.py \
  || echo "[ERREUR] plot_fig05_ddelta_phi_vs_k.py a échoué"

python zz-scripts/chapter07/plot_fig06_comparison.py \
  || echo "[ERREUR] plot_fig06_comparison.py a échoué"

python zz-scripts/chapter07/plot_fig07_invariant_i2.py \
  || echo "[ERREUR] plot_fig07_invariant_i2.py a échoué"

echo
echo "## Tests utilitaires k-grid et toy_model"
python zz-scripts/chapter07/utils/test_kgrid.py \
  || echo "[ERREUR] utils/test_kgrid.py a échoué"

python zz-scripts/chapter07/utils/toy_model.py \
  --out "${OUTDIR_SMOKE_UTILS}/toy_model_manual.png" \
  --dpi 96 \
  || echo "[ERREUR] utils/toy_model.py a échoué"

