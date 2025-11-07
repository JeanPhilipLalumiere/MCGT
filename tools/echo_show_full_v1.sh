#!/usr/bin/env bash
set -euo pipefail
for f in "$@"; do
  if [[ -f "$f" ]]; then
    bytes=$(wc -c < "$f" | tr -d ' ')
    lines=$(wc -l < "$f" | tr -d ' ')
    printf '\n\033[1m── %s ── (%s bytes, %s lines)\033[0m\n' "$f" "$bytes" "$lines"
    nl -ba "$f"
  else
    echo "!! manquant: $f"
  fi
done
