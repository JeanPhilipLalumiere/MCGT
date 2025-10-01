#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <script1> [script2...]" ; exit 2
fi

header='#!/usr/bin/env bash
set -uo pipefail
STAMP="$(date +%Y%m%dT%H%M%S)"
mkdir -p .ci-logs
LOG=".ci-logs/$(basename "$0" .sh)-${STAMP}.log"
exec > >(stdbuf -oL -eL tee -a "$LOG") 2>&1

ts(){ date +"[%F %T]"; }
say(){ printf "%s %s\n" "$(ts)" "$*"; }
__cat_header_heartbeat(){ while true; do sleep 30; say "HEARTBEAT: running $(basename \"$0\")"; done }
__cat_header_start_hb(){ __cat_header_heartbeat & __CAT_HB_PID=$! ; trap '__cat_header_cleanup' INT TERM EXIT; }
__cat_header_cleanup(){ say "CLEANUP"; kill ${__CAT_HB_PID:-0} 2>/dev/null || true; trap - INT TERM EXIT; }
say "START $(basename \"$0\")"
__cat_header_start_hb
'

for f in "$@"; do
  if [ ! -f "$f" ]; then echo "skip $f (not found)"; continue; fi
  bak="${f}.bak.$(date +%Y%m%dT%H%M%S)"
  cp -p "$f" "$bak"
  echo "backup -> $bak"
  first="$(head -n1 "$f" || true)"
  if [[ "$first" =~ ^#! ]]; then
    printf "%s\n" "$first" > "$f.tmp"
    echo "$header" | sed '1s/^#!.*$/# inserted header/' >> "$f.tmp"
    tail -n +2 "$f" >> "$f.tmp"
  else
    echo "$header" > "$f.tmp"
    cat "$f" >> "$f.tmp"
  fi
  mv "$f.tmp" "$f"
  chmod +x "$f"
  echo "$f injected"
done
