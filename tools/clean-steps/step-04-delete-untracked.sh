#!/usr/bin/env bash
# step-04-delete-untracked.sh
set -euo pipefail
LOGDIR=".tmp-cleanup-logs"; mkdir -p "$LOGDIR"
LOG="$LOGDIR/step-04-delete-untracked.log"
exec > >(tee -a "$LOG") 2>&1

echo "START: step-04 $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
cd "$(git rev-parse --show-toplevel)"

targets=( ".ci_poke" ".pytest_cache" ".tmp-ci" ".tmp-gh-dist" ".tmp-*" )

APPLY="${APPLY:-0}"
shopt -s nullglob dotglob
for pat in "${targets[@]}"; do
  for p in $pat; do
    [[ -e "$p" ]] || continue
    if git ls-files --error-unmatch -- "$p" >/dev/null 2>&1; then
      echo "SKIP tracked: $p"
      continue
    fi
    if [[ "$APPLY" != "1" ]]; then
      echo "DRY-RUN would remove: $p ($(du -sh "$p" 2>/dev/null || echo 'size?'))"
    else
      echo "Removing untracked: $p"
      rm -rf -- "$p"
    fi
  done
done
shopt -u nullglob dotglob
echo "END: step-04"
_on_exit(){
  if [[ "${NONINTERACTIVE:-0}" != "1" ]]; then
    printf "\n== step-04 finished (log: %s) ==\nPress Enter to close... " "$LOG"
    read -r _
  fi
}
trap _on_exit EXIT
