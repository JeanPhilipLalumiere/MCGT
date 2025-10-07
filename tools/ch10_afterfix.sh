#!/usr/bin/env bash
set -euo pipefail

echo "[PATCH] Remplacer tight_layout par subplots_adjust (fig03, fig04, fig05)"

# fig03
perl -0777 -pe 's/plt\.tight_layout\([^)]*\);\s*fig\.savefig\((args\.out),\s*dpi=args\.dpi\)/fig.subplots_adjust(left=0.06,right=0.98,top=0.95,bottom=0.14,wspace=0.28); fig.savefig(\1, dpi=args.dpi)/s' \
  -i zz-scripts/chapter10/plot_fig03_convergence_p95_vs_n.py

# fig04
perl -0777 -pe 's/plt\.tight_layout\([^)]*\);\s*fig\.savefig\((args\.out),\s*dpi=args\.dpi\)/fig.subplots_adjust(left=0.10,right=0.98,top=0.95,bottom=0.10); fig.savefig(\1, dpi=args.dpi)/s' \
  -i zz-scripts/chapter10/plot_fig04_scatter_p95_recalc_vs_orig.py

# fig05
perl -0777 -pe 's/plt\.tight_layout\([^)]*\);\s*fig=plt\.gcf\(\);\s*fig\.text\(([^;]+)\);\s*fig\.savefig\((args\.out),\s*dpi=args\.dpi\)/fig=plt.gcf(); fig.text(\1); fig.subplots_adjust(left=0.07,right=0.98,top=0.93,bottom=0.18); fig.savefig(\2, dpi=args.dpi)/s' \
  -i zz-scripts/chapter10/plot_fig05_hist_cdf_metrics.py

echo "[TEST] Relance rapide des 3 figures pour vérifier l’absence de warning"
OUT_DIR="zz-out/chapter10"
DATA_DIR="zz-data/chapter10"
S="zz-scripts/chapter10"

python3 "$S/plot_fig03_convergence_p95_vs_n.py" --results "$DATA_DIR/dummy_results.csv" --out "$OUT_DIR/fig03_convergence.png" --B 120 --npoints 8 --dpi 120
python3 "$S/plot_fig04_scatter_p95_recalc_vs_orig.py" --results "$DATA_DIR/dummy_results.csv" --out "$OUT_DIR/fig04_scatter_p95.png" --with-zoom --dpi 120
python3 "$S/plot_fig05_hist_cdf_metrics.py" --results "$DATA_DIR/dummy_results.csv" --out "$OUT_DIR/fig05_hist_cdf.png" --bins 40 --dpi 120

echo "[OK] Patch appliqué et vérifié."
