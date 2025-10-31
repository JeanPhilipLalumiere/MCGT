# repo_probe_fig_producers_and_help.sh (lecture seule)
set +e; set -u
REPO="${REPO:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cd "$REPO" || exit 1

miss_slugs=(
  "zz-figures/chapter09/09_fig_01_phase_overlay.png"
  "zz-figures/chapter09/09_fig_03_hist_absdphi_20_300.png"
  "zz-figures/chapter10/10_fig_01_iso_p95_maps.png"
  "zz-figures/chapter10/10_fig_02_scatter_phi_at_fpeak.png"
  "zz-figures/chapter10/10_fig_03_convergence_p95_vs_n.png"
  "zz-figures/chapter10/10_fig_04_scatter_p95_recalc_vs_orig.png"
  "zz-figures/chapter10/10_fig_05_hist_cdf_metrics.png"
)

echo "== PRODUCTEURS POTENTIELS (grep DEF_OUT / default=) =="
for s in "${miss_slugs[@]}"; do
  bn="$(basename "$s")"
  echo "-- $bn --"
  rg -n --hidden --glob 'zz-scripts/**' -e "$bn" -e "${bn/maps/mapss}" -e "${bn/_02_/02_}" -e "${bn/_03_/03_}" \
     -e "${bn/_04_/04_}" -e "${bn/_05_/05_}" | sed 's/^/  /' || true
done

echo; echo "== CONTRÔLE LIGNES DEF_OUT / default= =="
rg -n --hidden --glob 'zz-scripts/chapter0{9,10}/*.py' -e 'DEF_OUT|default="' \
  | sed 's/^/  /'

echo; echo "== TEST --help des producteurs connus =="
producers=(
  "zz-scripts/chapter09/plot_fig01_phase_overlay.py"
  "zz-scripts/chapter09/plot_fig03_hist_absdphi_20_300.py"
  "zz-scripts/chapter10/plot_fig01_iso_p95_maps.py"
  "zz-scripts/chapter10/plot_fig03_convergence_p95_vs_n.py"
  "zz-scripts/chapter10/plot_fig04_scatter_p95_recalc_vs_orig.py"
  "zz-scripts/chapter10/plot_fig05_hist_cdf_metrics.py"
)
for p in "${producers[@]}"; do
  if [ -f "$p" ]; then
    echo ">>> $p --help"
    python "$p" --help >/tmp/help_$(basename "$p").txt 2>&1
    ec=$?; echo "exit=$ec; sample:"; head -n 8 /tmp/help_$(basename "$p").txt
  else
    echo "MISSING SCRIPT: $p"
  fi
done

echo; echo "== CHASSE ciblée du #2 (fpeak) =="
rg -n --hidden --glob 'zz-scripts/**' -e 'fig_02|fpeak|phi_at_fpeak' | sed 's/^/  /'
read -r -p "[PAUSE] Entrée..." _
