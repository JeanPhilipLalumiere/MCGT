#!/usr/bin/env bash
set -euo pipefail

echo "[HOMOG-PASS4-AST] Inventaire statique (AST) argparse/main-guard/savefig/show — sans exécution"

SROOT="zz-scripts"
REPORT_DIR="zz-out"
TXT="$REPORT_DIR/homog_cli_inventory_pass4.txt"
CSV="$REPORT_DIR/homog_cli_inventory_pass4.csv"
FAIL_LIST="$REPORT_DIR/homog_cli_fail_list.txt"
mkdir -p "$REPORT_DIR"

echo "# CLI inventory (pass4-ast) $(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "$TXT"
echo "file,has_argparse,has_parse_args,has_main_guard,has_savefig,has_show,help_status,help_detail" > "$CSV"
: > "$FAIL_LIST"

mapfile -t FILES < <(find "$SROOT"/chapter0{1..9} "$SROOT"/chapter10 -type f -name "*.py" | sort)

ok=0; fail=0
python3 - <<'PY'
import ast, sys, pathlib, csv

csv_path = pathlib.Path("zz-out/homog_cli_inventory_pass4.csv")
fail_path = pathlib.Path("zz-out/homog_cli_fail_list.txt")
txt_path = pathlib.Path("zz-out/homog_cli_inventory_pass4.txt")

ok=0; fail=0
with csv_path.open("a", newline="", encoding="utf-8") as cf, fail_path.open("w", encoding="utf-8") as lf, txt_path.open("a", encoding="utf-8") as tf:
    wr = csv.writer(cf)
    for line in sys.stdin:
        f = line.strip()
        if not f: continue
        p = pathlib.Path(f)
        try:
            src = p.read_text(encoding="utf-8")
        except Exception:
            wr.writerow([f,"no","no","no","no","no","FAIL","unreadable"])
            lf.write(f + "\n"); fail += 1
            continue
        try:
            tree = ast.parse(src, filename=f, mode="exec")
        except Exception as e:
            wr.writerow([f,"no","no","no","no","no","FAIL","syntax_error"])
            lf.write(f + "\n"); fail += 1
            continue

        has_argparse = any(isinstance(n, ast.Import) and any(m.name=="argparse" for m in n.names) for n in ast.walk(tree)) \
                       or any(isinstance(n, ast.ImportFrom) and n.module=="argparse" for n in ast.walk(tree))

        # parse_args calls
        has_parse_args = any(isinstance(n, ast.Call) and isinstance(n.func, ast.Attribute) and n.func.attr=="parse_args" for n in ast.walk(tree))

        # __main__ guard
        has_main_guard = False
        for n in ast.walk(tree):
            if isinstance(n, ast.If) and isinstance(n.test, ast.Compare):
                left = n.test.left
                comps = n.test.comparators
                if isinstance(left, ast.Name) and left.id=="__name__" and comps and isinstance(comps[0], ast.Constant) and comps[0].value=="__main__":
                    has_main_guard = True
                    break

        # savefig/show (search as attribute names)
        has_savefig = any(isinstance(n, ast.Attribute) and n.attr=="savefig" for n in ast.walk(tree))
        has_show = any(isinstance(n, ast.Attribute) and n.attr=="show" for n in ast.walk(tree))

        # On ne “lance” rien : help_status = STATIC
        help_status = "STATIC"
        help_detail = "ast-scan"

        wr.writerow([f, "yes" if has_argparse else "no",
                        "yes" if has_parse_args else "no",
                        "yes" if has_main_guard else "no",
                        "yes" if has_savefig else "no",
                        "yes" if has_show else "no",
                        help_status, help_detail])

        # On considère FAIL s'il manque argparse OU main_guard
        if not has_argparse or not has_main_guard:
            lf.write(f + "\n"); fail += 1
        else:
            ok += 1

    tf.write(f"[SUMMARY-AST] OK-ish (argparse+guard): {ok}, FAIL (à traiter): {fail}\n")
PY <<'PYFILES'
$(find zz-scripts/chapter0{1..9} zz-scripts/chapter10 -type f -name "*.py" | sort)
PYFILES

echo "[HOMOG-PASS4-AST] Terminé. Rapports :"
echo " - $TXT"
echo " - $CSV"
echo " - $FAIL_LIST"
