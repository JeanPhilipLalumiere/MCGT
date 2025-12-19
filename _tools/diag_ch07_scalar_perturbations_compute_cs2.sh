#!/usr/bin/env bash
set -Eeuo pipefail

echo "== DIAG CH07 – compute_cs2 dans mcgt.scalar_perturbations et import CH07 =="

python - << 'PYEOF'
from pathlib import Path

# --- Inspection du module mcgt/scalar_perturbations.py ---
path = Path("mcgt/scalar_perturbations.py")
if not path.exists():
    raise SystemExit("[ERROR] Fichier introuvable: " + str(path))

lines = path.read_text().splitlines()

found = False
for i, line in enumerate(lines, start=1):
    if "def compute_cs2" in line:
        if not found:
            print("[INFO] 'def compute_cs2' trouvé dans mcgt/scalar_perturbations.py :")
            found = True
        print(f"  - ligne {i}: {line}")

if not found:
    print("[WARN] Aucune définition de 'compute_cs2' trouvée dans mcgt/scalar_perturbations.py")

print()

# --- Inspection de l'import dans generate_data_chapter07.py ---
gpath = Path("zz-scripts/chapter07/generate_data_chapter07.py")
if not gpath.exists():
    raise SystemExit("[ERROR] Fichier introuvable: " + str(gpath))

glines = gpath.read_text().splitlines()
print("[INFO] Ligne(s) d'import mcgt.scalar_perturbations dans generate_data_chapter07.py :")
for i, line in enumerate(glines, start=1):
    if "mcgt.scalar_perturbations" in line:
        print(f"  - ligne {i}: {line}")
PYEOF
