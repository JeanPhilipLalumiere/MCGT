#!/usr/bin/env bash
# Reproduce core paper outputs for MCGT from a fresh environment.
# Usage:
#   ./reproduce_paper_results.sh            # quick test run
#   ./reproduce_paper_results.sh test       # quick test run
#   ./reproduce_paper_results.sh full       # full MCMC run

set -euo pipefail

MODE="${1:-test}"

if [[ "${MODE}" != "test" && "${MODE}" != "full" ]]; then
  echo "[error] Unknown mode: ${MODE}. Use 'test' or 'full'."
  exit 1
fi

echo "[step] Installing pinned Python dependencies..."
python -m pip install --upgrade pip
python -m pip install -r requirements.txt

mkdir -p output

if [[ "${MODE}" == "test" ]]; then
  echo "[step] Running quick validation MCMC (CPL model)..."
  # Fast sanity-check used for reproducibility validation in CI/review.
  python run_mcmc.py --quick-test --model cpl
else
  echo "[step] Running full MCMC inference (CPL model)..."
  # Full inference used to regenerate publication-grade posterior samples.
  python run_mcmc.py --model cpl
fi

echo "[step] Generating corner plot from produced chain..."
python plot_corner.py \
  --input output/mcgt_chains.h5 \
  --chain-name mcgt_chain \
  --out-pdf output/mcgt_corner_plot.pdf \
  --out-png output/mcgt_corner_plot.png

echo "[ok] Reproducibility pipeline completed in '${MODE}' mode."
