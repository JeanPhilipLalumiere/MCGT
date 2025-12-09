#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] Script interrompu avec code $code";
  echo "[ASTUCE] Seul zz-scripts/chapter04/plot_fig04_relative_deviations.py est touché, avec backup .bak_fix_indent_for.";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== PATCH CH04 – Réindentation du bloc if/os.path.isfile(path) dans plot_fig04_relative_deviations.py =="

python - << 'PYEOF'
from pathlib import Path
import shutil, sys

path = Path("zz-scripts/chapter04/plot_fig04_relative_deviations.py")
if not path.exists():
    sys.exit("[ERROR] Fichier zz-scripts/chapter04/plot_fig04_relative_deviations.py introuvable.")

backup = path.with_suffix(".py.bak_fix_indent_for")
shutil.copy2(path, backup)
print(f"[BACKUP] {backup} créé")

lines = path.read_text().splitlines()

target = "if os.path.isfile(path):"
idx = None
for i, line in enumerate(lines):
    if target in line:
        idx = i
        break

if idx is None:
    sys.exit("[ERROR] Ligne contenant 'if os.path.isfile(path):' non trouvée, patch abandonné.")

if idx == 0:
    sys.exit("[ERROR] Aucune ligne avant 'if os.path.isfile(path):' pour récupérer l'indentation du for.")

for_line = lines[idx - 1]
if "for " not in for_line or " in " not in for_line:
    print("[WARN] Ligne précédente ne semble pas être un 'for ... in ...', réindentation quand même.", file=sys.stderr)

indent_for = len(for_line) - len(for_line.lstrip(" "))

# Déterminer la fin du bloc à réindenter : on s'arrête à la première ligne
# vide ou à une ligne dont l'indentation revient au niveau du 'for' ou moins.
start = idx
end = start
for k in range(start, len(lines)):
    stripped = lines[k].lstrip(" ")
    if stripped == "":
        end = k - 1
        break
    indent_k = len(lines[k]) - len(stripped)
    if k > start and indent_k <= indent_for:
        end = k - 1
        break
else:
    end = len(lines) - 1

print(f"[INFO] Réindentation des lignes {start+1} à {end+1} (inclus).")

new_lines = []
for j, line in enumerate(lines):
    if start <= j <= end:
        stripped = line.lstrip(" ")
        new_line = " " * (indent_for + 4) + stripped
        new_lines.append(new_line)
    else:
        new_lines.append(line)

path.write_text("\n".join(new_lines) + "\n")
print("[WRITE] Indentation du bloc 'if os.path.isfile(path):' corrigée.")
PYEOF

echo
echo "Terminé (patch_ch04_fix_plot_fig04_indent_for_block)."
echo "Appuie sur Entrée pour revenir au shell..."
read -r _
