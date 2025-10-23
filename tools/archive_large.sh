#!/usr/bin/env bash
set -euo pipefail
repo="${1:-.}"
cd "$repo"
mkdir -p _archives_preclean

# dry-run mode by default; use --apply to actually move
APPLY=false
if [ "${2:-}" == "--apply" ]; then APPLY=true; fi

while read -r f; do
  [ -f "$f" ] || continue
  echo "candidate: $f"
  if "$APPLY"; then
    echo "  moving -> _archives_preclean/$(basename "$f")"
    mv "$f" "_archives_preclean/$(basename "$f")"
    git rm --cached "$f" || true
  fi
done < _tmp/large_files_in_worktree.txt

if "$APPLY"; then
  git commit -m "chore: archive large files to _archives_preclean and remove from tracked files" || true
  echo "Applied changes and committed. Remember to push."
else
  echo "Dry-run complete. Rerun with '--apply' to move files and commit."
fi

