#!/usr/bin/env bash
set -uo pipefail
mkdir -p _tmp
ts="$(date -u +%Y%m%dT%H%M%SZ)"
LOG="_tmp/housekeeping.run.$ts.log"
echo "Log: $LOG"
echo "Running: tools/housekeeping_safe_noclose.sh"
echo "--------------------------------------------"
bash -x tools/housekeeping_safe_noclose.sh 2>&1 | tee "$LOG"
echo "--------------------------------------------"
echo "Exécution terminée. Log: $LOG"
read -rp "Appuyez sur Entrée pour fermer..."
