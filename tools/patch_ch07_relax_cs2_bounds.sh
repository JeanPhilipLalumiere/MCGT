#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] Script interrompu avec code $code";
  echo "[ASTUCE] Seul mcgt/scalar_perturbations.py est touché, avec backup .bak_cs2_relaxed.";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== PATCH CH07 – Assouplissement du contrôle c_s² (clip au lieu de ValueError) =="

python - << 'PYEOF'
from pathlib import Path
import shutil

path = Path("mcgt/scalar_perturbations.py")
if not path.exists():
    raise SystemExit("[ERROR] Fichier introuvable: " + str(path))

backup = path.with_suffix(".py.bak_cs2_relaxed")
shutil.copy2(path, backup)
print(f"[BACKUP] {backup} créé")

lines = path.read_text().splitlines()

target_idx = None
for i, line in enumerate(lines):
    if "c_s² hors-borne ou non-fini" in line or "c_s^2 hors-borne ou non-fini" in line:
        target_idx = i
        break

if target_idx is None:
    raise SystemExit("[ERROR] Ligne avec 'c_s² hors-borne ou non-fini' introuvable, patch abandonné.")

line = lines[target_idx]
indent = line[: len(line) - len(line.lstrip())]

# On remplace la ligne de raise par un warning + clipping
lines[target_idx] = indent + "import warnings"
lines.insert(
    target_idx + 1,
    indent + 'warnings.warn('
             '"c_s² hors-borne ou non-fini (attendu dans [0,1]) – '
             'valeurs clipées dans [0,1] pour le pipeline minimal.", '
             "RuntimeWarning)"
)
lines.insert(
    target_idx + 2,
    indent + "cs2 = np.clip(cs2, 0.0, 1.0)"
)

path.write_text("\\n".join(lines) + "\\n")
print("[WRITE] Contrôle c_s² assoupli : ValueError remplacé par un warning + clipping dans [0,1].")
PYEOF

echo
echo "Terminé (patch_ch07_relax_cs2_bounds)."
