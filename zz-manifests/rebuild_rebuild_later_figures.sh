#!/usr/bin/env bash
# AUTO-GENERATED helper to rebuild REBUILD_LATER figures
set -Eeuo pipefail

ROOT="${1:-$PWD}"
cd "$ROOT"

echo "[INFO] Rebuild chapter07/fig_03_invariant_i1 via zz-scripts/chapter07/plot_fig03_invariant_I1.py"
python "zz-scripts/chapter07/plot_fig03_invariant_I1.py"

echo "[INFO] Rebuild chapter07/fig_06_comparison via zz-scripts/chapter07/plot_fig06_comparison.py"
python "zz-scripts/chapter07/plot_fig06_comparison.py"

echo "[INFO] Rebuild chapter07/fig_07_invariant_i2 via zz-scripts/chapter07/plot_fig07_invariant_I2.py"
python "zz-scripts/chapter07/plot_fig07_invariant_I2.py"

echo "[INFO] Rebuild chapter09/fig_01_phase_overlay via zz-scripts/chapter09/plot_fig01_phase_overlay.py"
python "zz-scripts/chapter09/plot_fig01_phase_overlay.py"

echo "[INFO] Rebuild chapter09/fig_02_residual_phase via zz-scripts/chapter09/plot_fig02_residual_phase.py.bak"
python "zz-scripts/chapter09/plot_fig02_residual_phase.py.bak"

echo "[INFO] Rebuild chapter09/fig_05_scatter_phi_at_fpeak via zz-scripts/chapter09/plot_fig05_scatter_phi_at_fpeak.py"
python "zz-scripts/chapter09/plot_fig05_scatter_phi_at_fpeak.py"
