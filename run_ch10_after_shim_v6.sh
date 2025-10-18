#!/usr/bin/env bash
set -Eeuo pipefail
trap 's=$?; echo; echo "[DONE] Statut de sortie = $s"; echo; read -r -p "Appuyez sur Entrée pour fermer cette fenêtre (ou Ctrl+C)..." _' EXIT INT

cd ~/MCGT
conda activate mcgt-dev 2>/dev/null || source ~/miniforge3/bin/activate mcgt-dev || true
CSV="zz-data/chapter10/10_mc_results.circ.with_fpeak.csv"; test -r "$CSV" || { echo "[ERR] CSV manquant: $CSV"; exit 4; }
mkdir -p zz-figures/chapter10

python3 zz-scripts/chapter10/plot_fig03_convergence_p95_vs_n.py \
  --results "$CSV" --n-col n_20_300 --p95-col p95_20_300 \
  --dpi 300 --out zz-figures/chapter10/10_fig_03_convergence_p95_vs_n.png || true

python3 zz-scripts/chapter10/plot_fig03b_bootstrap_coverage_vs_n.py \
  --results "$CSV" --n-col n_20_300 --p95-col p95_20_300 \
  --dpi 300 --out zz-figures/chapter10/10_fig_03b_bootstrap_coverage_vs_n.png || true

python3 zz-scripts/chapter10/plot_fig04_scatter_p95_recalc_vs_orig.py \
  --results "$CSV" --orig-col p95_20_300 --recalc-col p95_20_300_circ \
  --dpi 300 --out zz-figures/chapter10/10_fig_04_scatter_p95_recalc_vs_orig.png || true

python3 zz-scripts/chapter10/plot_fig05_hist_cdf_metrics.py \
  --results "$CSV" --p95-col p95_20_300 \
  --dpi 300 --out zz-figures/chapter10/10_fig_05_hist_cdf_metrics.png || true

python3 zz-scripts/chapter10/plot_fig06_residual_map.py \
  --results "$CSV" --m1-col phi0 --m2-col phi_ref_fpeak \
  --dpi 300 --out zz-figures/chapter10/10_fig_06_residual_map.png || true

python3 tools/figure_manifest_builder.py || true
