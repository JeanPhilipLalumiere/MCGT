#!/usr/bin/env bash
# step-01-list-candidates.sh
set -euo pipefail
LOGDIR=".tmp-cleanup-logs"; mkdir -p "$LOGDIR"
LOG="$LOGDIR/step-01-list-candidates.log"
exec > >(tee -a "$LOG") 2>&1

echo "START: step-01-list-candidates $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
cd "$(git rev-parse --show-toplevel)"

patterns=(
  ".ci_poke"
  ".pytest_cache"
  ".tmp-*"
  ".tmp-ci"
  ".tmp-gh-dist"
  "dist_from_*"
  "artifacts_*"
  "dist_from_ci"
  "dist_from_ci_all"
  "dist_from_retry_*"
  "dist_from_testonly_*"
  "dist_from_[01"
  "_snapshots"
  ".github/workflows/.bak"
  "scripts/.bak"
  "dist/**"
  "actionlint.tar.gz"
  ".diag_last_failed.json"
  ".last_run_id"
  "*.bak"
  "pyproject.toml.bak.*"
  "setup.py.bak.*"
  "setup.cfg.bak"
)

echo "Expanding patterns..."
shopt -s nullglob dotglob globstar
> step-01-candidates.txt
for p in "${patterns[@]}"; do
  echo "---- pattern: $p ----"
  for f in $p; do
    printf "%s\n" "$f"
    printf "%s\n" "$f" >> step-01-candidates.txt
  done
done
shopt -u nullglob dotglob globstar

echo
echo "Wrote step-01-candidates.txt (inspect this file)."
echo "END: step-01-list-candidates"
_on_exit(){
  if [[ "${NONINTERACTIVE:-0}" != "1" ]]; then
    printf "\n== step-01 finished (log: %s, list: step-01-candidates.txt) ==\nPress Enter to close... " "$LOG"
    read -r _
  fi
}
trap _on_exit EXIT
