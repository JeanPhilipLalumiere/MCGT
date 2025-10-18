#!/usr/bin/env bash
set -Eeuo pipefail

pause_on_exit() {
  local s=$?
  echo
  echo "[DONE] Statut de sortie = $s"
  echo
  if [ -t 0 ]; then
    read -r -p "Appuyez sur Entrée pour fermer cette fenêtre (ou Ctrl+C)..." _
  fi
}
trap pause_on_exit EXIT INT

cd ~/MCGT
conda activate mcgt-dev 2>/dev/null || source ~/miniforge3/bin/activate mcgt-dev || true

CSV="zz-data/chapter10/10_mc_results.circ.with_fpeak.csv"
test -r "$CSV" || { echo "[ERR] CSV manquant: $CSV"; exit 4; }
mkdir -p zz-figures/chapter10

# fig03 — convergence p95 vs n (⚠ pas de --n-col ; le script ne le supporte pas)
python3 zz-scripts/chapter10/plot_fig03_convergence_p95_vs_n.py \
  --results "$CSV" --p95-col p95_20_300 \
  --dpi 300 --out zz-figures/chapter10/10_fig_03_convergence_p95_vs_n.png || true

# fig03b — bootstrap coverage vs n (on fournit des titres pour éviter toute dépendance)
python3 zz-scripts/chapter10/plot_fig03b_bootstrap_coverage_vs_n.py \
  --results "$CSV" --p95-col p95_20_300 \
  --title-left "Bootstrap coverage vs N" \
  --title-right "Interval width vs N" \
  --dpi 300 --out zz-figures/chapter10/10_fig_03b_bootstrap_coverage_vs_n.png || true

# fig04 — scatter p95 recalculé vs original (+ hist_x/y au besoin)
python3 zz-scripts/chapter10/plot_fig04_scatter_p95_recalc_vs_orig.py \
  --results "$CSV" --orig-col p95_20_300 --recalc-col p95_20_300_circ \
  --hist-x 0 --hist-y 0 \
  --dpi 300 --out zz-figures/chapter10/10_fig_04_scatter_p95_recalc_vs_orig.png || true

# fig05 — hist/CDF de p95 (⚠ ne PAS passer --p95-col, non supporté par ce script)
python3 zz-scripts/chapter10/plot_fig05_hist_cdf_metrics.py \
  --results "$CSV" \
  --dpi 300 --out zz-figures/chapter10/10_fig_05_hist_cdf_metrics.png || true

# fig06 — residual map (phi0 vs phi_ref_fpeak) + figsize pour éviter l’AttributeError
python3 zz-scripts/chapter10/plot_fig06_residual_map.py \
  --results "$CSV" --m1-col phi0 --m2-col phi_ref_fpeak \
  --figsize 6,5 \
  --dpi 300 --out zz-figures/chapter10/10_fig_06_residual_map.png || true

# MAJ du manifest
python3 tools/figure_manifest_builder.py || true
