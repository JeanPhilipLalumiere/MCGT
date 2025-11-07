#!/usr/bin/env bash
set -euo pipefail

echo "[PASS7] Restauration des originaux du chapitre 10 depuis *.bak"

D="zz-scripts/chapter10"
restored=0
skipped=0

shopt -s nullglob
for bak in "$D"/*.py.bak; do
  py="${bak%.bak}"
  if [[ -f "$py" ]]; then
    # garde une trace du stub actuel, puis restaure l'original
    cp -f "$bak" "$py"
    echo "[OK] Restoré: $(basename "$py") (depuis $(basename "$bak"))"
    ((restored++)) || true
  else
    echo "[SKIP] Pas de cible .py pour $(basename "$bak")"
    ((skipped++)) || true
  fi
done
shopt -u nullglob

echo "[PASS7] Restorations: $restored, Skips: $skipped"

# 1) Smoke rapide chapitre 10 (si dispo)
if [[ -x tools/ch10_smoke.sh ]]; then
  echo "[PASS7] Smoke ch10…"
  tools/ch10_smoke.sh || true
fi

# 2) Inventaire global (safe v4) pour vérifier qu'on reste à 0 FAIL
if [[ -x tools/homog_pass4_cli_inventory_safe_v4.sh ]]; then
  echo "[PASS7] Inventaire pass4-safe v4…"
  tools/homog_pass4_cli_inventory_safe_v4.sh
fi

echo
echo "=== Résumé (fin du rapport inventaire) ==="
tail -n 12 zz-out/homog_cli_inventory_pass4.txt || true
