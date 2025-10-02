#!/usr/bin/env bash
set -euo pipefail
LOG=".ci-logs/ci_commit_and_push_all-$(date +%Y%m%dT%H%M%S).log"
exec > >(stdbuf -oL -eL tee -a "$LOG") 2>&1
say() {
  date +"[%F %T] - "
  printf "%s\n" "$*"
}

DEF_BRANCH="$(git remote show origin 2>/dev/null | awk '/HEAD branch/ {print $NF}')"
[ -n "$DEF_BRANCH" ] || DEF_BRANCH="main"
CUR_BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)"

say "Default remote branch: $DEF_BRANCH | Current: $CUR_BRANCH"

git add -A
say "git status --porcelain:"
git status --porcelain

say "Show staged diff (first 200 lines):"
git diff --staged | sed -n '1,200p'

read -r -p "Commit all staged changes with message? (y/N) " yn
if [[ "$yn" =~ ^[Yy]$ ]]; then
  git commit -m "ci: tidy tools & workflows (auto)" || true
  read -r -p "Push to origin/$DEF_BRANCH ? (y/N) " yn2
  if [[ "$yn2" =~ ^[Yy]$ ]]; then
    git push origin "$DEF_BRANCH"
    say "Pushed to origin/$DEF_BRANCH"
  else
    say "Push skipped"
  fi
else
  say "Commit skipped"
fi

say "Done. Log: $LOG"
