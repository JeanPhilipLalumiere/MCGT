# repo_fix_ch09_fig03_connector.sh
set -euo pipefail
F=zz-scripts/chapter09/plot_fig03_hist_absdphi_20_300.py
cp -a "$F" "${F}.bak_$(date +%Y%m%dT%H%M%S)"

# Remplace le connecteur FR 'et' par 'and' pour la condition fautive
perl -0777 -pe 's/(\bargs\.diff)\s+et\s+\{/\1 and {/g' -i "$F"

echo "== DIFF =="
git --no-pager diff -- "$F" | sed 's/^/DIFF /'

echo "== py_compile =="
python -m py_compile "$F" && echo "OK py_compile ch09/fig03"

echo "== --help (aperçu) =="
python "$F" --help | sed -n '1,25p'

echo "== Scan résiduel ' et {' =="
rg -n ' et \{' "$F" || true
