#!/usr/bin/env bash
# step-10-inode-cleaner.sh
set -euo pipefail
LOGDIR=".tmp-cleanup-logs"; mkdir -p "$LOGDIR"
LOG="$LOGDIR/step-10-inode-cleaner.log"
exec > >(tee -a "$LOG") 2>&1

echo "START: step-10 $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
cd "$(git rev-parse --show-toplevel)"
APPLY="${APPLY:-0}"

find . -maxdepth 2 -print0 | while IFS= read -r -d '' p; do
  name="$(basename "$p")"
  # detect non-printable or very long (>200)
  if printf '%s' "$name" | LC_ALL=C grep -q '[^ -~]' 2>/dev/null || (( ${#p} > 200 )); then
    echo "PROBLEMATIC: $p"
    if [[ "$APPLY" == "1" ]]; then
      inode=$(ls -id "$p" 2>/dev/null | awk '{print $1}' || true)
      if [[ -n "$inode" ]]; then
        echo "Removing by inode $inode..."
        find . -inum "$inode" -exec rm -rf -- {} \;
      else
        echo "Trying Python rmtree fallback for $p"
        python - <<PY || echo "Python fallback failed for $p"
import shutil, os
p = os.path.abspath("$p")
if os.path.exists(p):
    shutil.rmtree(p, ignore_errors=True)
    print("Python removed", p)
PY
      fi
    else
      echo "DRY-RUN would remove $p"
    fi
  fi
done

echo "END: step-10"
_on_exit(){
  if [[ "${NONINTERACTIVE:-0}" != "1" ]]; then
    printf "\n== step-10 finished (log: %s) ==\nPress Enter to close... " "$LOG"
    read -r _
  fi
}
trap _on_exit EXIT
