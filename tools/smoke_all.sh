export PYTHONPATH="$(git rev-parse --show-toplevel):$PYTHONPATH"
# tools/smoke_all.sh
#!/usr/bin/env bash
set -Eeuo pipefail
START_TS="$(date +%Y%m%d_%H%M%S)"
LOG="zz-out/runlogs/smoke_all_${START_TS}.log"
mkdir -p zz-out/runlogs
exec > >(tee -a "$LOG") 2>&1
echo "[INFO] Smoke ALL — $(date)"

status=0

run_ch() {
  local ch="$1" cmd="$2"
  echo "────────────────────────────────────────"
  echo "[INFO] $ch"
  if bash -c "$cmd"; then
    echo "[OK] $ch"
  else
    echo "[FAIL] $ch"
    status=1
  fi
}

# CH09 (opérationnel)
run_ch "CH09" "bash tools/smoke_ch09_fast.sh"

# TODO: brancher ici CH01..CH08, CH10 au fur et à mesure
# ex: run_ch "CH01" "bash scripts/chapter01/smoke.sh"

echo "────────────────────────────────────────"
if [ $status -eq 0 ]; then
  echo "[OK] Smoke ALL green"
else
  echo "[WARN] Smoke ALL with failures"
fi
exit $status
