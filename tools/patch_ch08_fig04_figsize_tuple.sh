#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] Script interrompu avec code $code";
  echo "[ASTUCE] Seul scripts/chapter08/plot_fig04_chi2_heatmap.py est touché, avec backup .bak_fix_figsize.";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== PATCH CH08 – fig_04 : correction figsize tuple =="

python - << 'PYEOF'
from pathlib import Path
import shutil
import sys

path = Path("scripts/chapter08/plot_fig04_chi2_heatmap.py")
if not path.exists():
    sys.exit(f"[ERROR] Fichier introuvable: {path}")

backup = path.with_suffix(".py.bak_fix_figsize")
shutil.copy2(path, backup)
print(f"[BACKUP] {backup} créé")

text = path.read_text()

replacements = 0

if "fig, ax = plt.subplots(figsize=(7.5))" in text:
    text = text.replace(
        "fig, ax = plt.subplots(figsize=(7.5))",
        "fig, ax = plt.subplots(figsize=(7.5, 5.0))",
    )
    replacements += 1

if "figsize=(7.5)" in text:
    text = text.replace("figsize=(7.5)", "figsize=(7.5, 5.0)")
    replacements += 1

if "figsize = (7.5)" in text:
    text = text.replace("figsize = (7.5)", "figsize=(7.5, 5.0)")
    replacements += 1

if replacements == 0:
    sys.exit("[ERROR] Aucun motif figsize=(7.5) trouvé dans plot_fig04_chi2_heatmap.py")

path.write_text(text)
print(f"[WRITE] figsize mis à jour vers (7.5, 5.0) ({replacements} remplacement(s)).")
PYEOF

echo
echo "Terminé (patch_ch08_fig04_figsize_tuple)."
