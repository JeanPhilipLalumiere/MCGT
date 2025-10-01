#!/usr/bin/env bash
# step-12-update-gitignore.sh
set -euo pipefail
LOGDIR=".tmp-cleanup-logs"; mkdir -p "$LOGDIR"
LOG="$LOGDIR/step-12-update-gitignore.log"
exec > >(tee -a "$LOG") 2>&1

echo "START: step-12 $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
cd "$(git rev-parse --show-toplevel)"
IGNOREFILE=".gitignore"
touch "$IGNOREFILE"
APPLY="${APPLY:-0}"

patterns=(
"/dist/"
"/dist_from_*"
"/artifacts_*"
"/.pytest_cache/"
"/.tmp-*/"
"/.tmp-ci/"
"/.tmp-gh-dist/"
"/.ci_poke/"
"/scripts/.bak/"
"/.github/workflows/.bak/"
"*.bak"
".last_run_id"
".diag_last_failed.json"
"actionlint.tar.gz"
)

for pat in "${patterns[@]}"; do
  if grep -qxF -- "$pat" "$IGNOREFILE" 2>/dev/null ; then
    echo "OK exists: $pat"
  else
    if [[ "$APPLY" == "1" ]]; then
      echo "$pat" >> "$IGNOREFILE"
      echo "Appended: $pat"
    else
      echo "Would append: $pat"
    fi
  fi
done

if [[ "$APPLY" == "1" ]]; then
  git add "$IGNOREFILE"
  echo ".gitignore updated and staged."
fi

echo "END: step-12"
_on_exit(){
  if [[ "${NONINTERACTIVE:-0}" != "1" ]]; then
    printf "\n== step-12 finished (log: %s) ==\nPress Enter to close... " "$LOG"
    read -r _
  fi
}
trap _on_exit EXIT
