#!/usr/bin/env bash
# step-13-review-and-commit.sh
set -euo pipefail
LOGDIR=".tmp-cleanup-logs"; mkdir -p "$LOGDIR"
LOG="$LOGDIR/step-13-review-and-commit.log"
exec > >(tee -a "$LOG") 2>&1

echo "START: step-13 $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
cd "$(git rev-parse --show-toplevel)"

echo "GIT STATUS (staged & unstaged):"
git status --short || true
echo
echo "Staged diffs (if any):"
git diff --staged --name-only || true
echo
echo "To commit staged removals use:"
echo "  git commit -m 'chore: repo cleanup — purge artifacts, caches, throwaway CI scripts, backups'"
echo "Or inspect staged changes with 'git diff --staged' first."

echo "END: step-13"
_on_exit(){
  if [[ "${NONINTERACTIVE:-0}" != "1" ]]; then
    printf "\n== step-13 finished (log: %s) ==\nPress Enter to close... " "$LOG"
    read -r _
  fi
}
trap _on_exit EXIT
