#!/usr/bin/env bash
set -euo pipefail
mkdir -p _tmp assets/zz-figures/09_dark_energy_cpl
OUT="assets/zz-figures/09_dark_energy_cpl/09_fig_04_absdphi_milestones_vs_f.png"

python scripts/09_dark_energy_cpl/09_fig_04_absdphi_milestones_vs_f.py --log-level ERROR --out "$OUT"
echo "[ok] figure: $OUT"
