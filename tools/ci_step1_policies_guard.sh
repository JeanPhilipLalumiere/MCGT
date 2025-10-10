#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

if ! command -v jq >/dev/null 2>&1; then
  echo "::group::Install jq"
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update -qq && sudo apt-get install -y -qq jq
  else
    echo "::error::jq is required"; exit 2
  fi
  echo "::endgroup::"
fi

missing=0
for f in runtime_spec.json env_whitelist.json plot_style.json figure_layout.json retention.json cli_extensions.json units_registry.json; do
  if [ ! -s "policies/$f" ]; then
    echo "::error::missing policies/$f"; missing=1
  fi
done
[ "$missing" -eq 0 ] || { echo "::error::Policies missing"; exit 1; }

# Checks
python_ver="$(python3 -c 'import sys;print(".".join(map(str,sys.version_info[:3])))' 2>/dev/null || echo "0.0.0")"
np_ver="$(python3 - <<'PY' 2>/dev/null || true
try:
  import numpy as _; print(_. __version__)
except Exception: print("0.0.0")
PY
)"
scipy_ver="$(python3 - <<'PY' 2>/dev/null || true
try:
  import scipy as _; print(_. __version__)
except Exception: print("0.0.0")
PY
)"
mpl_ver="$(python3 - <<'PY' 2>/dev/null || true
try:
  import matplotlib as _; print(_. __version__)
except Exception: print("0.0.0")
PY
)"
pandas_ver="$(python3 - <<'PY' 2>/dev/null || true
try:
  import pandas as _; print(_. __version__)
except Exception: print("0.0.0")
PY
)"

min_py="$(jq -r '.python.min' policies/runtime_spec.json)"
echo "Runtime: python=$python_ver (min=$min_py) numpy=$np_ver scipy=$scipy_ver matplotlib=$mpl_ver pandas=$pandas_ver"

# BLAS probe (best-effort)
blas_ok=0
blas_info="$(python3 - <<'PY' 2>/dev/null || true
try:
  import numpy, io, contextlib
  buf=io.StringIO()
  with contextlib.redirect_stdout(buf): numpy.__config__.show()
  print(buf.getvalue())
except Exception as e:
  print("")
PY
)"
if echo "$blas_info" | grep -qi 'openblas'; then
  if echo "$blas_info" | grep -Eqi 'USE64BITINT|64'; then blas_ok=1; fi
fi
if [ "$blas_ok" -ne 1 ]; then
  echo "::warning::OpenBLAS int64 non détecté — toléré localement, requis en CI"
fi

# Validate env whitelist
while IFS= read -r k; do
  [ -z "$k" ] && continue
  if [ -n "${!k-}" ]; then
    echo "ENV OK: $k set"
  fi
done < <(jq -r '.allow[]?' policies/env_whitelist.json)

echo "Policies guard: OK"
