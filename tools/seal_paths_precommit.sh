#!/usr/bin/env bash
set -euo pipefail
# Refuse toute modif sur chemins scellés, sauf si MCGT_UNSEAL=1
SEALED_GLOBS=(
  "zz-scripts/chapter10/*.py"
)
if [[ "${MCGT_UNSEAL:-0}" != "1" ]]; then
  mapfile -t CHANGED < <(git diff --cached --name-only --diff-filter=ACMR)
  for g in "${SEALED_GLOBS[@]}"; do
    for f in "${CHANGED[@]}"; do
      [[ "$f" == $g ]] && { echo "[FAIL] sealed path: $f (set MCGT_UNSEAL=1 to override)"; exit 1; }
    done
  done
fi
exit 0
