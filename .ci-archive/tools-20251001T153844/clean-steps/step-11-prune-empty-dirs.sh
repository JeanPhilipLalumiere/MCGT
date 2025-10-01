#!/usr/bin/env bash
# step-11-prune-empty-dirs.sh
set -euo pipefail
LOGDIR=".tmp-cleanup-logs"; mkdir -p "$LOGDIR"
LOG="$LOGDIR/step-11-prune-empty-dirs.log"
exec > >(tee -a "$LOG") 2>&1

echo "START: step-11 $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
cd "$(git rev-parse --show-toplevel)"

find . -type d -empty -not -path './.git*' -not -path '.' -print > step-11-empty-dirs.txt
echo "Empty directories listed in step-11-empty-dirs.txt"
if [[ "${APPLY:-0}" == "1" ]]; then
  cat step-11-empty-dirs.txt | xargs -r -d '\n' rmdir -v || true
else
  echo "Dry-run: to remove, run APPLY=1 $0"
fi

echo "END: step-11"
_on_exit(){
  if [[ "${NONINTERACTIVE:-0}" != "1" ]]; then
    printf "\n== step-11 finished (log: %s, list: step-11-empty-dirs.txt) ==\nPress Enter to close... " "$LOG"
    read -r _
  fi
}
trap _on_exit EXIT
