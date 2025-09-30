#!/usr/bin/env bash
set -euo pipefail
if grep -n '^[[:space:]]*\.RECIPEPREFIX' Makefile >/dev/null 2>&1; then
  echo "❌ .RECIPEPREFIX détecté dans Makefile — interdit (on utilise TAB)."
  grep -n '^[[:space:]]*\.RECIPEPREFIX' Makefile || true
  exit 2
fi
echo "✅ Aucun .RECIPEPREFIX actif — OK."
