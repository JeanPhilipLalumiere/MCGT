#!/usr/bin/env bash
# Step 01 - Garde-fou diag + smoke pour MCGT
# À lancer AVANT et APRÈS les grosses opérations de nettoyage.

set -Eeuo pipefail

trap 'code=$?;
      echo;
      echo "[ERREUR] Arrêt avec code $code";
      echo "[ASTUCE] Vérifie le log ci-dessous pour voir à quelle étape ça a cassé.";
     ' ERR

# Localisation du dépôt (script placé dans tools/)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

timestamp="$(date -u +"%Y%m%dT%H%M%SZ")"
LOG_DIR="${REPO_ROOT}/zz-logs"
mkdir -p "${LOG_DIR}"
LOG_FILE="${LOG_DIR}/step01_guard_diag_smoke_${timestamp}.log"

{
  echo "=== MCGT Step 01 : garde-fou diag + smoke ==="
  echo "[INFO] Repo root : ${REPO_ROOT}"
  echo "[INFO] Horodatage (UTC) : ${timestamp}"
  echo

  echo "------------------------------------------------------------"
  echo "[1/4] Diagnostic de cohérence des manifests"
  echo "    -> python zz-manifests/diag_consistency.py zz-manifests/manifest_master.json --report text"
  echo "------------------------------------------------------------"
  python zz-manifests/diag_consistency.py \
    zz-manifests/manifest_master.json \
    --report text
  echo

  echo "------------------------------------------------------------"
  echo "[2/4] Smoke test ciblé CH09 (fast)"
  echo "    -> bash zz-tools/smoke_ch09_fast.sh"
  echo "------------------------------------------------------------"
  bash zz-tools/smoke_ch09_fast.sh
  echo

  echo "------------------------------------------------------------"
  echo "[3/4] Smoke global (squelette)"
  echo "    -> bash zz-tools/smoke_all_skeleton.sh"
  echo "------------------------------------------------------------"
  bash zz-tools/smoke_all_skeleton.sh
  echo

  echo "------------------------------------------------------------"
  echo "[4/4] Probe des versions (manifests, pyproject, __init__, CITATION)"
  echo "    -> ./tools/mcgt_probe_versions_v1.py"
  echo "------------------------------------------------------------"
  ./tools/mcgt_probe_versions_v1.py
  echo

  echo "[OK] Step 01 terminé sans erreur."
  echo "     Log complet : ${LOG_FILE}"

} 2>&1 | tee "${LOG_FILE}"
