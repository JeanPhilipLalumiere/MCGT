# repo_fix_ch09_fig03_fstring.sh
set -euo pipefail
F=zz-scripts/chapter09/plot_fig03_hist_absdphi_20_300.py
BKP="${F}.bak_$(date +%Y%m%dT%H%M%S)"
cp -a "$F" "$BKP"

# (A) Sécurise le connecteur déjà vu (au cas où il réapparaît)
perl -0777 -pe 's/(\bargs\.diff)\s+(et|and)\s+\{/\1 and {/g' -i "$F"

# (B) Remplace le bloc f-string illégal par un guard minimal et valide
python - "$F" <<'PY'
import re, sys, pathlib
p = pathlib.Path(sys.argv[1])
s = p.read_text()

# Corrige le bloc du type:
# if not args.csv.exists():
#     pass
# raise SystemExit(
# f"Aucun fichier d'entrée: {
# args.diff ... {
# args.csv}")
s = re.sub(
    r"if\s+not\s+args\.csv\.exists\(\):\s*\n\s*pass\s*\n\s*raise\s+SystemExit\(\s*f\"Aucun fichier d'entrée:\s*\{.*?\}\s*\)\s*",
    "if not args.csv.exists():\n    raise SystemExit(f\"Aucun fichier d'entrée: {args.csv}\")\n",
    s, flags=re.S
)
p.write_text(s)
PY

echo "== py_compile =="
python -m py_compile "$F" && echo "OK py_compile ch09/fig03"

echo "== --help aperçu =="
python "$F" --help | sed -n '1,35p'
