#!/usr/bin/env bash
set -euo pipefail
# Échoue si on voit "fallback" dans les logs récents de smoke CH09 fig02
if grep -RIn "fallback" zz-figures zz-out .ci-logs 2>/dev/null | grep -i "fig_02\|chapter09" ; then
  echo "[FAIL] fallback détecté pour fig02/CH09"
  exit 1
fi
echo "[OK] aucun fallback détecté"
