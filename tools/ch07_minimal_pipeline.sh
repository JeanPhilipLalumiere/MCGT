#!/usr/bin/env bash
# ch07_minimal_pipeline.sh – Pipeline minimal Chapitre 07 (perturbations scalaires)

set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "# ch07_minimal_pipeline.sh – Pipeline minimal Chapitre 07 (perturbations scalaires)"
echo "# Root : $ROOT"
echo

mkdir -p zz-out/smoke/chapter07
mkdir -p zz-out/chapter07

echo "## 1) Smoke – generate_data_chapter07.py --dry-run"
python zz-scripts/chapter07/generate_data_chapter07.py \
  -i zz-configuration/scalar_perturbations.ini \
  --export-raw zz-out/smoke/chapter07/generate_data_chapter07_manual.csv \
  --dry-run

echo
echo "## 2) Smoke – launch_scalar_perturbations_solver.py --dry-run"
python zz-scripts/chapter07/launch_scalar_perturbations_solver.py \
  -i zz-configuration/scalar_perturbations.ini \
  --export-raw zz-out/smoke/chapter07/launch_scalar_perturbations_solver_manual.csv \
  --dry-run

echo
echo "## 3) Run complet minimal – generate_data_chapter07.py"
set +e
python zz-scripts/chapter07/generate_data_chapter07.py \
  -i zz-configuration/scalar_perturbations.ini \
  --export-raw zz-data/chapter07/07_scan_raw_minimal.csv \
  --export-2d \
  --n-k 32 \
  --n-a 20 \
  --log-level INFO \
  --log-file zz-out/chapter07/generate_data_chapter07_minimal.log
status=$?
set -e

if [[ "$status" -ne 0 ]]; then
  echo
  echo "[WARN] generate_data_chapter07.py a terminé avec un code $status."
  echo "       Si le message d'erreur mentionne 'c_s^2 hors-borne ou non-fini',"
  echo "       il s'agit d'un échec *attendu* pour le profil canonique actuel."
else
  echo "[OK] generate_data_chapter07.py terminé sans erreur."
fi

echo
echo "## 4) Run complet minimal – launch_scalar_perturbations_solver.py"
python zz-scripts/chapter07/launch_scalar_perturbations_solver.py \
  -i zz-configuration/scalar_perturbations.ini \
  --export-raw zz-data/chapter07/07_phase_run.csv \
  --log-level INFO \
  --log-file zz-out/chapter07/launch_scalar_perturbations_solver_minimal.log

echo
echo "## 5) Figures principales (Fig. 01 à 07)"

echo "# 5.1 plot_fig01_cs2_heatmap.py"
python zz-scripts/chapter07/plot_fig01_cs2_heatmap.py

echo "# 5.2 plot_fig02_delta_phi_heatmap.py"
python zz-scripts/chapter07/plot_fig02_delta_phi_heatmap.py

echo "# 5.3 plot_fig03_invariant_i1.py"
python zz-scripts/chapter07/plot_fig03_invariant_i1.py

echo "# 5.4 plot_fig04_dcs2_vs_k.py"
python zz-scripts/chapter07/plot_fig04_dcs2_vs_k.py

echo "# 5.5 plot_fig05_ddelta_phi_vs_k.py"
python zz-scripts/chapter07/plot_fig05_ddelta_phi_vs_k.py

echo "# 5.6 plot_fig06_comparison.py"
python zz-scripts/chapter07/plot_fig06_comparison.py

echo "# 5.7 plot_fig07_invariant_i2.py"
python zz-scripts/chapter07/plot_fig07_invariant_i2.py

echo
echo "[DONE] Pipeline minimal CH07 terminé."
