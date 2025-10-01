#!/usr/bin/env bash
# step-05-delete-dist_from.sh
set -euo pipefail
LOGDIR=".tmp-cleanup-logs"; mkdir -p "$LOGDIR"
LOG="$LOGDIR/step-05-delete-dist_from.log"
exec > >(tee -a "$LOG") 2>&1

echo "START: step-05 $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
cd "$(git rev-parse --show-toplevel)"

APPLY="${APPLY:-0}"
mapfile -t cand < <(find . -maxdepth 2 -type d -name 'dist_from*' -print || true)

if [[ ${#cand[@]} -eq 0 ]]; then
  echo "No dist_from* found"
else
  for p in "${cand[@]}"; do
    echo "=== Candidate: $p ==="
    ls -lb "$p" 2>/dev/null || true
    du -sh "$p" || true
    if [[ "$APPLY" != "1" ]]; then
      echo "DRY-RUN would remove: $p"
      continue
    fi

    if rm -rf -- "$p" 2>/dev/null; then
      echo "Removed $p"
      continue
    fi

    echo "Normal rm failed: trying inode-based remove..."
    inode=$(ls -id "$p" 2>/dev/null | awk '{print $1}' || true)
    if [[ -n "$inode" ]]; then
      find . -inum "$inode" -exec rm -rf -- {} \; && echo "Removed by inode $inode" && continue
    fi

    echo "Trying Python fallback..."
    python - <<PY || echo "Python fallback failed for $p"
import shutil, sys, os
p = os.path.abspath("$p")
if os.path.exists(p):
    shutil.rmtree(p)
    print("Python removed", p)
PY
  done
fi

echo "END: step-05"
_on_exit(){
  if [[ "${NONINTERACTIVE:-0}" != "1" ]]; then
    printf "\n== step-05 finished (log: %s) ==\nPress Enter to close... " "$LOG"
    read -r _
  fi
}
trap _on_exit EXIT
