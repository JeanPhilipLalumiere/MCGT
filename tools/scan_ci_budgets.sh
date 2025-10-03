#!/usr/bin/env bash
set -Eeuo pipefail
out=".ci-out/ci_budgets_report.txt"
: >"$out"

echo "[BUDGET SCAN]" | tee -a "$out"
for f in .github/workflows/*.yml .github/workflows/*.yaml; do
  [ -f "$f" ] || continue
  tm=$(grep -nE '^[[:space:]]*timeout-minutes:[[:space:]]*[0-9]+' "$f" || true)
  pv=$(grep -nE 'python-version' "$f" || true)
  echo "FILE: $f" | tee -a "$out"
  if [ -n "$tm" ]; then
    echo "$tm"
  else
    echo "  (no timeout-minutes found)"
  fi | tee -a "$out"
  if [ -n "$pv" ]; then
    echo "$pv"
  else
    echo "  (no python-version found)"
  fi | tee -a "$out"
  echo "" | tee -a "$out"
done
echo "[OK] wrote $out"
