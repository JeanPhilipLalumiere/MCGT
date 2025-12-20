#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

# Purge Python cache artifacts
find . -type d -name '__pycache__' -prune -exec rm -rf {} +
find . -type f -name '*.pyc' -delete

# Remove root-level diagnostic and temp files
for f in _diag_* _tmp_* *.log; do
  if [ -e "$f" ]; then
    rm -f "$f"
  fi
done

# Move any root-level shell scripts into _tools/
mkdir -p _tools
for f in *.sh; do
  if [ -f "$f" ]; then
    mv "$f" _tools/
  fi
done

# Run coherence check
python check_coherence.py
