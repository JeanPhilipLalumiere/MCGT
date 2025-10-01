#!/usr/bin/env bash
# Injecte un header d'instrumentation au début d'un script (backup .bak)
set -euo pipefail

usage(){
  cat <<EOF
Usage: $0 <script1> [script2...]
Injecte un header d'instrumentation au début des scripts (créé backup .bak).
EOF
}

if [ $# -lt 1 ]; then usage; exit 2; fi

header='#!/usr/bin/env bash
set -uo pipefail
STAMP="$(date +%Y%m%dT%H%M%S)"
mkdir -p .ci-logs
LOG=".ci-logs/$(basename "$0" .sh)-${STAMP}.log"
# redirect stdout/stderr unbuffered to tee
exec > >(stdbuf -oL -eL tee -a "$LOG") 2>&1

ts(){ date +"[%F %T]"; }
say(){ printf "%s %s\\n" "$(ts)" "$*"; }
# heartbeat: print alive every 30s in background
__cat_header_heartbeat(){
  while true; do
    sleep 30
    say "HEARTBEAT: running $(basename "$0")"
  done
}
# start heartbeat in background; store pid for cleanup
__cat_header_start_hb(){
  __cat_header_heartbeat & __CAT_HB_PID=$!
  trap '__cat_header_cleanup' INT TERM EXIT
}
__cat_header_cleanup(){
  say "CLEANUP: stopping heartbeat and exiting"
  if [ -n "${__CAT_HB_PID:-}" ]; then kill "${__CAT_HB_PID}" 2>/dev/null || true; fi
  trap - INT TERM EXIT
}
# minimal checks
say "START script $(basename "$0")"
say "Etape: vérification gh auth"
command -v gh >/dev/null 2>&1 && gh auth status || say "WARN: gh not authenticated or not installed"
say "Etape: git fetch"
git fetch --all --prune || say "WARN: git fetch failed"
# start heartbeat
__cat_header_start_hb
'

for f in "$@"; do
  if [ ! -f "$f" ]; then
    echo "WARN: $f not found, skip"
    continue
  fi
  echo "Processing $f"
  bak="${f}.bak.$(date +%Y%m%dT%H%M%S)"
  cp -p "$f" "$bak"
  echo " - backup -> $bak"

  # read first line: if shebang, keep it and insert header after
  firstline="$(head -n1 "$f" || true)"
  if [[ "$firstline" =~ ^#! ]]; then
    printf "%s\n" "$firstline" > "${f}.tmp"
    # write header without repeating shebang (header starts with #!/usr/bin/env bash), so strip its shebang
    echo "$header" | sed '1s/^#!.*$/# inserted header/' >> "${f}.tmp"
    tail -n +2 "$f" >> "${f}.tmp"
  else
    echo "$header" > "${f}.tmp"
    cat "$f" >> "${f}.tmp"
  fi

  mv "${f}.tmp" "$f"
  chmod +x "$f"
  echo " - injected header into $f (backup saved)"
done
