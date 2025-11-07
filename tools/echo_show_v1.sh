#!/usr/bin/env bash
# Usage: tools/echo_show_v1.sh <file1> [file2 ...]
# Affiche proprement (entête, taille, 1..N numérotées), sans modifier.
set -euo pipefail
for f in "$@"; do
  if [[ -f "$f" ]]; then
    bytes=$(wc -c < "$f" | tr -d ' ')
    lines=$(wc -l < "$f" | tr -d ' ')
    printf '\n\033[1m── %s ── (%s bytes, %s lines)\033[0m\n' "$f" "$bytes" "$lines"
    nl -ba "$f" | sed -n '1,400p'
    [[ "$lines" -gt 400 ]] && echo "...(troncation, utilisez --full pour tout voir)"
  else
    echo "!! manquant: $f"
  fi
done
