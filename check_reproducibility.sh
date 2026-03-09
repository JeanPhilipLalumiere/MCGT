#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="${ROOT_DIR}/.repro-venv"
TMP_DIR="${ROOT_DIR}/.repro-tmp"
MPLCONFIG_DIR="${ROOT_DIR}/.repro-mplconfig"

cd "${ROOT_DIR}"

echo "[info] Root: ${ROOT_DIR}"
echo "[info] Recreating virtualenv at ${VENV_DIR}"
rm -rf "${VENV_DIR}"
rm -rf "${TMP_DIR}"
rm -rf "${MPLCONFIG_DIR}"
mkdir -p "${TMP_DIR}"
mkdir -p "${MPLCONFIG_DIR}"
python3 -m venv --system-site-packages "${VENV_DIR}"

# shellcheck disable=SC1091
source "${VENV_DIR}/bin/activate"

export MCGT_USE_TEX=0
export MPLBACKEND=Agg
export PYTHONUNBUFFERED=1
export TMPDIR="${TMP_DIR}"
export TMP="${TMP_DIR}"
export TEMP="${TMP_DIR}"
export MPLCONFIGDIR="${MPLCONFIG_DIR}"
export XDG_CACHE_HOME="${MPLCONFIG_DIR}"
export PYTHONPATH="${ROOT_DIR}/src:${ROOT_DIR}:${PYTHONPATH:-}"

echo "[info] Validating locked dependency set from requirements.lock"
python -m pip install --no-index -r requirements.lock

echo "[info] Scanning code for hard-coded user paths"
if rg -n \
  --glob '*.py' \
  --glob '*.sh' \
  --glob '*.md' \
  --glob '*.tex' \
  --glob '*.yml' \
  --glob '*.yaml' \
  --glob '*.json' \
  --glob '!check_reproducibility.sh' \
  --glob '!tests/test_no_hardcoded_user_paths.py' \
  '/home/|/Users/|[A-Za-z]:\\\\Users\\\\' \
  scripts mcgt tests tools docs .github README.md REPRODUCIBILITY.md manuscript assets/zz-manifests .; then
  echo "[fail] Hard-coded user path(s) detected"
  exit 1
fi

run_phase() {
  local label="$1"
  shift
  echo "[info] ${label}"
  "$@"
}

run_phase "Final verdict reproduction" bash reproduce_final_verdict.sh
run_phase "Phase 1 smoke" python scripts/stability_audit_ch01_ch03.py
run_phase "Phase 2 smoke" python scripts/phase2_observational_report.py
run_phase "Phase 3 smoke" python scripts/phase3_lss_geometry_report.py
run_phase "Phase 4 smoke" python scripts/phase4_global_verdict.py
run_phase "Phase 4 consistency" python scripts/verify_table_consistency.py
run_phase "Phase 5 smoke" python scripts/phase5_geometric_solution.py

test -f output/ptmg_predictions_z0_to_z20.csv
test -f output/ptmg_corner_plot.pdf

echo "[pass] Cold-run reproducibility checks completed successfully."
