#!/usr/bin/env bash
set -Eeuo pipefail
F="zz-scripts/chapter02/plot_fig05_FG_series.py"
echo "== TRIAGE: $F =="
python "$F" --help >/dev/null 2>_tmp/triage_fig05.stderr || true
echo "---- STDERR ----"; cat _tmp/triage_fig05.stderr || true
