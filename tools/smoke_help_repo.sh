#!/usr/bin/env bash
set -Eeuo pipefail
shopt -s nullglob

TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUTDIR="_tmp/smoke_help_${TS}"
mkdir -p "$OUTDIR"
REPORT="$OUTDIR/report.tsv"
LOG="$OUTDIR/run.log"
: >"$REPORT"; : >"$LOG"

say(){ echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*" | tee -a "$LOG"; }

mapfile -t FILES < <(git ls-files 'zz-scripts/chapter??/plot_*.py' | sort)

ok=0; fail=0
set +e  # on n'abat pas la session si un --help échoue
for f in "${FILES[@]}"; do
  say "TEST --help: $f"
  python "$f" --help >/dev/null 2>>"$LOG"
  if [[ $? -eq 0 ]]; then
    printf "OK\t%s\n" "$f" >>"$REPORT"; ((ok++))
  else
    printf "FAIL\t%s\n" "$f" >>"$REPORT"; ((fail++))
  fi
done
set -e

printf "TOTAL\t%d\nOK\t%d\nFAIL\t%d\n" "${#FILES[@]}" "$ok" "$fail" | tee -a "$LOG"
echo "Rapport TSV : $REPORT"
echo "Log complet : $LOG"
