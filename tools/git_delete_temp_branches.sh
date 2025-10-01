#!/usr/bin/env bash
set -euo pipefail
LOG=".ci-logs/git_delete_temp_branches-$(date +%Y%m%dT%H%M%S).log"
exec > >(stdbuf -oL -eL tee -a "$LOG") 2>&1
say(){ date +"[%F %T] - "; printf "%s\n" "$*"; }

say "Listing local branches that look temporary (pattern ci/sanity-*)"
mapfile -t branches < <(git branch --list 'ci/*' | sed 's/^[*[:space:]]*//')
if [ ${#branches[@]} -eq 0 ]; then
  say "No matching local branches."
  exit 0
fi

say "Candidates to delete locally:"
for b in "${branches[@]}"; do say " - $b"; done

read -p "Delete these local branches? (y/N) " yn
if [[ "$yn" =~ ^[Yy]$ ]]; then
  for b in "${branches[@]}"; do
    git branch -D "$b" || true
    say "Deleted $b"
  done
fi
say "Done. Log: $LOG"
