#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] Script interrompu avec code $code";
  echo "[ASTUCE] Seul scripts/chapter02/plot_fig04_pipeline_diagram.py est touché (backup .bak_fix_except).";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== PATCH CH02 – Suppression des blocs 'except Exception' orphelins dans plot_fig04_pipeline_diagram.py =="

python - << 'PYEOF'
from pathlib import Path
import shutil

path = Path("scripts/chapter02/plot_fig04_pipeline_diagram.py")
backup = path.with_suffix(".py.bak_fix_except")
shutil.copy2(path, backup)
print(f"[BACKUP] {backup} créé")

lines = path.read_text().splitlines()
new_lines = []

skipping = False
indent_except = None

for line in lines:
    stripped = line.lstrip()
    indent = len(line) - len(stripped)

    # Début d'un bloc except Exception
    if not skipping and stripped.startswith("except Exception"):
        skipping = True
        indent_except = indent
        print("[PATCH] Bloc 'except Exception' détecté et supprimé.")
        continue

    if skipping:
        # Ligne vide -> on l'ignore aussi
        if stripped == "":
            continue
        # Si l'indentation reste plus grande que celle du except, on est dans le bloc -> on saute
        if indent > indent_except:
            continue
        # Sinon, on sort du bloc et on reprend le flux normal
        skipping = False
        indent_except = None
        # on tombe en dessous, donc on traite cette ligne normalement

    new_lines.append(line)

path.write_text("\n".join(new_lines) + "\n", encoding="utf-8")
print("[WRITE] Blocs 'except Exception' orphelins supprimés.")

PYEOF

echo
echo "Terminé (patch_ch02_remove_orphan_except)."
echo "Appuie sur Entrée pour revenir au shell..."
read -r _
