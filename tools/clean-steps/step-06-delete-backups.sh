#!/usr/bin/env bash
# step-06-delete-backups.sh
set -euo pipefail
LOGDIR=".tmp-cleanup-logs"; mkdir -p "$LOGDIR"
LOG="$LOGDIR/step-06-delete-backups.log"
exec > >(tee -a "$LOG") 2>&1

echo "START: step-06 $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
cd "$(git rev-parse --show-toplevel)"
APPLY="${APPLY:-0}"

shopt -s nullglob
to_delete=( *.bak* pyproject.toml.bak.* setup.py.bak.* setup.cfg.bak )
for f in "${to_delete[@]}"; do
  [[ -e "$f" ]] || continue
  if git ls-files --error-unmatch -- "$f" >/dev/null 2>&1; then
    echo "TRACKED -> skip: $f"
    continue
  fi
  if [[ "$APPLY" != "1" ]]; then
    echo "DRY-RUN would remove: $f"
  else
    echo "Removing: $f"
    rm -f -- "$f"
  fi
done
shopt -u nullglob

echo "END: step-06"
_on_exit(){
  if [[ "${NONINTERACTIVE:-0}" != "1" ]]; then
    printf "\n== step-06 finished (log: %s) ==\nPress Enter to close... " "$LOG"
    read -r _
  fi
}
trap _on_exit EXIT
