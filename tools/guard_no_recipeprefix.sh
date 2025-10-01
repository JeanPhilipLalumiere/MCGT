#!/usr/bin/env bash
set +e
if grep -n '^[[:space:]]*\.RECIPEPREFIX' Makefile >/dev/null 2>&1; then
  echo "❌ .RECIPEPREFIX détecté dans Makefile"; exit 1
fi
echo "✅ Aucun .RECIPEPREFIX actif — OK."
