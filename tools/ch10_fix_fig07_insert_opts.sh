#!/usr/bin/env bash
set -euo pipefail

F="zz-scripts/chapter10/plot_fig07_synthesis.py"

echo "[PATCH] fig07: insertion robuste de --summary-csv et de l'alias --csv"

python3 - <<'PY'
import re, sys, pathlib
p = pathlib.Path("zz-scripts/chapter10/plot_fig07_synthesis.py")
s = p.read_text(encoding="utf-8")

# 0) S'assurer que argparse est importé
if not re.search(r'^\s*import\s+argparse\b', s, flags=re.MULTILINE):
    # insérer après le shebang/docstring si besoin
    if s.startswith("#!"):
        first_nl = s.find("\n")
        s = s[:first_nl+1] + "import argparse\n" + s[first_nl+1:]
    else:
        s = "import argparse\n" + s

# 1) détecter le nom du parseur (p, ap, parser, etc.)
m_parser = re.search(r'^([ \t]*)(\w+)\s*=\s*argparse\.ArgumentParser\(', s, flags=re.MULTILINE)
parser_indent = ""
parser_var = "p"
if m_parser:
    parser_indent = m_parser.group(1)
    parser_var = m_parser.group(2)

# 2) retirer alias --csv existants mal posés (et toute ligne add_argument qui mappe dest=summary_csv en --csv)
s = re.sub(
    r'^[ \t]*' + re.escape(parser_var) + r'\.add_argument\(\s*[\'"]--csv[\'"].*?dest\s*=\s*[\'"]summary_csv[\'"].*?\)\s*\n',
    '',
    s,
    flags=re.MULTILINE,
)

# 3) si un add_argument avec dest='summary_csv' existe déjà, ne rien insérer
if re.search(r'\.add_argument\([^)]*dest\s*=\s*[\'"]summary_csv[\'"]', s):
    # rien à faire
    pass
else:
    # construire les deux lignes à insérer
    insert_lines = (
        f"{parser_indent}{parser_var}.add_argument('--summary-csv', dest='summary_csv', "
        f"help='CSV de synthèse des séries', default=None)\n"
        f"{parser_indent}{parser_var}.add_argument('--csv', dest='summary_csv', "
        f"help='Alias de --summary-csv (CSV de synthèse)')\n"
    )
    # 3a) préférence: insérer juste après la ligne --out si présente
    m_out = re.search(
        r'^([ \t]*' + re.escape(parser_var) + r'\.add_argument\([^)]*--out[^)]*\)\s*)$',
        s, flags=re.MULTILINE)
    if m_out:
        pos = m_out.end()
        s = s[:pos] + "\n" + insert_lines + s[pos:]
    else:
        # 3b) sinon, insérer juste après la création du parser
        if not m_parser:
            print("[WARN] Impossible de détecter la création du parser; insertion en tête du fichier.", file=sys.stderr)
            s = insert_lines + s
        else:
            pos = m_parser.end()
            # aller à la fin de la ligne création parser
            eol = s.find("\n", pos)
            if eol == -1: eol = pos
            s = s[:eol+1] + insert_lines + s[eol+1:]

p.write_text(s, encoding="utf-8")
print("[OK] --summary-csv + alias --csv (dest=summary_csv) insérés si nécessaires.")
PY

echo "[TEST] --help fig07"
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
