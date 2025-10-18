#!/usr/bin/env bash
# Corrige les indentations restantes des scripts chap.10 signalés dans les logs
set -Eeuo pipefail

cd ~/MCGT

fix() {
  local file="$1" pat="$2"
  if grep -n -E "^[[:space:]]+${pat//\[/\\[}" "$file" >/dev/null 2>&1; then
    sed -ri "s|^[[:space:]]+(${pat})|\1|" "$file"
    echo "[FIX] dé-dent $file → $pat"
  else
    echo "[OK ] pas d’indent à retirer $file → $pat"
  fi
}

# fig03
fix "zz-scripts/chapter10/plot_fig03_convergence_p95_vs_n.py" 'p95 = df\[p95_col\]\.dropna\(\)\.astype\(float\)\.values'

# fig04
fix "zz-scripts/chapter10/plot_fig04_scatter_p95_recalc_vs_orig.py" 'recalc_col = detect_column\(df, args\.recalc_col, \[args\.recalc_col\]\)'

# fig05
fix "zz-scripts/chapter10/plot_fig05_hist_cdf_metrics.py" 'p95 = df\[p95_col\]\.dropna\(\)\.astype\(float\)\.values'

# fig06 (déjà x corrigé ; compléter avec y et z s’ils existent)
fix "zz-scripts/chapter10/plot_fig06_residual_map.py" 'y = df\[args\.m2_col\]\.astype\(float\)\.values'
fix "zz-scripts/chapter10/plot_fig06_residual_map.py" 'x = df\[args\.m1_col\]\.astype\(float\)\.values'
fix "zz-scripts/chapter10/plot_fig06_residual_map.py" 'res = y - x'

echo "[DONE] Patches d’indentation appliqués."
