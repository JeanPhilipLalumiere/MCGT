#!/usr/bin/env bash
set -euo pipefail

S="zz-scripts/chapter10"
D="zz-data/chapter10"
O="zz-out/chapter10"
mkdir -p "$O"

echo "[CHECK] recherche de tight_layout (hors lignes commentées)"
viol=$(awk '/tight_layout/ && $0 !~ /^[[:space:]]*#/{print FILENAME ":" FNR ":" $0}' $(find "$S" -maxdepth 1 -name "*.py") || true)
if [[ -n "${viol}" ]]; then
  echo "${viol}"
  echo "[FAIL] Des appels actifs à tight_layout subsistent."
  exit 1
fi
echo "[OK] Aucun appel actif à tight_layout"

echo "[CHECK] --help sur chaque script principal"
for f in \
  plot_fig01_iso_p95_maps.py \
  plot_fig02_scatter_phi_at_fpeak.py \
  plot_fig03_convergence_p95_vs_n.py \
  plot_fig03b_bootstrap_coverage_vs_n.py \
  plot_fig04_scatter_p95_recalc_vs_orig.py \
  plot_fig05_hist_cdf_metrics.py \
  plot_fig06_residual_map.py \
  plot_fig07_synthesis.py
do
  echo "  -> $f --help"
  python3 "$S/$f" --help >/dev/null
done
echo "[OK] Parseurs OK"

echo "[RUN] Exécutions minimales"
python3 "$S/plot_fig01_iso_p95_maps.py" --results "$D/dummy_results.csv" --out "$O/fig01.png" --levels 12 --no-clip
python3 "$S/plot_fig02_scatter_phi_at_fpeak.py" --results "$D/dummy_results.csv" --out "$O/fig02.png" --alpha 0.6 --pi-ticks
python3 "$S/plot_fig03_convergence_p95_vs_n.py" --results "$D/dummy_results.csv" --out "$O/fig03.png" --B 120 --npoints 8 --dpi 120
python3 "$S/plot_fig03b_bootstrap_coverage_vs_n.py" --results "$D/dummy_results.csv" --out "$O/fig03b.png" --outer 300 --inner 400 --npoints 6 --alpha 0.05 --minN 30
python3 "$S/plot_fig04_scatter_p95_recalc_vs_orig.py" --results "$D/dummy_results.csv" --out "$O/fig04.png" --point-size 8
python3 "$S/plot_fig05_hist_cdf_metrics.py" --results "$D/dummy_results.csv" --out "$O/fig05.png" --bins 40 --ref-p95 1.0
python3 "$S/plot_fig06_residual_map.py" --results "$D/dummy_results.csv" --out "$O/fig06.png" --metric dp95 --abs --gridsize 24 --mincnt 3 --scale-exp -7 --threshold 1e-6
python3 "$S/plot_fig07_synthesis.py" \
  --manifest "$O/fig03b_cov_A.manifest.json" \
  --manifest "$O/fig03b_cov_B.manifest.json" \
  --out "$O/fig07.png" \
  --csv "$O/fig07_summary.csv"

echo "[DONE] Smoke OK — sorties dans $O"
