#!/usr/bin/env bash
# Exécute un script avec header d'instrumentation (ne modifie pas l'original)
# Usage: tools/run_with_instrumentation.sh [timeout-secs] <script> [args...]
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 [timeout-secs] <script> [args...]"; exit 2
fi

re='^[0-9]+$'
if [[ "$1" =~ $re ]]; then
  TIMEOUT="$1"; shift
else
  TIMEOUT=900
fi

SCRIPT="$1"; shift || true
if [ ! -f "$SCRIPT" ]; then
  echo "ERR: script '$SCRIPT' not found"; exit 2
fi

mkdir -p .ci-logs
STAMP="$(date +%Y%m%dT%H%M%S)"
LOG=".ci-logs/$(basename "$SCRIPT" .sh)-$STAMP.log"

# create wrapper (temp file)
WRAP="/tmp/__cat_wrapper_${STAMP}.sh"
cat > "$WRAP" <<'WRAP_EOF'
#!/usr/bin/env bash
set -euo pipefail

mkdir -p .ci-logs
STAMP_WRAPPER="$(date +%Y%m%dT%H%M%S)"
LOG_WRAPPER=".ci-logs/$(basename "$1" .sh)-${STAMP_WRAPPER}.log"

# redirect stdout/stderr unbuffered to tee
exec > >(stdbuf -oL -eL tee -a "$LOG_WRAPPER") 2>&1

ts(){ date +"[%F %T]"; }
say(){ printf "%s %s\n" "$(ts)" "$*"; }

__hb(){
  while true; do
    sleep 30
    say "HEARTBEAT: running $1"
  done
}

say "START wrapper for $1"
say "Etape: verification gh auth (if available)"
command -v gh >/dev/null 2>&1 && gh auth status || say "WARN: gh not authenticated or not installed"
say "Etape: git fetch --prune (best-effort)"
git fetch --all --prune || say "WARN: git fetch failed"

# start heartbeat
__hb "$1" & HB_PID=$!
trap 'say "CLEANUP wrapper"; kill ${HB_PID:-0} 2>/dev/null || true; exit' INT TERM EXIT

# exec the target script (pass all args)
exec bash -x "$@"
WRAP_EOF

chmod +x "$WRAP"

# Run the wrapper under timeout; tee appended also to a simpler log name for discoverability
echo "Launching wrapper -> log: $LOG"
timeout --preserve-status "$TIMEOUT" bash "$WRAP" "$SCRIPT" "$@" 2>&1 | stdbuf -oL -eL tee -a "$LOG"
rc=${PIPESTATUS[0]:-0}

rm -f "$WRAP"
if [ "$rc" -eq 124 ]; then
  echo "[$(date +'%F %T')] TIMEOUT after ${TIMEOUT}s. Log: $LOG"
else
  echo "[$(date +'%F %T')] script exit code $rc. Log: $LOG"
fi
exit $rc
