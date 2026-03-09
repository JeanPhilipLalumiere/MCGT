#!/usr/bin/env bash
set -euo pipefail

bad=0
while IFS= read -r -d '' f; do
  [[ -f "$f" ]] || continue
  [[ -x "$f" ]] || continue
  case "$f" in
    *.sh|*.py|*/hooks/*) ;;
    *)
      echo "[fail] executable bit on non-script: $f"
      bad=1
      ;;
  esac
done < <(git ls-files -z)

if ((bad)); then
  exit 1
fi
echo "[ok] executable-bit policy passed"
