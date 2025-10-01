#!/usr/bin/env bash
set -euo pipefail
if git ls-files | grep -qE '(^|/)\.RECIPEPREFIX$'; then
  echo "ERROR: .RECIPEPREFIX détecté"; exit 1
fi
echo "OK: aucun .RECIPEPREFIX"
