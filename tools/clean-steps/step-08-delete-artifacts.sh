#!/usr/bin/env bash
# step-08-delete-artifacts.sh
set -euo pipefail
LOGDIR=".tmp-cleanup-logs"; mkdir -p "$LOGDIR"
LOG="$LOGDIR/step-08-delete-artifacts.log"
exec > >(tee -a "$LOG") 2>&1

echo "START: step-08 $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
cd "$(git rev-parse --show-toplevel)"
APPLY="${APPLY:-0}"

shopt -s nullglob
for d in artifacts_*; do
  [[ -e "$d" ]] || continue
  echo "Found: $d"
  du -sh "$d" || true
  if git ls-files --error-unmatch -- "$d" >/dev/null 2>&1; then
    echo "tracked -> git rm -n $d"
    [[ "$APPLY" == "1" ]] && git rm -r -- "$d"
  else
    echo "untracked -> rm -rf $d"
    [[ "$APPLY" == "1" ]] && rm -rf -- "$d"
  fi
done
shopt -u nullglob

echo "END: step-08"
_on_exit(){
  if [[ "${NONINTERACTIVE:-0}" != "1" ]]; then
    printf "\n== step-08 finished (log: %s) ==\nPress Enter to close... " "$LOG"
    read -r _
  fi
}
trap _on_exit EXIT
