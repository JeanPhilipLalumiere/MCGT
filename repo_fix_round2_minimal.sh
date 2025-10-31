# repo_fix_round2_minimal.sh — PATCHS SÛRS, RÉVERSIBLES
set -euo pipefail

bak() { f="$1"; [ -f "$f" ] && cp -a "$f" "${f}.bak_$(date +%Y%m%dT%H%M%S)"; }

# A) ch10 (fig01/03/04/05) : la ligne "df = ci.ensure_fig02_cols(df)" doit être indentée
for f in \
  zz-scripts/chapter10/plot_fig01_iso_p95_maps.py \
  zz-scripts/chapter10/plot_fig03_convergence_p95_vs_n.py \
  zz-scripts/chapter10/plot_fig04_scatter_p95_recalc_vs_orig.py \
  zz-scripts/chapter10/plot_fig05_hist_cdf_metrics.py
do
  bak "$f"
done

# Ajoute 4 espaces **uniquement** si la ligne commence en colonne 1
perl -0777 -pe 's/^\K(df\s*=\s*ci\.ensure_fig02_cols\(df\)\s*)$/    $1/m' -i \
  zz-scripts/chapter10/plot_fig01_iso_p95_maps.py \
  zz-scripts/chapter10/plot_fig03_convergence_p95_vs_n.py \
  zz-scripts/chapter10/plot_fig04_scatter_p95_recalc_vs_orig.py \
  zz-scripts/chapter10/plot_fig05_hist_cdf_metrics.py

# B) ch09 (fig03) : indenter le début de main() — on NE modifie PAS la logique
f=zz-scripts/chapter09/plot_fig03_hist_absdphi_20_300.py
bak "$f"
perl -0777 -pe '
  s/^\K(args\s*=\s*parse_args\(\))$/    $1/m;
  s/^\K(log\s*=\s*setup_logger\([^\n]*\))$/    $1/m;
  s/^\K(data_label\s*=\s*None,)\s*$/    $1/m;
  s/^\K(f\s*=\s*None,)\s*$/    $1/m;
  s/^\K(abs_dphi\s*=\s*None,)\s*$/    $1/m;
  s/^\K(if\s+args\.diff\.exists\(\)\s*:)\s*$/    $1/m;
' -i "$f"

echo "== DIFFS minimaux =="
git --no-pager diff -- \
  zz-scripts/chapter10/plot_fig01_iso_p95_maps.py \
  zz-scripts/chapter10/plot_fig03_convergence_p95_vs_n.py \
  zz-scripts/chapter10/plot_fig04_scatter_p95_recalc_vs_orig.py \
  zz-scripts/chapter10/plot_fig05_hist_cdf_metrics.py \
  zz-scripts/chapter09/plot_fig03_hist_absdphi_20_300.py | sed 's/^/DIFF /'

echo "== COMPILE (bytecode) =="
python -m py_compile \
  zz-scripts/chapter10/plot_fig01_iso_p95_maps.py \
  zz-scripts/chapter10/plot_fig03_convergence_p95_vs_n.py \
  zz-scripts/chapter10/plot_fig04_scatter_p95_recalc_vs_orig.py \
  zz-scripts/chapter10/plot_fig05_hist_cdf_metrics.py \
  zz-scripts/chapter09/plot_fig03_hist_absdphi_20_300.py \
  && echo "OK py_compile" || echo "ECHEC py_compile"

echo "== --help (sanity) =="
set +e
python zz-scripts/chapter10/plot_fig01_iso_p95_maps.py --help | sed -n '1,25p'
python zz-scripts/chapter10/plot_fig03_convergence_p95_vs_n.py --help | sed -n '1,25p'
python zz-scripts/chapter10/plot_fig04_scatter_p95_recalc_vs_orig.py --help | sed -n '1,25p'
python zz-scripts/chapter10/plot_fig05_hist_cdf_metrics.py --help | sed -n '1,25p'
python zz-scripts/chapter09/plot_fig03_hist_absdphi_20_300.py --help | sed -n '1,25p'
set -e
