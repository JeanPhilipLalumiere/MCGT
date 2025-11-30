#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
LOG_DIR="zz-logs"
mkdir -p "$LOG_DIR"
LOG_FILE="${LOG_DIR}/step02_inventory_${STAMP}.log"

echo "=== MCGT Step 02 : inventaire par chapitre ===" | tee "$LOG_FILE"
echo "[INFO] Repo root : $ROOT" | tee -a "$LOG_FILE"
echo "[INFO] Horodatage (UTC) : $STAMP" | tee -a "$LOG_FILE"
echo | tee -a "$LOG_FILE"

for CH in $(seq -w 1 10); do
  echo "------------------------------------------------------------" | tee -a "$LOG_FILE"
  echo "[CH${CH}] Scripts (zz-scripts/chapter${CH})" | tee -a "$LOG_FILE"
  find "zz-scripts/chapter${CH}" -maxdepth 1 -type f -name '*.py' 2>/dev/null | sort | tee -a "$LOG_FILE" || true

  echo | tee -a "$LOG_FILE"
  echo "[CH${CH}] Données (zz-data/chapter${CH})" | tee -a "$LOG_FILE"
  find "zz-data/chapter${CH}" -maxdepth 1 -type f \( -name '*.csv' -o -name '*.json' \) 2>/dev/null | sort | tee -a "$LOG_FILE" || true

  echo | tee -a "$LOG_FILE"
  echo "[CH${CH}] Figures (zz-figures/chapter${CH})" | tee -a "$LOG_FILE"
  find "zz-figures/chapter${CH}" -maxdepth 1 -type f -name '*.png' 2>/dev/null | sort | tee -a "$LOG_FILE" || true

  echo | tee -a "$LOG_FILE"
done

echo "------------------------------------------------------------" | tee -a "$LOG_FILE"
echo "[OK] Step 02 terminé. Inventaire écrit dans : $LOG_FILE" | tee -a "$LOG_FILE"
