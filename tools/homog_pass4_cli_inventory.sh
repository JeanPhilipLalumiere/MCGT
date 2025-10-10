#!/usr/bin/env bash
set -euo pipefail

echo "[HOMOG-PASS4] Inventaire CLI: argparse/main-guard/--help/savefig/show"

SROOT="zz-scripts"
REPORT_DIR="zz-out"
REPORT_TXT="$REPORT_DIR/homog_cli_inventory_pass4.txt"
REPORT_CSV="$REPORT_DIR/homog_cli_inventory_pass4.csv"
FAIL_LIST="$REPORT_DIR/homog_cli_fail_list.txt"
mkdir -p "$REPORT_DIR"

# Collecte des fichiers Python 01..10
mapfile -t FILES < <(find "$SROOT"/chapter0{1..9} "$SROOT"/chapter10 -type f -name "*.py" | sort)

# Entêtes
echo "# CLI inventory (pass4) $(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "$REPORT_TXT"
echo "file,has_argparse,has_parse_args,has_main_guard,has_savefig,has_show,help_status,help_detail" > "$REPORT_CSV"
: > "$FAIL_LIST"

ok=0; fail=0
tmpd="$(mktemp -d)"
trap 'rm -rf "$tmpd"' EXIT

for f in "${FILES[@]}"; do
  rel="$f"

  # Lire le fichier et masquer les commentaires de ligne
  # (on garde les docstrings; c'est suffisant pour les heuristiques)
  content="$(sed 's/^[[:space:]]*#.*$//' "$f")"

  has_argparse="no"
  has_parse_args="no"
  has_main_guard="no"
  has_savefig="no"
  has_show="no"

  grep -qE '\bimport[[:space:]]+argparse\b' <<<"$content" && has_argparse="yes"
  grep -qE '\.parse_args\('               <<<"$content" && has_parse_args="yes"
  grep -qE 'if[[:space:]]+__name__\s*==\s*["'"'"']__main__["'"'"']\s*:' <<<"$content" && has_main_guard="yes"
  grep -qE '\.savefig\('                  <<<"$content" && has_savefig="yes"
  # show() est considéré "présent" s'il apparaît hors commentaires
  grep -qE '(^|[^#])\bshow\('            <<<"$(grep -n . "$f")" && has_show="yes"

  # Test --help avec timeout et backend neutre
  help_status="OK"
  help_detail="-"
  OUT="$tmpd/out.txt"; ERR="$tmpd/err.txt"
  set +e
  MPLBACKEND=Agg PYTHONWARNINGS=ignore timeout 8s python3 "$f" --help >"$OUT" 2>"$ERR"
  rc=$?
  set -e

  if [[ $rc -ne 0 ]]; then
    help_status="FAIL"
    # Prend la 1ère ligne d'erreur utile
    if [[ -s "$ERR" ]]; then
      help_detail="$(head -n1 "$ERR")"
    else
      help_detail="exit $rc (no stderr)"
    fi
    echo "$rel" >> "$FAIL_LIST"
    ((fail++)) || true
  else
    ((ok++)) || true
  fi

  # Sanitize CSV: remplace les virgules et newlines dans detail
  help_detail="$(echo "$help_detail" | tr '\n' ' ' | sed 's/,/;/g')"

  echo "$rel | argparse:$has_argparse | parse_args:$has_parse_args | main_guard:$has_main_guard | savefig:$has_savefig | show:$has_show | help:$help_status" \
    | tee -a "$REPORT_TXT" >/dev/null
  echo "$rel,$has_argparse,$has_parse_args,$has_main_guard,$has_savefig,$has_show,$help_status,$help_detail" >> "$REPORT_CSV"
done

echo "" | tee -a "$REPORT_TXT" >/dev/null
echo "[SUMMARY] --help OK: $ok, FAIL: $fail" | tee -a "$REPORT_TXT" >/dev/null
[[ -s "$FAIL_LIST" ]] && echo "[LIST] Fichiers en échec: $FAIL_LIST" | tee -a "$REPORT_TXT" >/dev/null || true
