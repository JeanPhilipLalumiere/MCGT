#!/usr/bin/env bash
# step-09-clean-dists.sh
set -euo pipefail
LOGDIR=".tmp-cleanup-logs"; mkdir -p "$LOGDIR"
LOG="$LOGDIR/step-09-clean-dists.log"
exec > >(tee -a "$LOG") 2>&1

echo "START: step-09 $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
cd "$(git rev-parse --show-toplevel)"
APPLY="${APPLY:-0}"

targets=( "dist" "dist_from_ci" "dist_from_ci_all" "dist_from_testonly_*" "dist_from_retry_*" "dist_from_*" )

shopt -s nullglob
for pat in "${targets[@]}"; do
  for p in $pat; do
    [[ -e "$p" ]] || continue
    echo "Candidate: $p"
    du -sh "$p" || true
    if git ls-files --error-unmatch -- "$p" >/dev/null 2>&1; then
      echo "tracked: git rm -n $p"
      [[ "$APPLY" == "1" ]] && git rm -r -- "$p"
    else
      echo "untracked: rm -rf $p"
      [[ "$APPLY" == "1" ]] && rm -rf -- "$p"
    fi
  done
done
shopt -u nullglob

echo "END: step-09"
_on_exit(){
  if [[ "${NONINTERACTIVE:-0}" != "1" ]]; then
    printf "\n== step-09 finished (log: %s) ==\nPress Enter to close... " "$LOG"
    read -r _
  fi
}
trap _on_exit EXIT
