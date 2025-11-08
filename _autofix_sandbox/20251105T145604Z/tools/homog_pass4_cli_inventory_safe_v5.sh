#!/usr/bin/env bash
set -euo pipefail

echo "[HOMOG-PASS4-SAFE v5] Inventaire CLI (--help) tolérant (usage-based), parallèle, Agg"

SROOT="zz-scripts"
REPORT_DIR="zz-out"
REPORT_TXT="$REPORT_DIR/homog_cli_inventory_pass4.txt"
REPORT_CSV="$REPORT_DIR/homog_cli_inventory_pass4.csv"
FAIL_LIST="$REPORT_DIR/homog_cli_fail_list.txt"
mkdir -p "$REPORT_DIR"

# Collecte des fichiers Python 01..10
mapfile -t FILES < <(find "$SROOT"/chapter0{1..9} "$SROOT"/chapter10 -type f -name "*.py" | sort)

# En-têtes
echo "# CLI inventory (pass4-safe v5) $(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "$REPORT_TXT"
echo "file,has_argparse,has_parse_args,has_main_guard,has_savefig,has_show,help_status,help_detail" > "$REPORT_CSV"
: > "$FAIL_LIST"

strip_line_comments () { sed -E 's/^[[:space:]]+#.*$//'; }

scan_one () {
  f="$1"; rel="$1"
  src="$(awk '{print} END{}' "$f" | strip_line_comments || true)"

  has_argparse="no";   [[ "$src" =~ (^|[^[:alnum:]_])import[[:space:]]+argparse ]] || [[ "$src" =~ argparse.ArgumentParser ]] && has_argparse="yes"
  has_parse_args="no"; [[ "$src" =~ \.parse_args\(\) ]] && has_parse_args="yes"
  has_main_guard="no"; grep -qE 'if[[:space:]]+__name__[[:space:]]*==[[:space:]]*[\"\x27]__main__[\"\x27]' "$f" && has_main_guard="yes"
  has_savefig="no";    grep -qE '[^#]savefig\(' "$f" && has_savefig="yes"
  has_show="no";       grep -qE '[^#]show\(' "$f"    && has_show="yes"

  # Exécuter --help sous Agg, timeout court
  out="$(timeout 6s env MPLBACKEND=Agg PYTHONWARNINGS=ignore python3 "$f" --help 2>&1 || true)"
  rc=$?

  # Heuristique “help OK” si le contenu ressemble à une aide, même si rc!=0
  if echo "$out" | grep -qiE 'usage:|optional arguments|show this help message|[-]h, --help'; then
    help_status="OK"; help_detail="help-shown"
  elif (( rc == 0 )); then
    help_status="OK"; help_detail="exit0"
  elif (( rc == 124 )); then
    help_status="FAIL"; help_detail="timeout"
  else
    help_status="FAIL"; help_detail="rc=$rc"
  fi

  printf "%s | argparse:%s | parse_args:%s | main_guard:%s | savefig:%s | show:%s | help:%s\n" \
    "$rel" "$has_argparse" "$has_parse_args" "$has_main_guard" "$has_savefig" "$has_show" "$help_status" >> "$REPORT_TXT"

  # CSV
  safe_detail="$(echo "$help_detail" | tr ',' ';')"
  echo "$rel,$has_argparse,$has_parse_args,$has_main_guard,$has_savefig,$has_show,$help_status,$safe_detail" >> "$REPORT_CSV"

  # FAIL list
  [[ "$help_status" == "FAIL" ]] && echo "$rel" >> "$FAIL_LIST" || true
}

export -f scan_one strip_line_comments
export REPORT_TXT REPORT_CSV FAIL_LIST

printf "%s\0" "${FILES[@]}" | xargs -0 -n1 -P"$(nproc)" bash -c 'scan_one "$@"' _

echo "[DONE] Scan écrit:"
echo " - $REPORT_TXT"
echo " - $REPORT_CSV"
echo " - $FAIL_LIST"

# Petit résumé
tail -n 10 "$REPORT_TXT" || true
echo
echo -n "[SUMMARY] --help OK: "
awk -F, 'NR>1 && $7=="OK"{ok++} END{print (ok+0) ", FAIL: " (NR>1?NR-1-ok:0)}' "$REPORT_CSV"
echo "[LIST] Fichiers en échec: $FAIL_LIST"
