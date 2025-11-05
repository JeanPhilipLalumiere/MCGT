#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"; cd "$ROOT"

# Par défaut, pas d'interaction
MCGT_NO_SHELL_DROP="${MCGT_NO_SHELL_DROP:-1}"
TS="$(date -u +%Y%m%d_%H%M%S)"
LOG=".ci-logs/env_lock_${TS}.log"
exec > >(tee -a "$LOG") 2>&1

trap 'ec=$?; echo; echo "== Fin (code: $ec) =="; echo "Log: $LOG"; exit $ec' EXIT

OUT="requirements-prepub.txt"
echo "== MCGT • Lock Python environment =="
python -V || true
pip --version || true

TMP="/tmp/req_${TS}.txt"
if pip freeze > "$TMP"; then
  awk '/^[A-Za-z0-9_.-]+==[0-9][0-9A-Za-z_.+-]*/{print}' "$TMP" | LC_ALL=C sort -f > "$OUT"
else
  : > "$OUT"
fi

echo "Écrit: $OUT ($(wc -l < "$OUT") paquets)"
mkdir -p zz-manifests
sha256sum "$OUT" > "zz-manifests/${OUT}.sha256" 2>/dev/null || true
