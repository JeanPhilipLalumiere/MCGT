# zz-tools/gate_ch09.sh
#!/usr/bin/env bash
set -Eeuo pipefail
bash zz-tools/smoke_ch09_fast.sh
python3 zz-tools/validate_ch09_artifacts.py
echo "[OK] Gate CH09 : smoke + artefacts validés."
