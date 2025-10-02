#!/usr/bin/env bash
# Usage: tools/run_with_timeout_and_tail.sh <timeout-seconds> <script> [args...]
set -uo pipefail
timeout_secs="${1:-600}" # valeur par défaut (ex.: 600s). Tu choisis.
shift || true
script="${1:-}"
shift || true
logdir=".ci-logs"
mkdir -p "$logdir"
stamp="$(date +%Y%m%dT%H%M%S)"
log="$logdir/$(basename "$script" .sh)_$stamp.log"

if [ -z "$script" ]; then
  echo "Usage: $0 <timeout-seconds> <script> [args...]"
  exit 2
fi

echo "[$(date +'%F %T')] running '$script' (timeout ${timeout_secs}s). Log -> $log"
# exécute en mode non-buffered, trace bash (-x), avec timeout GNU
# exit code 124 = timeout
stdbuf -oL -eL timeout --preserve-status "$timeout_secs" bash -x "$script" "$@" 2>&1 | stdbuf -oL -eL tee -a "$log" &
pid=$!

# tail while running
sleep 0.5
tail -n +1 -f "$log" &
tailpid=$!

wait $pid
ret=$?

# stop tail
kill $tailpid 2>/dev/null || true

if [ $ret -eq 124 ]; then
  echo "[$(date +'%F %T')] TIMEOUT: script exceeded ${timeout_secs}s (exit $ret)"
else
  echo "[$(date +'%F %T')] script exited with code $ret"
fi

echo "Log: $log"
exit $ret
