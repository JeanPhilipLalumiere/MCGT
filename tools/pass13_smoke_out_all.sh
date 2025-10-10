#!/usr/bin/env bash
set -euo pipefail

echo "[PASS13] Smoke headless (--out) sur tous les scripts + rapport"

SROOT="zz-scripts"
OUTDIR="zz-out/smoke"
REPDIR="zz-out"
CSV="$REPDIR/homog_smoke_pass13.csv"
LOG="$REPDIR/homog_smoke_pass13.log"
mkdir -p "$OUTDIR" "$REPDIR"
: > "$CSV"
: > "$LOG"

echo "file,status,reason,elapsed_sec,out_path,out_size" >> "$CSV"

export MPLBACKEND=Agg

run_one() {
  local f="$1"
  local rel="${f#${SROOT}/}"
  local outp="$OUTDIR/${rel%.py}.png"
  mkdir -p "$(dirname "$outp")"

  local t0 t1 dt
  t0=$(date +%s)
  # On redirige stderr pour analyse
  local tmp_err
  tmp_err="$(mktemp)"
  timeout 60s python3 "$f" --out "$outp" --dpi 96 > /dev/null 2> "$tmp_err"
  rc=$?
  t1=$(date +%s); dt=$((t1 - t0))

  if [[ $rc -eq 0 ]]; then
    local sz="0"
    [[ -s "$outp" ]] && sz=$(stat -c '%s' "$outp" 2>/dev/null || stat -f '%z' "$outp")
    echo "$f,OK,,${dt},$outp,$sz" >> "$CSV"
  else
    local err; err="$(tr -d '\r' < "$tmp_err" | tail -n 10)"
    local reason="FAIL_EXEC"
    grep -qiE 'the following arguments are required' <<<"$err" && reason="SKIP_REQUIRED_ARGS"
    grep -qiE 'unrecognized arguments|unrecognised arguments' <<<"$err" && reason="SKIP_UNKNOWN_ARGS"
    grep -qiE 'usage:|--help' <<<"$err" && reason="${reason};USAGE_HINT"

    echo "$f,$reason,$(echo "$err" | tr '\n' ' ' | sed 's/,/;/g'),${dt},$outp," >> "$CSV"
    {
      echo "----- $f (rc=$rc, ${dt}s) -----"
      echo "$err"
      echo
    } >> "$LOG"
  fi

  rm -f "$tmp_err"
}

export -f run_one
export SROOT OUTDIR CSV LOG

# Lister tous les .py des chapitres 01..10
find "$SROOT"/chapter0{1..9} "$SROOT"/chapter10 -type f -name "*.py" \
  | sort \
  | xargs -I{} -P"$(nproc)" bash -lc 'run_one "$@"' _ {}

echo "[PASS13] Rapport:"
echo " - $CSV"
echo " - $LOG"
# Résumé court
awk -F, 'NR>1 {c[$2]++} END{for (k in c) printf "[SUMMARY] %-20s %d\n", k, c[k];}' "$CSV" | sort
