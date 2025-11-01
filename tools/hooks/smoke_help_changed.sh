#!/usr/bin/env bash
set -Eeuo pipefail
mapfile -t FILES < <(git diff --name-only --cached | grep -E '^zz-scripts/.+/plot_.*\.py$' || true)
[[ ${#FILES[@]} -eq 0 ]] && { echo "[INFO] Aucun plot modifié — skip."; exit 0; }
fail=0
for f in "${FILES[@]}"; do
  if python "$f" --help >/dev/null 2>&1; then
    echo "[OK] $f"
  else
    echo "[FAIL] $f"
    fail=1
  fi
done
exit $fail
