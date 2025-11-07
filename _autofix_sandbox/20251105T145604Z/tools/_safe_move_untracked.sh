#!/usr/bin/env bash
set -uo pipefail
git ls-files --others --exclude-standard -z | while IFS= read -r -d '' f; do
  # ignorer caches/dossiers bruyants et éléments à préserver
  [[ "$f" == _tmp/* || "$f" == _tmp-figs/* || "$f" == .git/* ]] && { echo "SKIP: $f (cache/git)"; continue; }
  [[ "$f" == "run_housekeeping_capture.sh" ]] && { echo "SKIP: $f (wrapper root)"; continue; }
  [[ "$f" == tools/* ]] && { echo "SKIP: $f (already in tools)"; continue; }
  [[ "$f" == *.txt ]] && { echo "SKIP: $f (.txt)"; continue; }

  if [[ "$f" == *.sh ]]; then
    mkdir -p tools
    dest="tools/$(basename "$f")"
  else
    mkdir -p _attic_untracked
    dest="_attic_untracked/$(basename "$f")"
  fi

  if mv -f -- "$f" "$dest" 2>/dev/null; then
    echo "MOVED: $f -> $dest"
  else
    echo "SKIP: $f (move failed)"
  fi
done
