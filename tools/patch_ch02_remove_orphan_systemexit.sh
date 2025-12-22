#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] Script interrompu avec code $code";
  echo "[ASTUCE] Seul scripts/02_primordial_spectrum/plot_fig04_pipeline_diagram.py est touché (backup .bak_fix_systemexit).";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== PATCH CH02 – Suppression des blocs 'except SystemExit' orphelins dans plot_fig04_pipeline_diagram.py =="

python - << 'PYEOF'
from pathlib import Path
import shutil

path = Path("scripts/02_primordial_spectrum/plot_fig04_pipeline_diagram.py")
backup = path.with_suffix(".py.bak_fix_systemexit")
shutil.copy2(path, backup)
print(f"[BACKUP] {backup} créé")

lines = path.read_text().splitlines()
new_lines = []

skipping = False
indent_except = None

for line in lines:
    stripped = line.lstrip()
    indent = len(line) - len(stripped)

    # Début d'un bloc "except SystemExit:"
    if not skipping and stripped.startswith("except SystemExit"):
        skipping = True
        indent_except = indent
        print("[PATCH] Bloc 'except SystemExit' détecté et supprimé.")
        continue

    if skipping:
        # On reste en mode skip tant que l'indentation est strictement plus grande
        # que celle du "except" (corps du bloc).
        if stripped == "":
            continue
        if indent > indent_except:
            continue
        # On sort du bloc : cette ligne fait maintenant partie du flux normal
        skipping = False
        indent_except = None

    new_lines.append(line)

path.write_text("\n".join(new_lines) + "\n", encoding="utf-8")
print("[WRITE] Blocs 'except SystemExit' orphelins supprimés.")

# Petit check : afficher les lignes qui contiennent encore "except"
print("\n[INFO] Vérification des 'except' restants :")
for i, l in enumerate(new_lines, start=1):
    if "except" in l:
        print(f"{i:3}: {l}")

PYEOF

echo
echo "Terminé (patch_ch02_remove_orphan_systemexit)."
echo "Appuie sur Entrée pour revenir au shell..."
read -r _
