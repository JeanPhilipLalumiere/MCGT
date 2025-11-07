#!/usr/bin/env bash
set -Eeuo pipefail
trap 'code=$?; echo; echo "[SMOKE] Fin (code=$code)"; read -rp "▶ Appuyez sur Entrée pour quitter... " _' EXIT
echo "[SMOKE] ch09/ch10"
make smoke-all || true
echo "[SMOKE] diag_consistency (rapport JSON)"
python zz-manifests/diag_consistency.py zz-manifests/manifest_master.json \
  --report json --normalize-paths --apply-aliases --strip-internal > _diag_master_after_smoke.json || true
echo "OK: _diag_master_after_smoke.json"
