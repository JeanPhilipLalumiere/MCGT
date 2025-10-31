# repo_dryrun_missing_pair.sh
set -euo pipefail
OUT="/tmp/mcgt_figs_round2_fix_$(date +%Y%m%dT%H%M%S)"
mkdir -p "$OUT"

# ch09 — fig03 (hist abs dphi)
python zz-scripts/chapter09/plot_fig03_hist_absdphi_20_300.py \
  --diff zz-data/chapter09/09_phase_diff.csv \
  --out  "$OUT/09_fig_03_hist_absdphi_20_300.png" \
  --dpi  160 || true

# ch10 — fig01 (déjà OK, on régénère pour la route)
python zz-scripts/chapter10/plot_fig01_iso_p95_maps.py \
  --results zz-data/chapter10/10_mc_results.circ.with_fpeak.csv.gz \
  --out     "$OUT/10_fig_01_iso_p95_maps.png" \
  --dpi     160 || true

echo "== Résumé =="
ls -lh "$OUT"/*.png 2>/dev/null || echo "(aucun PNG produit)"
