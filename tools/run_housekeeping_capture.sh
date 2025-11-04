#!/usr/bin/env bash
# Wrapper: exécute le housekeeping en mode trace, capture complète, fenêtre ouverte.

set -uo pipefail
mkdir -p _tmp

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
LOG="_tmp/housekeeping.run.${STAMP}.log"
TARGET="tools/housekeeping_safe_noclose.sh"

if [[ ! -x "$TARGET" ]]; then
  echo "ERROR: $TARGET not found or not executable."
  echo "Fix: re-créer le script puis:  chmod +x $TARGET"
  read -rp "Appuyez sur Entrée pour fermer..."
  exit 1
fi

echo "Log: $LOG"
echo "Running: $TARGET"
echo "--------------------------------------------"
bash -x "$TARGET" 2>&1 | tee "$LOG"
echo "--------------------------------------------"
echo "Exécution terminée. Log: $LOG"
read -rp "Appuyez sur Entrée pour fermer..."
