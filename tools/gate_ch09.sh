# tools/gate_ch09.sh
#!/usr/bin/env bash
set -Eeuo pipefail
bash tools/smoke_ch09_fast.sh
python3 tools/validate_ch09_artifacts.py
echo "[OK] Gate CH09 : smoke + artefacts validés."
