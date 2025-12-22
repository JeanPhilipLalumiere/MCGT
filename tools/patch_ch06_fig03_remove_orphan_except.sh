#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] Script interrompu avec code $code";
  echo "[ASTUCE] Seul scripts/06_early_growth_jwst/plot_fig03_delta_cls_relative.py est touché, avec backup .bak_rm_except.";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== PATCH CH06 – Suppression des blocs 'except' orphelins dans plot_fig03_delta_cls_relative.py =="

python - << 'PYEOF'
from pathlib import Path
import shutil
import sys

path = Path("scripts/06_early_growth_jwst/plot_fig03_delta_cls_relative.py")
if not path.exists():
    print("[ERROR] Fichier introuvable:", path)
    sys.exit(1)

backup = path.with_suffix(".py.bak_rm_except")
shutil.copy2(path, backup)
print(f"[BACKUP] {backup} créé")

lines = path.read_text().splitlines()

def indent(line: str) -> int:
    return len(line) - len(line.lstrip(" \t"))

new_lines = []
i = 0
n = len(lines)

while i < n:
    line = lines[i]
    stripped = line.lstrip()
    if stripped.startswith("except "):
        base_indent = indent(line)
        print(f"[PATCH] Suppression d'un bloc 'except' à la ligne {i+1}")
        i += 1
        # sauter tout le bloc indenté qui suit
        while i < n:
            l2 = lines[i]
            s2 = l2.lstrip()
            ind2 = indent(l2)
            if s2 == "":
                i += 1
                continue
            if ind2 <= base_indent:
                break
            i += 1
        continue
    new_lines.append(line)
    i += 1

path.write_text("\n".join(new_lines) + "\n")
print("[WRITE] Blocs 'except ...' orphelins supprimés.")
PYEOF

echo
echo "Terminé (patch_ch06_fig03_remove_orphan_except)."
