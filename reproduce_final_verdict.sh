#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "${ROOT_DIR}"

export MCGT_USE_TEX="${MCGT_USE_TEX:-0}"
export MPLBACKEND="${MPLBACKEND:-Agg}"
export PYTHONUNBUFFERED="${PYTHONUNBUFFERED:-1}"

echo "[info] Regenerating Phase 3 outputs for Figure 09"
python scripts/phase3_lss_geometry_report.py

echo "[info] Regenerating Phase 4 outputs for Table 2"
python scripts/phase4_global_verdict.py

echo "[info] Verifying Table 2 consistency"
python scripts/verify_table_consistency.py

test -f assets/zz-figures/06_early_growth_jwst/06_fig_09_structure_growth_factor.png
test -f assets/zz-data/10_global_scan/10_table_02_marginalized_constraints.csv
test -f output/ptmg_predictions_z0_to_z20.csv
test -f output/ptmg_corner_plot.pdf

echo "[pass] Final verdict artifacts reproduced: Figure 09, Table 2, and synchronized /output artifacts are present."
