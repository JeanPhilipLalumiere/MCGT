#!/usr/bin/env bash
set -euo pipefail

S="zz-scripts/chapter10"
F="$S/plot_fig07_synthesis.py"
SMOKE="tools/ch10_smoke.sh"

echo "[PATCH] fig07: ajout de l'alias --csv => --summary-csv (si absent)"

python3 - <<'PY'
import pathlib, re, sys
p = pathlib.Path("zz-scripts/chapter10/plot_fig07_synthesis.py")
s = p.read_text(encoding="utf-8")

# 1) Détecter si --csv (dest='summary_csv') existe déjà
if re.search(r"add_argument\([^)]*--csv[^)]*dest=['\"]summary_csv['\"]", s):
    print("[INFO] Alias --csv existe déjà.")
else:
    # 2) S'il y a déjà --summary-csv, insérer juste après
    m = re.search(r"add_argument\([^)]*--summary-csv[^)]*\)\s*", s)
    if m:
        insert_pos = m.end()
        alias = "    p.add_argument('--csv', dest='summary_csv', help='Alias de --summary-csv (CSV de synthèse)')\n"
        s = s[:insert_pos] + alias + s[insert_pos:]
        print("[OK] Ajout de l'alias --csv après --summary-csv.")
    else:
        # 3) Sinon, avant parse_args, ajouter les deux
        m2 = re.search(r"\.parse_args\(\)", s)
        if not m2:
            print("[WARN] Impossible de localiser parse_args(); insertion en fin de build_parser().")
        # Essayer de trouver la définition du parser build_parser()
        bp = re.search(r"def\s+build_parser\s*\([^)]*\)\s*->?\s*[^:]*:\s*(?:\n|\r\n)", s)
        if bp:
            # insérer à la fin de build_parser, avant return p (ou avant fin du bloc)
            # On cherche le premier 'return p' après bp
            ret = re.search(r"return\s+p", s[bp.end():])
            insert_pos = (bp.end() + ret.start()) if ret else bp.end()
            block = (
                "    p.add_argument('--summary-csv', dest='summary_csv', default=None,\n"
                "                   help='Chemin du CSV de synthèse à écrire')\n"
                "    p.add_argument('--csv', dest='summary_csv', help='Alias de --summary-csv (CSV de synthèse)')\n"
            )
            s = s[:insert_pos] + block + s[insert_pos:]
            print("[OK] Ajout de --summary-csv + alias --csv dans build_parser().")
        else:
            print("[ERR] build_parser() introuvable : patch manuel requis.")
            sys.exit(1)

p.write_text(s, encoding="utf-8")
PY

echo "[PATCH] smoke: remplacer --csv par --summary-csv"
if [[ -f "$SMOKE" ]]; then
  # remplace seulement les occurrences d'option '--csv ' liées à fig07
  perl -0777 -pe "s/(plot_fig07_synthesis\.py[^\n]*?)--csv\b/\1--summary-csv/g" -i "$SMOKE"
else
  echo "[WARN] $SMOKE introuvable, skip."
fi

echo "[TEST] fig07: --help"
python3 "$F" --help >/dev/null

echo "[RUN] fig07: génère une synthèse minimale depuis les 2 manifests existants"
O="zz-out/chapter10"
M1="$O/fig03b_cov_A.manifest.json"
M2="$O/fig03b_cov_B.manifest.json"
if [[ ! -f "$M1" || ! -f "$M2" ]]; then
  echo "[WARN] Manifests attendus non trouvés ($M1 / $M2). Je relance fig03b pour les produire..."
  python3 "$S/plot_fig03b_bootstrap_coverage_vs_n.py" --results "zz-data/chapter10/dummy_results.csv" --out "$O/fig03b_cov_A.png" --npoints 6 --outer 300 --inner 400 --seed 42
  python3 "$S/plot_fig03b_bootstrap_coverage_vs_n.py" --results "zz-data/chapter10/dummy_results.csv" --out "$O/fig03b_cov_B.png" --npoints 6 --outer 300 --inner 200 --seed 99
fi

python3 "$F" \
  --manifests "$M1" "$M2" \
  --labels "A(outer300,inner400)" "B(outer300,inner200)" \
  --out "$O/fig07_synthesis.png" \
  --summary-csv "$O/fig07_summary.csv" \
  --dpi 140

echo "[OK] fig07 synthèse régénérée."
echo "[SMOKE] relance tools/ch10_smoke.sh"
if [[ -x tools/ch10_smoke.sh ]]; then
  bash tools/ch10_smoke.sh
fi

echo "[DONE]"
