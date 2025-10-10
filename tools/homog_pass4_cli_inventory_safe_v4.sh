#!/usr/bin/env bash
set -euo pipefail

echo "[HOMOG-PASS4-SAFE v4] Inventaire CLI (--help) parallèle, timeout, Agg"

SROOT="zz-scripts"
REPORT_DIR="zz-out"
REPORT_TXT="$REPORT_DIR/homog_cli_inventory_pass4.txt"
REPORT_CSV="$REPORT_DIR/homog_cli_inventory_pass4.csv"
FAIL_LIST="$REPORT_DIR/homog_cli_fail_list.txt"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT
mkdir -p "$REPORT_DIR"

# Collecte des fichiers Python chapitres 01..10
mapfile -t FILES < <(find "$SROOT"/chapter0{1..9} "$SROOT"/chapter10 -type f -name "*.py" | sort)

# En-têtes
echo "# CLI inventory (pass4-safe v4) $(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "$REPORT_TXT"
echo "file,has_argparse,has_parse_args,has_main_guard,has_savefig,has_show,help_status,help_detail" > "$REPORT_CSV"
: > "$FAIL_LIST"

# Supprimer uniquement les lignes entièrement commentées
strip_line_comments () { sed -E 's/^[[:space:]]+#.*$//'; }

# Fonction unitaire pour un fichier (appelée via xargs)
scan_one () {
  local f="$1"
  local rel="$f"
  local outf errf
  outf="$(mktemp -p "$TMPDIR")"
  errf="$(mktemp -p "$TMPDIR")"

  # Détection statique (hors lignes entièrement commentées)
  local content
  content="$(strip_line_comments < "$f")"
  local has_argparse="no" has_parse_args="no" has_main_guard="no" has_savefig="no" has_show="no"

  grep -F -q "argparse" <<<"$content" && has_argparse="yes" || true
  grep -F -q ".parse_args(" <<<"$content" && has_parse_args="yes" || true
  grep -E -q "__name__\s*==\s*['\"]__main__['\"]" <<<"$content" && has_main_guard="yes" || true
  grep -F -q ".savefig(" <<<"$content" && has_savefig="yes" || true
  grep -F -q ".show(" <<<"$content" && has_show="yes" || true

  local help_status="FAIL" help_detail=""

  # Exécution --help isolée (timeout 8s, env minimal, backend Agg)
  if timeout 8s env -i PATH="$PATH" HOME="$HOME" PYTHONPATH="." \
      MPLBACKEND="Agg" PYTHONWARNINGS="ignore" LC_ALL=C.UTF-8 \
      python3 "$f" --help >"$outf" 2>"$errf"; then
    :
  fi

  if grep -qiE '^\s*usage:|--help' "$outf" || grep -qiE '^\s*usage:|--help' "$errf"; then
    help_status="OK"
  else
    help_status="FAIL"
    help_detail="$(head -n 2 "$errf" | tr '\n' ' ' | sed 's/,/;/g')"
    echo "$rel" >> "$FAIL_LIST"
  fi

  printf "%s | argparse:%s | parse_args:%s | main_guard:%s | savefig:%s | show:%s | help:%s\n" \
    "$rel" "$has_argparse" "$has_parse_args" "$has_main_guard" "$has_savefig" "$has_show" "$help_status" \
    >> "$REPORT_TXT"

  echo "$rel,$has_argparse,$has_parse_args,$has_main_guard,$has_savefig,$has_show,$help_status,${help_detail}" \
    >> "$REPORT_CSV"

  rm -f "$outf" "$errf"
}

export -f strip_line_comments scan_one
export REPORT_TXT REPORT_CSV FAIL_LIST TMPDIR

# Paralléliser (N = nb de CPU logiques; fallback 4)
N="$( (command -v nproc >/dev/null && nproc) || getconf _NPROCESSORS_ONLN || echo 4 )"
[[ "$N" =~ ^[0-9]+$ ]] || N=4
(( N < 2 )) && N=2

printf "%s\0" "${FILES[@]}" | xargs -0 -n1 -P "$N" bash -lc 'scan_one "$0"'

OK=$(awk -F, 'NR>1 && $7=="OK"{c++} END{print c+0}' "$REPORT_CSV")
FAIL=$(awk -F, 'NR>1 && $7=="FAIL"{c++} END{print c+0}' "$REPORT_CSV")

{
  echo
  echo "[SUMMARY] --help OK: $OK, FAIL: $FAIL"
  echo "[LIST] Fichiers en échec: $FAIL_LIST"
} >> "$REPORT_TXT"

echo "[DONE] Scan écrit:"
echo " - $REPORT_TXT"
echo " - $REPORT_CSV"
echo " - $FAIL_LIST"
