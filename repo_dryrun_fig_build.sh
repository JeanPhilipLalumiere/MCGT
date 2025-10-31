# repo_dryrun_fig_build.sh — aucun write dans le repo ; PNG dans /tmp
set -euo pipefail
OUT="/tmp/mcgt_figs_round2_$(date +%Y%m%dT%H%M%S)"
mkdir -p "$OUT"

# Source de données ch09
DIFF09="zz-data/chapter09/09_phase_diff.csv"

# Source chap10 (le plus riche)
RES10="zz-data/chapter10/10_mc_results.circ.with_fpeak.csv.gz"

echo "[DRYRUN] Build → $OUT"

# ch09 — fig03
python zz-scripts/chapter09/plot_fig03_hist_absdphi_20_300.py \
  --diff "$DIFF09" \
  --out "$OUT/09_fig_03_hist_absdphi_20_300.png" \
  --dpi 160 || true

# ch10 — fig01
python zz-scripts/chapter10/plot_fig01_iso_p95_maps.py \
  --results "$RES10" \
  --out "$OUT/10_fig_01_iso_p95_maps.png" \
  --dpi 160 || true

# ch10 — fig02 (OUT canonique déjà patché)
python zz-scripts/chapter10/plot_fig02_scatter_phi_at_fpeak.py \
  --results "$RES10" \
  --out "$OUT/10_fig_02_scatter_phi_at_fpeak.png" \
  --dpi 160 || true

# ch10 — fig03
python zz-scripts/chapter10/plot_fig03_convergence_p95_vs_n.py \
  --results "$RES10" \
  --out "$OUT/10_fig_03_convergence_p95_vs_n.png" \
  --dpi 160 --npoints 12 --B 400 || true

# ch10 — fig04 (cols explicites)
python zz-scripts/chapter10/plot_fig04_scatter_p95_recalc_vs_orig.py \
  --results "$RES10" \
  --orig-col p95_20_300 --recalc-col p95_20_300_recalc \
  --out "$OUT/10_fig_04_scatter_p95_recalc_vs_orig.png" \
  --dpi 160 || true

# ch10 — fig05
python zz-scripts/chapter10/plot_fig05_hist_cdf_metrics.py \
  --results "$RES10" \
  --out "$OUT/10_fig_05_hist_cdf_metrics.png" \
  --dpi 160 || true

echo
echo "== Résumé fichiers =="
ls -lh "$OUT"/*.png 2>/dev/null || echo "(aucun PNG produit)"
