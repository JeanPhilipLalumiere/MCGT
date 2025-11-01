#!/usr/bin/env bash
set -Eeuo pipefail
python - <<'PY'
import sys; sys.version_info >= (3,10) or (_ for _ in ()).throw(SystemExit("Python >=3.10 requis"))
PY
python tools/_check_fig_manifest.py
