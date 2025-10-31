# repo_ctx_show_offenders.sh — lecture seule, n'écrit rien
set +euo pipefail
ctx () { f="$1"; l="$2"; a="${3:-12}"; s=$((l-a)); [ $s -lt 1 ] && s=1; e=$((l+a)); nl -ba "$f" | sed -n "${s},${e}p"; echo; }

echo "== ch09/fig03 (IndentationError after def, line ~98) ==";
ctx zz-scripts/chapter09/plot_fig03_hist_absdphi_20_300.py 98 14

echo "== ch10/fig01 (SyntaxError: expected except/finally, line ~50) ==";
ctx zz-scripts/chapter10/plot_fig01_iso_p95_maps.py 50 20
# repérer les 'try:' sans except/finally dans le fichier ch10/fig01
echo "-- try/except map (line: text) --"
nl -ba zz-scripts/chapter10/plot_fig01_iso_p95_maps.py | rg -n ':\s*try\s*:|:\s*except\s|:\s*finally\s*:' --no-line-number | sed 's/^/  /'

echo "== ch10/fig03 (IndentationError line ~137) ==";
ctx zz-scripts/chapter10/plot_fig03_convergence_p95_vs_n.py 137 16

echo "== ch10/fig04 (IndentationError line ~118) ==";
ctx zz-scripts/chapter10/plot_fig04_scatter_p95_recalc_vs_orig.py 118 16

echo "== ch10/fig05 (IndentationError line ~84) ==";
ctx zz-scripts/chapter10/plot_fig05_hist_cdf_metrics.py 84 16

echo "== Tabs vs spaces quickscan (les tabs déclenchent souvent ces erreurs) ==";
rg -nP "\t" zz-scripts/chapter0{9,10}/*.py || true

read -r -p "[PAUSE] Entrée..." _
