#!/usr/bin/env bash
set -euo pipefail

F="zz-scripts/chapter10/plot_fig07_synthesis.py"

echo "[PATCH] fig07: réinsertion de l'alias --csv avec l'indentation correcte"

python3 - <<'PY'
import re, pathlib, sys
p = pathlib.Path("zz-scripts/chapter10/plot_fig07_synthesis.py")
s = p.read_text(encoding="utf-8")

# 0) retirer toute ligne existante d'alias --csv dest='summary_csv' (mal indentée ou dupliquée)
s = re.sub(
    r'^[ \t]*p\.add_argument\(\s*[\'"]--csv[\'"].*?dest\s*=\s*[\'"]summary_csv[\'"].*?\)\s*\n',
    '',
    s,
    flags=re.MULTILINE,
)

# 1) trouver la ligne --summary-csv et capturer son indentation
m = re.search(r'^([ \t]*)p\.add_argument\([^)]*--summary-csv[^)]*\)\s*$', s, flags=re.MULTILINE)
if not m:
    print("[ERR] Impossible de localiser --summary-csv dans plot_fig07_synthesis.py", file=sys.stderr)
    sys.exit(1)

indent = m.group(1)
alias_line = indent + "p.add_argument('--csv', dest='summary_csv', help='Alias de --summary-csv (CSV de synthèse)')\n"

# 2) insérer juste après la ligne --summary-csv
insert_pos = m.end()
s = s[:insert_pos] + "\n" + alias_line + s[insert_pos:]

p.write_text(s, encoding="utf-8")
print("[OK] Alias --csv inséré avec la bonne indentation.")
PY

echo "[TEST] --help de fig07"
python3 "$F" --help >/dev/null

echo "[RUN] fig07 rapide (si manifests présents)"
O="zz-out/chapter10"
M1="$O/fig03b_cov_A.manifest.json"
M2="$O/fig03b_cov_B.manifest.json"
if [[ -f "$M1" && -f "$M2" ]]; then
  python3 "$F" \
    --manifests "$M1" "$M2" \
    --labels "A(outer300,inner400)" "B(outer300,inner200)" \
    --out "$O/fig07_synthesis.png" \
    --csv "$O/fig07_summary.csv" \
    --dpi 140
  echo "[OK] fig07 regénérée."
else
  echo "[SKIP] Manifests absents, je ne regénère pas fig07."
fi

echo "[SMOKE] relance tools/ch10_smoke.sh"
if [[ -x tools/ch10_smoke.sh ]]; then
  bash tools/ch10_smoke.sh
else
  echo "[WARN] tools/ch10_smoke.sh introuvable."
fi

echo "[DONE]"
