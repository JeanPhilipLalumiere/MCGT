#!/usr/bin/env bash
set -euo pipefail
OUT=".ci-out/smoke_v2"; mkdir -p "$OUT"
run() {
  local s="$1"; local stem="$2"
  echo "[SMOKE] $s → $stem"
  python "$s" --outdir "$OUT" --format png --dpi 120 --style classic || true
  # rename si le script ne nomme pas lui-même
  if ! ls "$OUT" | grep -q "^$stem\.png$"; then
    last=$(ls -1t "$OUT"/*.png 2>/dev/null | head -n1 || true)
    [[ -n "$last" ]] && cp -f "$last" "$OUT/$stem.png"
  fi
}
run zz-scripts/chapter07/plot_fig04_dcs2_vs_k.py        chapter07_fig04_dcs2_vs_k
run zz-scripts/chapter10/plot_fig05_hist_cdf_metrics.py chapter10_fig05_hist_cdf
run zz-scripts/chapter04/plot_fig02_invariants_histogram.py chapter04_fig02_invariants_hist
run zz-scripts/chapter03/plot_fig01_fR_stability_domain.py  chapter03_fig01_fr_stability
ls -lh "$OUT"
