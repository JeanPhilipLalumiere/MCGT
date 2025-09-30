#!/usr/bin/env bash
# step-00-preflight.sh
# Preflight checks. SAFE by default. Keeps the terminal open at the end.
set -euo pipefail

LOGDIR=".tmp-cleanup-logs"
mkdir -p "$LOGDIR"
LOG="$LOGDIR/step-00-preflight.log"
exec > >(tee -a "$LOG") 2>&1

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
echo "START: step-00-preflight $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
if [[ -z "$ROOT" || ! -d "$ROOT/.git" ]]; then
  echo "ERROR: must run inside a Git repository." >&2
  status=2
else
  cd "$ROOT"
  echo "Repo: $ROOT"
  echo "Git branch: $(git branch --show-current)"
  echo "Staged changes (should be none):"
  git status --porcelain || true
  status=0
fi

echo "END: step-00-preflight (status=$status)"
_on_exit(){
  if [[ "${NONINTERACTIVE:-0}" != "1" ]]; then
    printf "\n== step-00 finished (log: %s) ==\nPress Enter to close this script output... " "$LOG"
    read -r _
  fi
  exit "$status"
}
trap _on_exit EXIT
