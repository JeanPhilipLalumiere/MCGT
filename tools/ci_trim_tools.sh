#!/usr/bin/env bash
# Supprime les scripts tools inutiles en conservant une whitelist
set -euo pipefail
mkdir -p .ci-logs
STAMP="$(date +%Y%m%dT%H%M%S)"
LOG=".ci-logs/ci_trim_tools-$STAMP.log"
exec > >(stdbuf -oL -eL tee -a "$LOG") 2>&1

say() {
  date +"[%F %T] - "
  printf "%s\n" "$*"
}

say "Whitelist: keep these scripts"
keep=("guard_no_recipeprefix.sh" "sanity_diag.sh" "run_with_instrumentation.sh" "run_and_tail.sh" "ci_select_canonical_workflow.sh" "docs_write_ci_readme.sh" "ci_commit_and_push_all.sh" "ci_archive_logs.sh" "git_delete_temp_branches.sh" "ci_add_yaml_check.sh" "ci_trigger_and_fetch_diag.sh")
cd tools
for f in *; do
  if [[ " ${keep[*]} " == *" $f "* ]]; then
    say "KEEP $f"
  else
    say "REMOVE $f"
    rm -f -- "$f" || true
  fi
done
say "Done. Log: $LOG"
