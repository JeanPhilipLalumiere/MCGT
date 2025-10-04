#!/usr/bin/env bash
set -euo pipefail

# === PSX: empêcher la fermeture auto (hors CI) ===
WAIT_ON_EXIT="${WAIT_ON_EXIT:-1}"
psx_pause() {
  rc=$?
  echo
  if [[ $rc -eq 0 ]]; then
    echo "✅ Étape 4 — Terminé avec exit code: $rc"
  else
    echo "❌ Étape 4 — Terminé avec exit code: $rc"
  fi
  if [[ "${WAIT_ON_EXIT}" == "1" && -t 1 && -z "${CI:-}" ]]; then
    read -r -p "PSX — Appuie sur Entrée pour fermer cette fenêtre…" _
  fi
}
trap 'psx_pause' EXIT
# ================================================

cd "$(git rev-parse --show-toplevel)"

# S’auto-marquer exécutable si besoin (évite un futur échec du hook)
if [[ ! -x "$0" ]]; then
  chmod +x "$0"
  git add --chmod=+x "$0" || git add "$0"
fi

echo "==> (1) Patch ch07/ch08 (E402 + F821)"
python3 - <<'PY'
from pathlib import Path
import re

# --- ch07: generate_data_chapter07.py ---
p = Path("zz-scripts/chapter07/generate_data_chapter07.py")
s = p.read_text(encoding="utf-8")

# E402 : ajout # noqa: E402 sur l'import après sys.path bidouillé
s = re.sub(
    r'^(from\s+mcgt\.perturbations_scalaires\s+import\s+compute_cs2,\s*compute_delta_phi)(\s*)$',
    r'\1  # noqa: E402\2',
    s, flags=re.M
)

# F821 : rétablir cfg_lissage et utiliser la variable
# Remplace une ligne orpheline `cfg["lissage"]` par une vraie affectation
s = re.sub(
    r'(\n\s*if\s+[\'"]lissage[\'"]\s+in\s+cfg:\s*)(\n\s*)cfg\["lissage"\](\s*\n)',
    r'\1\2cfg_lissage = cfg["lissage"]\3',
    s, flags=re.M
)
# Si jamais l’affectation manque encore, l’insérer après le if
def ensure_cfg_lissage_assign(code: str) -> str:
    pat = re.compile(r'(^\s*if\s+[\'"]lissage[\'"]\s+in\s+cfg:\s*\n)', re.M)
    out = []
    last = 0
    for m in pat.finditer(code):
        out.append(code[last:m.end()])
        # Chercher si une assignation suit dans les 5 lignes
        tail = code[m.end():].splitlines(True)
        window = "".join(tail[:5])
        if re.search(r'^\s*cfg_lissage\s*=\s*cfg\["lissage"\]', window, re.M) is None:
            out.append("    cfg_lissage = cfg[\"lissage\"]\n")
        last = m.end()
    out.append(code[last:])
    return "".join(out)

s = ensure_cfg_lissage_assign(s)

p.write_text(s, encoding="utf-8")
print("patched:", p)

# --- ch07: launch_scalar_perturbations_solver.py ---
p = Path("zz-scripts/chapter07/launch_scalar_perturbations_solver.py")
s = p.read_text(encoding="utf-8")

# F821 : même cause, même remède
s = re.sub(
    r'(\n\s*if\s+[\'"]lissage[\'"]\s+in\s+cfg:\s*)(\n\s*)cfg\["lissage"\](\s*\n)',
    r'\1\2cfg_lissage = cfg["lissage"]\3',
    s, flags=re.M
)

def ensure_cfg_lissage_assign2(code: str) -> str:
    pat = re.compile(r'(^\s*if\s+[\'"]lissage[\'"]\s+in\s+cfg:\s*\n)', re.M)
    out = []
    last = 0
    for m in pat.finditer(code):
        out.append(code[last:m.end()])
        tail = code[m.end():].splitlines(True)
        window = "".join(tail[:5])
        if re.search(r'^\s*cfg_lissage\s*=\s*cfg\["lissage"\]', window, re.M) is None:
            out.append("    cfg_lissage = cfg[\"lissage\"]\n")
        last = m.end()
    out.append(code[last:])
    return "".join(out)

s = ensure_cfg_lissage_assign2(s)

p.write_text(s, encoding="utf-8")
print("patched:", p)

# --- ch08: generate_data_chapter08.py ---
p = Path("zz-scripts/chapter08/generate_data_chapter08.py")
s = p.read_text(encoding="utf-8")

# E402 : ajout # noqa: E402 sur import après sys.path bidouillé
s = re.sub(
    r'^(from\s+cosmo\s+import\s+DV,\s*Omega_lambda0,\s*Omega_m0,\s*distance_modulus)(\s*)$',
    r'\1  # noqa: E402\2',
    s, flags=re.M
)

p.write_text(s, encoding="utf-8")
print("patched:", p)
PY

echo "==> (2) Pré-commit (tolérant) + commit/push si diff"
pre-commit run --all-files || true
git add -A
if ! git diff --staged --quiet; then
  git commit -m "fix(ch07,ch08): add noqa E402 and restore cfg_lissage assignment to satisfy Ruff"
  git push
else
  echo "Aucun changement à committer."
fi
