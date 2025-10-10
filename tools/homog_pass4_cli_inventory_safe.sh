#!/usr/bin/env bash
set -euo pipefail

echo "[HOMOG-PASS4-SAFE] Inventaire CLI (--help) avec timeout & détection par contenu (v2)"

SROOT="zz-scripts"
REPORT_DIR="zz-out"
REPORT_TXT="$REPORT_DIR/homog_cli_inventory_pass4.txt"
REPORT_CSV="$REPORT_DIR/homog_cli_inventory_pass4.csv"
FAIL_LIST="$REPORT_DIR/homog_cli_fail_list.txt"
mkdir -p "$REPORT_DIR"

# Collecte des fichiers Python 01..10
mapfile -t FILES < <(find "$SROOT"/chapter0{1..9} "$SROOT"/chapter10 -type f -name "*.py" | sort)

# En-têtes rapports
echo "# CLI inventory (pass4-safe v2) $(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "$REPORT_TXT"
echo "file,has_argparse,has_parse_args,has_main_guard,has_savefig,has_show,help_status,help_detail" > "$REPORT_CSV"
: > "$FAIL_LIST"

ok=0; fail=0

# Supprime UNIQUEMENT les lignes entièrement commentées (pas les commentaires inline)
strip_line_comments () {
  sed -E 's/^[[:space:]]+#.*$//'
}

for f in "${FILES[@]}"; do
  rel="$f"

  # Détection statique simple (hors lignes totalement commentées)
  content="$(cat "$f" | strip_line_comments)"

  has_argparse="no"; has_parse_args="no"; has_main_guard="no"; has_savefig="no"; has_show="no"
  echo "$content" | grep -F -q "argparse" && has_argparse="yes" || true
  echo "$content" | grep -F -q ".parse_args(" && has_parse_args="yes" || true
  echo "$content" | grep -E -q "__name__\s*==\s*['\"]__main__['\"]" && has_main_guard="yes" || true
  echo "$content" | grep -F -q ".savefig(" && has_savefig="yes" || true
  echo "$content" | grep -F -q ".show(" && has_show="yes" || true

  # Exécution --help isolée + timeout par fichier
  out_file="$(mktemp)"; err_file="$(mktemp)"
  help_status="FAIL"; help_detail=""

  if timeout 8s env -i PATH="$PATH" HOME="$HOME" PYTHONPATH="." \
      MPLBACKEND="Agg" PYTHONWARNINGS="ignore" LC_ALL=C.UTF-8 \
      python3 "$f" --help >"$out_file" 2>"$err_file"; then
    :
  fi

  if grep -qiE '^\s*usage:|--help' "$out_file" || grep -qiE '^\s*usage:|--help' "$err_file"; then
    help_status="OK"; ((ok++))
  else
    help_status="FAIL"
    help_detail="$(head -n 2 "$err_file" | tr '\n' ' ' | sed 's/,/;/g')"
    echo "$rel" >> "$FAIL_LIST"
    ((fail++))
  fi

  printf "%s | argparse:%s | parse_args:%s | main_guard:%s | savefig:%s | show:%s | help:%s\n" \
    "$rel" "$has_argparse" "$has_parse_args" "$has_main_guard" "$has_savefig" "$has_show" "$help_status" \
    | tee -a "$REPORT_TXT" >/dev/null

  echo "$rel,$has_argparse,$has_parse_args,$has_main_guard,$has_savefig,$has_show,$help_status,${help_detail}" \
    >> "$REPORT_CSV"

  rm -f "$out_file" "$err_file"
done

echo "" | tee -a "$REPORT_TXT" >/dev/null
echo "[SUMMARY] --help OK: $ok, FAIL: $fail" | tee -a "$REPORT_TXT"
echo "[LIST] Fichiers en échec: $FAIL_LIST" | tee -a "$REPORT_TXT"
