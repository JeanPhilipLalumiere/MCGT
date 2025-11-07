#!/usr/bin/env bash
set -euo pipefail

F="zz-scripts/chapter10/plot_fig05_hist_cdf_metrics.py"

echo "[PATCH] fig05: remplacer *toute* occurrence de plt.tight_layout(...) par fig.subplots_adjust(...)"

# Remplace n'importe quel appel à tight_layout (même sur une ligne avec d'autres statements)
perl -0777 -pe 's/plt\.tight_layout\([^;]*\);\s*/fig=plt.gcf(); fig.subplots_adjust(left=0.07,right=0.98,top=0.93,bottom=0.18);\n/g' -i "$F"

echo "[CHECK] Vérifier qu il ne reste plus de tight_layout"
if grep -n "tight_layout" "$F"; then
  echo "[WARN] Des occurrences subsistent, revoir le fichier."
else
  echo "[OK] Plus de tight_layout dans $F"
fi

echo "[TEST] Re-génère fig05"
OUT_DIR="zz-out/chapter10"
DATA_DIR="zz-data/chapter10"
python3 "$F" --results "$DATA_DIR/dummy_results.csv" --out "$OUT_DIR/fig05_hist_cdf.png" --bins 40 --dpi 120

echo "[DONE] Patch + test fig05 OK."
