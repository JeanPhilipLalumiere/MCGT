#!/usr/bin/env bash
set -Eeuo pipefail

# Script de sanity pré-release pour MCGT / zz-tools.
# Hypothèses :
#   - environnement Python déjà activé (par ex. conda activate mcgt-dev)
#   - dépôt cloné dans ~/MCGT

cd ~/MCGT

TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG_DIR="/tmp/mcgt_pre_release_${TS}"
mkdir -p "$LOG_DIR"

echo "########## PRE-RELEASE SANITY (diag + tests + packaging) ##########"
echo "[INFO] Logs détaillés dans : $LOG_DIR"
echo

echo "==== 1) diag_consistency manifest_publication (strict) ===="
PAUSE_ON_EXIT=0 python ./zz-manifests/diag_consistency.py \
  --repo-root "$PWD" \
  --normalize-paths \
  --apply-aliases \
  --content-check \
  --report text \
  --fail-on errors \
  ./zz-manifests/manifest_publication.json \
  > "$LOG_DIR/diag_manifest_publication.log"

sed -n '1,40p' "$LOG_DIR/diag_manifest_publication.log"
echo

echo "==== 2) diag_consistency manifest_master (fail-on none, 0 erreur attendu à terme; 1 FILE_MISSING ch09 toléré) ===="
PAUSE_ON_EXIT=0 python ./zz-manifests/diag_consistency.py \
  --repo-root "$PWD" \
  --normalize-paths \
  --apply-aliases \
  --content-check \
  --report text \
  --fail-on none \
  ./zz-manifests/manifest_master.json \
  > "$LOG_DIR/diag_manifest_master.log"

sed -n '1,40p' "$LOG_DIR/diag_manifest_master.log"
echo

echo "==== 3) pytest zz-tests ===="
PAUSE_ON_EXIT=0 python -m pytest ./zz-tests \
  > "$LOG_DIR/pytest_zztests.log"

sed -n '1,40p' "$LOG_DIR/pytest_zztests.log"
echo

echo "==== 4) Packaging sanity (build + twine check) ===="
rm -rf ./dist/ ./build/ ./zz_tools.egg-info

python -m build \
  > "$LOG_DIR/build.log"

python -m twine check ./dist/* \
  > "$LOG_DIR/twine_check.log"

echo "[OK] Packaging sanity terminé."
echo "[INFO] build.log   : $LOG_DIR/build.log"
echo "[INFO] twine_check : $LOG_DIR/twine_check.log"
echo
echo "########## PRE-RELEASE SANITY FINI ##########"
