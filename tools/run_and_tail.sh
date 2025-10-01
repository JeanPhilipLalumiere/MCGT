#!/usr/bin/env bash
# usage: tools/run_and_tail.sh [timeout-secs] <script> [args...]
set -euo pipefail

if [ $# -lt 1 ]; then echo "Usage: $0 [timeout] <script> [args]"; exit 2; fi

re='^[0-9]+$'
if [[ "$1" =~ $re ]]; then TIMEOUT="$1"; shift; else TIMEOUT=900; fi
SCRIPT="$1"; shift || true
if [ ! -f "$SCRIPT" ]; then echo "ERR: script not found: $SCRIPT"; exit 2; fi

# Launch instrumented run in background
tools/run_with_instrumentation.sh "$TIMEOUT" "$SCRIPT" "$@" &
WRPID=$!

# Wait briefly for a log file to appear, then tail it
sleep 0.8
LOG="$(ls -1t .ci-logs/$(basename "$SCRIPT" .sh)-*.log 2>/dev/null | head -n1 || true)"
for i in $(seq 1 10); do
  if [ -n "$LOG" ]; then break; fi
  sleep 0.4
  LOG="$(ls -1t .ci-logs/$(basename "$SCRIPT" .sh)-*.log 2>/dev/null | head -n1 || true)"
done

if [ -n "$LOG" ]; then
  echo "Tailing log: $LOG (Ctrl-C to stop tail; script keeps running in background if still active)"
  tail -n +1 -f "$LOG" &
  TAILPID=$!
  wait "$WRPID" || true
  sleep 0.5
  kill "$TAILPID" 2>/dev/null || true
else
  echo "Aucun log detecte; attendez ou verifiez .ci-logs/"
  wait "$WRPID" || true
fi
