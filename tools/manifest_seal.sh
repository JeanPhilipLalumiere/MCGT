#!/usr/bin/env bash
# tools/manifest_seal.sh
# But : revalider l’état (audit/diag strict/tests) et créer un tag si tout est propre.
# - échoue si diag signale un warning/erreur
# - journalise dans _tmp/manifest_seal.<TS>.log
# - idempotent (chaque run crée un tag horodaté distinct)

set -euo pipefail

TS=$(date -u +%Y%m%dT%H%M%SZ)
LOG="_tmp/manifest_seal.$TS.log"
mkdir -p _tmp

echo "[seal] start $TS" | tee -a "$LOG"

echo "[seal] audit --all" | tee -a "$LOG"
./tools/audit_manifest_files.sh --all | tee -a "$LOG"

echo "[seal] diag strict (fail on warnings)" | tee -a "$LOG"
python zz-manifests/diag_consistency.py zz-manifests/manifest_master.json \
  --report json --normalize-paths --apply-aliases --strip-internal --content-check --fail-on warnings \
  > "_tmp/diag_seal.$TS.json" 2>&1 || {
    echo "[seal] diag failed — head of report ↓" | tee -a "$LOG"
    head -n 200 "_tmp/diag_seal.$TS.json" | tee -a "$LOG"
    exit 1
  }

echo "[seal] tests" | tee -a "$LOG"
pytest -q | tee -a "$LOG"

echo "[seal] tag + push" | tee -a "$LOG"
TAG="v${TS}-manifest-clean"
git tag -a "$TAG" -m "manifest clean (diag=0 warnings, tests OK)"
git push --tags

echo "[seal] done (tag=$TAG, log=$LOG)" | tee -a "$LOG"
# === COPY LOGS FROM HERE ===
