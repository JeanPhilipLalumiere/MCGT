#!/usr/bin/env bash
# (Option A) Pour utiliser la pause PSX factorisée :
# . tools/lib_psx.sh
# psx_install "step2c_fix_remaining_errors.sh"
set -euo pipefail

WAIT_ON_EXIT="${WAIT_ON_EXIT:-1}"
psx() {
  rc=$?
  echo
  if [[ $rc -eq 0 ]]; then
    echo "✅ Étape 2c — Terminé avec exit code: $rc"
  else
    echo "❌ Étape 2c — Terminé avec exit code: $rc"
  fi
  if [[ "${WAIT_ON_EXIT}" == "1" && -t 1 && -z "${CI:-}" ]]; then
    read -r -p "PSX — Appuie sur Entrée pour fermer cette fenêtre…" _
  fi
}
trap 'psx' EXIT

cd "$(git rev-parse --show-toplevel)"

echo "==> (1) mcgt/constants.py — définir constantes + simplifier conversion (F823)"
python3 - <<'PY'
from pathlib import Path
import re

p = Path("mcgt/constants.py")
s = p.read_text(encoding="utf-8")

# 1) Retire auto-import parasite s'il existe (vu précédemment)
s = s.replace("from mcgt.constants import C_LIGHT_M_S\n", "")

# 2) Injecte trois constantes si manquantes (après la docstring si possible)
if "METER_PER_PC" not in s:
    doc_end = 0
    m = re.search(r'"""[\s\S]*?"""', s)
    if m:
        doc_end = m.end()
    inject = (
        "\nMETER_PER_PC = 3.085677581491367e16  # m\n"
        "METER_PER_KPC = METER_PER_PC * 1_000.0\n"
        "METER_PER_MPC = METER_PER_PC * 1_000_000.0\n"
    )
    s = s[:doc_end] + inject + s[doc_end:]

# 3) Simplifie km_s_per_Mpc_to_per_s : plus de try/except NameError
s = re.sub(
    r"def\s+km_s_per_Mpc_to_per_s\s*\(\s*x:\s*float\s*\)\s*->\s*float\s*:\s*[\s\S]*?(?=\n\w)",
    "def km_s_per_Mpc_to_per_s(x: float) -> float:\n"
    "    return x * 1000.0 / METER_PER_MPC\n\n",
    s,
    count=1,
)

p.write_text(s, encoding="utf-8")
print("constants.py : patch appliqué.")
PY

echo "==> (2) ch07 — rétablir cfg_lissage et E402 ciblés"
# a) Remet l'affectation manquante (ligne isolée « cfg['lissage'] » -> « cfg_lissage = cfg['lissage'] »)
sed -i "s/^[[:space:]]*cfg\\['lissage'\\][[:space:]]*$/    cfg_lissage = cfg['lissage']/" \
  zz-scripts/chapter07/generate_data_chapter07.py \
  zz-scripts/chapter07/launch_scalar_perturbations_solver.py

# b) Si jamais l'ancienne écriture « l = cfg['lissage'] » subsiste quelque part, on la renomme proprement
sed -i "s/\\bl = cfg\\['lissage'\\]/cfg_lissage = cfg['lissage']/" \
  zz-scripts/chapter07/generate_data_chapter07.py \
  zz-scripts/chapter07/launch_scalar_perturbations_solver.py

# c) Ajoute noqa: E402 sur imports tardifs
sed -i "s@^\\(from mcgt\\.perturbations_scalaires .*\\)@\\1  # noqa: E402@" \
  zz-scripts/chapter07/generate_data_chapter07.py
sed -i "s@^\\(from pathlib import Path\\)@\\1  # noqa: E402@" \
  zz-scripts/chapter07/tests/test_chapter07.py
sed -i "s@^\\(import pandas as pd\\)@\\1  # noqa: E402@" \
  zz-scripts/chapter07/tests/test_chapter07.py
sed -i "s@^\\(import pytest\\)@\\1  # noqa: E402@" \
  zz-scripts/chapter07/tests/test_chapter07.py

echo "==> (3) ch08 — noqa: E402 sur imports après sys.path bidouillé"
sed -i "s@^\\(from cosmo import DV, Omega_lambda0, Omega_m0, distance_modulus\\)@\\1  # noqa: E402@" \
  zz-scripts/chapter08/generate_data_chapter08.py
sed -i "s@^\\(from cosmo import DV, distance_modulus\\)@\\1  # noqa: E402@" \
  zz-scripts/chapter08/plot_fig06_normalized_residuals_distribution.py

echo "==> (4) Ruff + pre-commit (tolérant) puis commit si diff"
pre-commit run --all-files || true
git add -A
if ! git diff --staged --quiet; then
  git commit -m "lint: minimal fixes (constants F823 + ch07/ch08 E402/F821)"
  git push
else
  echo "Aucun changement à committer."
fi
