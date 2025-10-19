#!/usr/bin/env bash
set -euo pipefail
OUT=".ci-out/scan/large_tracked_files.csv"
mkdir -p "$(dirname "$OUT")"
git ls-files -z | xargs -0 -n1 stat -c '%s %n' 2>/dev/null | awk '$1>5000000{printf("%d,%s\n",$1,$2)}' | sort -nr > "$OUT"
echo "Wrote large tracked files (>5MB) to $OUT"
echo "Top 50:"
head -n 50 "$OUT"
