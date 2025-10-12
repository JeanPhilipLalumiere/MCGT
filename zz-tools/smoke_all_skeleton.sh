export PYTHONPATH="$(git rev-parse --show-toplevel):$PYTHONPATH"
# zz-tools/smoke_all_skeleton.sh
#!/usr/bin/env bash
set -Eeuo pipefail
echo "[INFO] Smoke global (squelette)"
bash zz-tools/smoke_ch09_fast.sh
# TODO: ajouter CH01..CH10 quand les runners de chapitre seront prêts
