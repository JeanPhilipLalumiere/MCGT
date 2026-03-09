#!/usr/bin/env bash
set -euo pipefail

shopt -s nullglob
files=(.github/**/*.yml .github/**/*.yaml)
if ((${#files[@]} == 0)); then
  echo "[ok] no workflow files found"
  exit 0
fi

bad=0
for f in "${files[@]}"; do
  if grep -n $'\t' "$f" >/dev/null; then
    echo "[fail] tab character found: $f"
    bad=1
  fi
done

if ((bad)); then
  exit 1
fi

echo "[ok] workflow audit passed"
