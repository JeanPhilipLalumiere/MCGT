#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG_DIR="$ROOT/zz-logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/step06_low_priority_data_${TS}.log"

exec > >(tee "$LOG_FILE") 2>&1

echo "=== MCGT Step 06 : audit LOW_PRIORITY_DATA ==="
echo "[INFO] Repo root : $ROOT"
echo "[INFO] Horodatage (UTC) : $TS"
echo

LP_FILES=(
  "zz-data/chapter03/placeholder.csv"
  "zz-data/chapter07/placeholder.csv"
  "zz-data/chapter10/dummy_results.csv"
  "zz-data/chapter10/example_results.csv"
)

echo "------------------------------------------------------------"
echo "[CHECK] Présence des fichiers LOW_PRIORITY_DATA"
for f in "${LP_FILES[@]}"; do
  if [[ -f "$f" ]]; then
    echo "[OK] LPDATA_EXISTS $f"
  else
    echo "[WARN] LPDATA_MISSING $f"
  fi
done

echo "------------------------------------------------------------"
echo "[SCAN] Recherche d'utilisations dans le dépôt (hors logs/attic/zz-out/.git)"
for f in "${LP_FILES[@]}"; do
  name="$(basename "$f")"
  echo
  echo "[FILE] $f"
  if [[ ! -f "$f" ]]; then
    echo "  -> SKIP (absent)"
    continue
  fi

  TMP="$(mktemp)"
  if rg -n --hidden -S "$name" . \
        --glob '!zz-logs/*' \
        --glob '!.git/*' \
        --glob '!attic/*' \
        --glob '!zz-out/*' \
        --glob '!.venv/*' >"$TMP" 2>&1; then
    echo "  -> LPDATA_USED name=$name"
    sed 's/^/    /' "$TMP"
  else
    echo "  -> LPDATA_UNUSED name=$name (aucune référence trouvée hors logs/attic/zz-out)"
  fi
  rm -f "$TMP"
done

echo
echo "[OK] Step 06 terminé. Rapport : $LOG_FILE"
