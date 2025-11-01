# repo_regen_and_install_round2_figs.sh
set -euo pipefail
OUT="/tmp/mcgt_figs_round2_pack_$(date +%Y%m%dT%H%M%S)"
mkdir -p "$OUT"

# --- (A) SOURCES possibles déjà générées en /tmp
mapfile -t CANDIDATES < <(ls -d /tmp/mcgt_figs_round2_* 2>/dev/null | sort -r || true)

# --- (B) Helper pour copier sans écraser
copy_if_found () {
  local src="$1" dst="$2"
  if [[ -f "$src" ]]; then
    mkdir -p "$(dirname "$dst")"
    # Remplacer 'install -n' (non portable) par cp --no-clobber --update=none
    cp --no-clobber --update=none "$src" "$dst" && echo "[COPIED] $src -> $dst" || echo "[SKIP] $dst existe déjà"
  else
    echo "[MISS] $src"
  fi
}

# --- (C) Essaye d’abord de récupérer depuis /tmp (tes runs précédents)
FOUND_ANY=0
for D in "${CANDIDATES[@]}"; do
  for b in 10_fig_01_iso_p95_maps.png 10_fig_02_scatter_phi_at_fpeak.png \
           10_fig_03_convergence_p95_vs_n.png 10_fig_04_scatter_p95_recalc_vs_orig.png \
           10_fig_05_hist_cdf_metrics.png 09_fig_03_hist_absdphi_20_300.png
  do
    if [[ -f "$D/$b" ]]; then
      copy_if_found "$D/$b" "zz-figures/chapter${b:0:2}/$b"
      FOUND_ANY=1
    fi
  done
done

# --- (D) Si manquants, régénère proprement vers $OUT
need_gen=()
[[ ! -f zz-figures/chapter10/10_fig_01_iso_p95_maps.png ]] && need_gen+=("fig01")
[[ ! -f zz-figures/chapter10/10_fig_02_scatter_phi_at_fpeak.png ]] && need_gen+=("fig02")
[[ ! -f zz-figures/chapter10/10_fig_03_convergence_p95_vs_n.png ]] && need_gen+=("fig03")
[[ ! -f zz-figures/chapter10/10_fig_04_scatter_p95_recalc_vs_orig.png ]] && need_gen+=("fig04")
[[ ! -f zz-figures/chapter10/10_fig_05_hist_cdf_metrics.png ]] && need_gen+=("fig05")
[[ ! -f zz-figures/chapter09/09_fig_03_hist_absdphi_20_300.png ]] && need_gen+=("ch09fig03")

if (( ${#need_gen[@]} > 0 )); then
  echo "[REGEN] ${need_gen[*]} → $OUT"
  # Entrées attendues (déjà présentes chez toi)
  R10="zz-data/chapter10/10_mc_results.circ.with_fpeak.csv.gz"
  D09="zz-data/chapter09/09_phase_diff.csv"

  for tag in "${need_gen[@]}"; do
    case "$tag" in
      fig01)
        python zz-scripts/chapter10/plot_fig01_iso_p95_maps.py \
          --results "$R10" --out "$OUT/10_fig_01_iso_p95_maps.png" --dpi 150 || true
        copy_if_found "$OUT/10_fig_01_iso_p95_maps.png" "zz-figures/chapter10/10_fig_01_iso_p95_maps.png"
        ;;
      fig02)
        python zz-scripts/chapter10/plot_fig02_scatter_phi_at_fpeak.py \
          --results "$R10" --out "$OUT/10_fig_02_scatter_phi_at_fpeak.png" --dpi 150 || true
        copy_if_found "$OUT/10_fig_02_scatter_phi_at_fpeak.png" "zz-figures/chapter10/10_fig_02_scatter_phi_at_fpeak.png"
        ;;
      fig03)
        python zz-scripts/chapter10/plot_fig03_convergence_p95_vs_n.py \
          --results "$R10" --out "$OUT/10_fig_03_convergence_p95_vs_n.png" --dpi 150 || true
        copy_if_found "$OUT/10_fig_03_convergence_p95_vs_n.png" "zz-figures/chapter10/10_fig_03_convergence_p95_vs_n.png"
        ;;
      fig04)
        python zz-scripts/chapter10/plot_fig04_scatter_p95_recalc_vs_orig.py \
          --results "$R10" --out "$OUT/10_fig_04_scatter_p95_recalc_vs_orig.png" --dpi 150 || true
        copy_if_found "$OUT/10_fig_04_scatter_p95_recalc_vs_orig.png" "zz-figures/chapter10/10_fig_04_scatter_p95_recalc_vs_orig.png"
        ;;
      fig05)
        python zz-scripts/chapter10/plot_fig05_hist_cdf_metrics.py \
          --results "$R10" --out "$OUT/10_fig_05_hist_cdf_metrics.png" --dpi 150 || true
        copy_if_found "$OUT/10_fig_05_hist_cdf_metrics.png" "zz-figures/chapter10/10_fig_05_hist_cdf_metrics.png"
        ;;
      ch09fig03)
        python zz-scripts/chapter09/plot_fig03_hist_absdphi_20_300.py \
          --diff "$D09" --out "$OUT/09_fig_03_hist_absdphi_20_300.png" --dpi 150 || true
        copy_if_found "$OUT/09_fig_03_hist_absdphi_20_300.png" "zz-figures/chapter09/09_fig_03_hist_absdphi_20_300.png"
        ;;
    esac
  done
fi

echo "== Probe Round2 =="
bash repo_probe_round2_consistency.sh
