#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] Script interrompu avec code $code";
  echo "[ASTUCE] Seul zz-scripts/chapter04/plot_fig04_relative_deviations.py est touché, avec backup .bak_fix_if_indent.";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== PATCH CH04 – Réindentation du bloc if os.path.isfile(path) =="

python - << 'PYEOF'
from pathlib import Path
import shutil, sys

path = Path("zz-scripts/chapter04/plot_fig04_relative_deviations.py")
if not path.exists():
    sys.exit("[ERROR] Fichier zz-scripts/chapter04/plot_fig04_relative_deviations.py introuvable.")

backup = path.with_suffix(".py.bak_fix_if_indent")
shutil.copy2(path, backup)
print(f"[BACKUP] {backup} créé")

lines = path.read_text().splitlines()

idx_if = None
for i, line in enumerate(lines):
    if "if os.path.isfile(path):" in line:
        idx_if = i
        break

if idx_if is None:
    sys.exit("[ERROR] Aucune ligne 'if os.path.isfile(path):' trouvée, patch abandonné.")

indent_if = len(lines[idx_if]) - len(lines[idx_if].lstrip(" "))
body_indent = indent_if + 4

print(f"[INFO] if os.path.isfile(path): à la ligne {idx_if+1}, indent_if={indent_if}, body_indent={body_indent}")

# On réindente les lignes qui suivent, jusqu'à un else: ou une ligne vide ou une nouvelle def
for j in range(idx_if + 1, len(lines)):
    stripped = lines[j].strip()
    if stripped == "":
        break
    if stripped.startswith("else:"):
        break
    if stripped.startswith("def "):
        break
    # On ne touche que les lignes qui sont censées être dans le bloc if
    new_line = " " * body_indent + stripped
    lines[j] = new_line

path.write_text("\n".join(lines) + "\n")
print("[WRITE] Bloc suivant le if os.path.isfile(path) réindenté.")
PYEOF

echo
echo "Terminé (patch_ch04_fix_plot_fig04_if_indent_only)."
echo "Appuie sur Entrée pour revenir au shell..."
read -r _
