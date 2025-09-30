#!/usr/bin/env bash
# step-07-git-rm-ci-scripts.sh
set -euo pipefail
LOGDIR=".tmp-cleanup-logs"; mkdir -p "$LOGDIR"
LOG="$LOGDIR/step-07-git-rm-ci-scripts.log"
exec > >(tee -a "$LOG") 2>&1

echo "START: step-07 $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
cd "$(git rev-parse --show-toplevel)"
APPLY="${APPLY:-0}"

patterns=( "run_publish_testonly*.sh" "create_testpypi_workflow_and_run*.sh" "progressive_publish_testonly*.sh" "repair_publish_testonly_yaml.sh" "rebuild_publish_testonly_from_template.sh" )

for pat in "${patterns[@]}"; do
  echo "Pattern: $pat"
  shopt -s nullglob
  for f in $pat; do
    [[ -e "$f" ]] || continue
    if git ls-files --error-unmatch -- "$f" >/dev/null 2>&1; then
      if [[ "$APPLY" != "1" ]]; then
        echo "DRY git rm -n $f"
        git rm -n -- "$f" || true
      else
        echo "git rm $f"
        git rm -- "$f"
      fi
    else
      if [[ "$APPLY" != "1" ]]; then
        echo "DRY rm -f $f (untracked)"
      else
        echo "rm -f $f"
        rm -f -- "$f"
      fi
    fi
  done
  shopt -u nullglob
done

echo "END: step-07"
_on_exit(){
  if [[ "${NONINTERACTIVE:-0}" != "1" ]]; then
    printf "\n== step-07 finished (log: %s) ==\nPress Enter to close... " "$LOG"
    read -r _
  fi
}
trap _on_exit EXIT
