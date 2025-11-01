#!/usr/bin/env bash
set -Eeuo pipefail
shopt -s nullglob

# Localise dernier rapport
REPORT="$(ls -1 _tmp/smoke_help_*/report.tsv 2>/dev/null | tail -n1 || true)"
LOG="$(dirname "$REPORT")/run.log"
if [[ -z "${REPORT:-}" || ! -f "$REPORT" || ! -f "$LOG" ]]; then
  echo "[ERR] Aucun rapport trouvé. Lance d'abord: bash tools/smoke_help_repo.sh" >&2
  exit 1
fi

echo "== INPUTS =="; echo "REPORT: $REPORT"; echo "LOG:    $LOG"; echo

# Liste FAIL
mapfile -t FAILS < <(awk '$1=="FAIL"{print $2}' "$REPORT")
fail_n=${#FAILS[@]}
echo "FAIL count: $fail_n"
nl -ba <(printf "%s\n" "${FAILS[@]}") || true
echo

tmpdir="$(mktemp -d)"
SUMMARY="$tmpdir/fail_summary.tsv"
: > "$SUMMARY"
echo -e "file\texception\tmessage\tfirst_frame" >> "$SUMMARY"

for f in "${FAILS[@]}"; do
  # bornes du bloc log du fichier
  start_line="$(grep -n -F "TEST --help: $f" "$LOG" | tail -n1 | cut -d: -f1)"
  if [[ -z "$start_line" ]]; then
    echo -e "$f\tNA\tno-log-block\tNA" >> "$SUMMARY"
    continue
  fi
  next_line="$(awk -v s="$start_line" 'NR>s && /TEST --help:/ {print NR; exit}' "$LOG")"
  [[ -z "$next_line" ]] && next_line="$(wc -l < "$LOG")"
  sed -n "${start_line},${next_line}p" "$LOG" > "$tmpdir/blk.log"

  # extraction (dernière ligne d'erreur)
  ex_line="$(grep -E '([A-Za-z_]+Error|Exception):' "$tmpdir/blk.log" | tail -n1 || true)"
  ex_type="$(sed -E 's/^.* ([A-Za-z_]+Error|Exception):.*$/\1/' <<<"$ex_line" || true)"
  ex_msg="$(sed -E 's/^.* (?:[A-Za-z_]+Error|Exception):[ ]?(.*)$/\1/' <<<"$ex_line" || true)"
  first_frame="$(grep -E 'File ".*\.py", line [0-9]+' "$tmpdir/blk.log" | head -n1 | sed -E 's/^[[:space:]]*//' || true)"
  [[ -z "$ex_type" ]] && ex_type="NA"
  [[ -z "$ex_msg"  ]] && ex_msg="NA"
  [[ -z "$first_frame" ]] && first_frame="NA"
  echo -e "${f}\t${ex_type}\t${ex_msg}\t${first_frame}" >> "$SUMMARY"

  echo "---- $f"
  # Scans non intrusifs (indices de patch)
  rg -n 'add_argument\([^)]*type\s*=\s*"[a-z]+"\)'        "$f" || true
  rg -n 'add_argument\([^)]*choices\s*=\s*[^)\]]+\)'      "$f" | rg -v '\[[^]]+\]' || true
  rg -n 'print_help\([^)]*\)\s*%\s*'                      "$f" || true
  rg -n '(%\([A-Za-z0-9_]+\)[df])|((?<!%)%[0-9.+\- #]*[df])' "$f" || true
  rg -n 'pd\.read_|np\.load|json\.load|yaml\.safe_load'   "$f" | head -n3 || true
  rg -n '^\s*(with |open\()'                              "$f" | head -n3 || true
  rg -n 'if __name__ == .__main__.'                       "$f" || true
  echo
done

echo "== SUMMARY by exception =="
cut -f2 "$SUMMARY" | sort | uniq -c | sort -nr

echo
echo "== Detailed table =="
column -ts $'\t' "$SUMMARY"

echo
echo "[OK] Synthèse: $SUMMARY"
