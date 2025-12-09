#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] Script interrompu avec code $code";
  echo "[ASTUCE] Seul zz-scripts/chapter04/plot_fig04_relative_deviations.py est touché, avec backup .bak_fix_if_block.";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== PATCH CH04 – Réécriture du bloc for/if pour charger 04_dimensionless_invariants.csv =="

python - << 'PYEOF'
from pathlib import Path
import shutil, sys

path = Path("zz-scripts/chapter04/plot_fig04_relative_deviations.py")
if not path.exists():
    sys.exit("[ERROR] Fichier zz-scripts/chapter04/plot_fig04_relative_deviations.py introuvable.")

backup = path.with_suffix(".py.bak_fix_if_block")
shutil.copy2(path, backup)
print(f"[BACKUP] {backup} créé")

lines = path.read_text().splitlines()

# On cherche la ligne contenant 'for path in' (bloc de sélection du CSV)
start = None
for i, line in enumerate(lines):
    if "for path in" in line and "candidates" in line:
        start = i
        break

if start is None:
    sys.exit("[ERROR] Aucune ligne 'for path in candidates' trouvée, patch abandonné.")

# Indentation du 'for'
indent_for = len(lines[start]) - len(lines[start].lstrip(" "))

# On cherche la fin du bloc : on s'arrête à la première ligne vide
# ou à la prochaine 'def ' au niveau racine.
end = len(lines) - 1
for k in range(start + 1, len(lines)):
    stripped = lines[k].strip()
    if stripped == "":
        end = k - 1
        break
    if stripped.startswith("def "):
        end = k - 1
        break

print(f"[INFO] Bloc for/if à remplacer : lignes {start+1} à {end+1}.")

# Nouveau bloc propre
base_indent = " " * indent_for
new_block = [
    f"{base_indent}for path in candidates:",
    f"{base_indent}    if os.path.isfile(path):",
    f"{base_indent}        df = pd.read_csv(path)",
    f"{base_indent}        break",
    f"{base_indent}else:",
    f'{base_indent}    raise FileNotFoundError('
    f'"Impossible de trouver 04_dimensionless_invariants.csv dans les chemins candidats.")',
]

new_lines = []
for j, line in enumerate(lines):
    if j < start or j > end:
        new_lines.append(line)
    elif j == start:
        # Injecte le bloc réécrit à la place de l'ancien
        new_lines.extend(new_block)

path.write_text("\n".join(new_lines) + "\n")
print("[WRITE] Bloc for/if remplacé par une version propre et indentée.")
PYEOF

echo
echo "Terminé (patch_ch04_fix_plot_fig04_if_block)."
echo "Appuie sur Entrée pour revenir au shell..."
read -r _
