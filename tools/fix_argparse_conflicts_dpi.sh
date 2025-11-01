#!/usr/bin/env bash
set -Eeuo pipefail

# Cible: les 4 fichiers signalés par le triage
FILES=(
  "zz-scripts/chapter01/plot_fig02_logistic_calibration.py"
  "zz-scripts/chapter01/plot_fig03_relative_error_timeline.py"
  "zz-scripts/chapter01/plot_fig05_I1_vs_T.py"
  "zz-scripts/chapter02/plot_fig02_calibration.py"
)

ts="$(date -u +%Y%m%dT%H%M%SZ)"
patched=0

for f in "${FILES[@]}"; do
  [[ -f "$f" ]] || { echo "[SKIP] $f (absent)"; continue; }
  cp --no-clobber --update=none -- "$f" "${f}.bak_${ts}" || true

  # Patch: ArgumentParser( ... ) -> ArgumentParser(conflict_handler='resolve', ... )
  # uniquement si pas déjà présent
  if grep -n "ArgumentParser" "$f" | grep -vq "conflict_handler="; then
    # insertion sûre: remplace la première occurrence de "ArgumentParser(" sur la ligne
    sed -E -i "s/ArgumentParser\(/ArgumentParser(conflict_handler='resolve', /" "$f"
    echo "[PATCH] $f"
    patched=$((patched+1))
  else
    echo "[OK] $f — déjà conflict_handler=resolve"
  fi
done

echo "[SUMMARY] fichiers patchés: $patched"

echo "[RUN] Smoke --help ciblé (4 fichiers)..."
ok=0; fail=0
for f in "${FILES[@]}"; do
  if python "$f" --help >/dev/null 2>&1; then
    echo -e "OK\t$f"
    ok=$((ok+1))
  else
    echo -e "FAIL\t$f"
    fail=$((fail+1))
  fi
done
echo "[SUMMARY] OK=$ok FAIL=$fail"
