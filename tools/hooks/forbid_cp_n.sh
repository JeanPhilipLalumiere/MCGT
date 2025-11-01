#!/usr/bin/env bash
set -Eeuo pipefail
# Échoue s'il reste 'cp --no-clobber --update=none' dans des scripts shell suivis par git
mapfile -t CANDS < <(git ls-files '*.*sh' 'tools/**' ':!:*.bak_*' 2>/dev/null | grep -E '\.sh$' || true)
[[ ${#CANDS[@]} -eq 0 ]] && exit 0
bad=0
for f in "${CANDS[@]}"; do
  if grep -nE '\bcp[[:space:]]+-n\b' -- "$f" >/dev/null; then
    echo "[CP-N] $f"
    bad=1
  fi
done
exit $bad
