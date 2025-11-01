# repo_fix_round2_minimal_v2.sh
set -euo pipefail

bak() { f="$1"; [ -f "$f" ] && cp -a "$f" "${f}.bak_$(date +%Y%m%dT%H%M%S)"; }

############################################
# A) ch10/fig01 — indenter dans le try:{...}
############################################
F10=zz-scripts/chapter10/plot_fig01_iso_p95_maps.py
bak "$F10"

# Si la ligne 'df = ci.ensure_fig02_cols(df)' n'est indentée qu'à 0–4 espaces,
# on la force à 8 espaces (à l'intérieur du try:)
perl -0777 -pe 's/^[ \t]{0,4}(df\s*=\s*ci\.ensure_fig02_cols\(df\)\s*)$/        $1/m' -i "$F10"

############################################
# B) ch09/fig03 — connecteurs FR -> EN + None, None, None (sans virgules)
############################################
F09=zz-scripts/chapter09/plot_fig03_hist_absdphi_20_300.py
bak "$F09"

# 1) Remplacer les connecteurs français hors chaînes: "et"/"ou" -> "and"/"or"
# (heuristique sûre : entre deux mots)
perl -0777 -pe 's/(?<=\w)\s+et\s+(?=\w)/ and /g; s/(?<=\w)\s+ou\s+(?=\w)/ or /g' -i "$F09"

# 2) Les affectations avec virgule créent des tuples; on retire la virgule
# en gardant l'indentation à 4 espaces dans main()
perl -0777 -pe '
  s/^\s*data_label\s*=\s*None,\s*$/    data_label = None\n/m;
  s/^\s*f\s*=\s*None,\s*$/    f = None\n/m;
  s/^\s*abs_dphi\s*=\s*None,\s*$/    abs_dphi = None\n/m;
' -i "$F09"

echo "== DIFFS (v2) =="
git --no-pager diff -- "$F10" "$F09" | sed 's/^/DIFF /'

echo "== py_compile ciblé =="
python -m py_compile "$F10" "$F09" && echo "OK py_compile v2" || echo "ECHEC py_compile v2"

echo "== --help ciblé =="
set +e
python "$F10" --help | sed -n '1,25p'
python "$F09" --help | sed -n '1,25p'
set -e
