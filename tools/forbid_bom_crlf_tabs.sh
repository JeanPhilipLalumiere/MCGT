#!/usr/bin/env bash
set -euo pipefail

if (($# == 0)); then
  echo "usage: $0 <file-or-glob> [... ]" >&2
  exit 2
fi

shopt -s nullglob globstar
bad=0

for pattern in "$@"; do
  for f in $pattern; do
    [[ -f "$f" ]] || continue
    if LC_ALL=C grep -q $'\r' "$f"; then
      echo "[fail] CRLF detected: $f"
      bad=1
    fi
    if LC_ALL=C grep -q $'\t' "$f"; then
      echo "[fail] TAB detected: $f"
      bad=1
    fi
    if head -c 3 "$f" | LC_ALL=C grep -q $'^\xEF\xBB\xBF'; then
      echo "[fail] UTF-8 BOM detected: $f"
      bad=1
    fi
  done
done

if ((bad)); then
  exit 1
fi
echo "[ok] encoding policy passed"
