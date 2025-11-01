#!/usr/bin/env bash
set -Eeuo pipefail
shopt -s nullglob

# 1) Localise le dernier rapport de smoke --help
REPORT="$(ls -1 _tmp/smoke_help_*/report.tsv 2>/dev/null | tail -n1 || true)"
LOG="$(dirname "$REPORT")/run.log"
if [[ -z "${REPORT:-}" || ! -f "$REPORT" || ! -f "$LOG" ]]; then
  echo "[ERR] Aucun rapport trouvé. Lance d'abord: bash tools/smoke_help_repo.sh" >&2
  exit 1
fi

echo "== INPUTS =="; echo "REPORT: $REPORT"; echo "LOG:    $LOG"; echo

# 2) Liste des FAIL
mapfile -t FAILS < <(awk '$1=="FAIL"{print $2}' "$REPORT")
fail_n=${#FAILS[@]}
echo "FAIL count: $fail_n"
printf '%s\n' "${FAILS[@]}" | nl -ba
echo

# 3) Pour chaque FAIL: extrait le bloc de log et synthétise l'exception
tmpdir="$(mktemp -d)"
SUMMARY="$tmpdir/fail_summary.tsv"
: > "$SUMMARY"
echo -e "file\texception\tmessage\tfirst_frame" >> "$SUMMARY"

for f in "${FAILS[@]}"; do
  # bornes du bloc correspondant dans le log
  start_line=$(grep -n -F "TEST --help: $f" "$LOG" | tail -n1 | cut -d: -f1)
  next_line=$(awk -v s="$start_line" 'NR>s && /TEST --help:/ {print NR; exit}' "$LOG")
  [[ -z "$next_line" ]] && next_line=$(wc -l < "$LOG")
  sed -n "${start_line},${next_line}p" "$LOG" > "$tmpdir/blk.log"

  # heuristique d'extraction (dernière ligne "Error"/"Exception")
  ex_line=$(grep -E '([A-Za-z]+Error|Exception):' "$tmpdir/blk.log" | tail -n1)
  ex_type=$(echo "$ex_line" | sed -E 's/^.* ([A-Za-z_]+Error|Exception):.*$/\1/')
  ex_msg=$(echo "$ex_line" | sed -E 's/^.* (?:[A-Za-z_]+Error|Exception):[ ]?(.*)$/\1/')
  first_frame=$(grep -E 'File ".*\.py", line [0-9]+' "$tmpdir/blk.log" | head -n1 | sed -E 's/^[[:space:]]*//')

  echo -e "${f}\t${ex_type:-NA}\t${ex_msg:-NA}\t${first_frame:-NA}" >> "$SUMMARY"

  # 4) Scan d’anti-patterns rapides (lecture seule)
  echo "---- ${f}"
  rg -n 'add_argument\([^)]*type\s*=\s*"[a-z]+"\)' "$f" || true
  rg -n 'print_help\([^)]*\)\s*%\s*' "$f" || true
  rg -n 'open\([^)]*\)' "$f" | head -n3 || true
  rg -n 'pd\.read_|np\.load|json\.load|yaml\.safe_load' "$f" | head -n3 || true
  rg -n 'if __name__ == .__main__.' "$f" || true
  echo
done

# 5) Agrégats par exception
echo "== SUMMARY by exception =="
cut -f2 "$SUMMARY" | sort | uniq -c | sort -nr

echo
echo "== Top 13 (détail condensé) =="
column -ts $'\t' "$SUMMARY"
echo
echo "[OK] Rapport synthèse: $SUMMARY"
