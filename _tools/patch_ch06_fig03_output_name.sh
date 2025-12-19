#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] Script interrompu avec code $code";
  echo "[ASTUCE] Seul zz-scripts/chapter06/plot_fig03_delta_cls_relative.py est touché, avec backup .bak_fix_output.";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== PATCH CH06 – Normalisation du nom de sortie de fig_03 (delta_cls_relative) =="

python - << 'PYEOF'
from pathlib import Path
import shutil

path = Path("zz-scripts/chapter06/plot_fig03_delta_cls_relative.py")
if not path.exists():
    raise SystemExit("[ERROR] Fichier introuvable: " + str(path))

backup = path.with_suffix(".py.bak_fix_output")
shutil.copy2(path, backup)
print(f"[BACKUP] {backup} créé")

text = path.read_text()
replacements = 0

# 1) Remplacement direct du nom court par le nom canonique
if "fig_03_delta_cls_rel" in text:
    text = text.replace("fig_03_delta_cls_rel", "06_fig_03_delta_cls_relative")
    replacements += 1

# 2) Fallback ultra défensif : si jamais un nom générique traîne encore
if "delta_cls_relative.png" in text and "06_fig_03_delta_cls_relative.png" not in text:
    text = text.replace("delta_cls_relative.png", "06_fig_03_delta_cls_relative.png")
    replacements += 1

if not replacements:
    print("[WARN] Aucun motif de nom de fichier trouvé, aucun changement appliqué.")
else:
    path.write_text(text)
    print(f"[WRITE] Nom(s) de sortie mis à jour vers 06_fig_03_delta_cls_relative* ({replacements} remplacement(s)).")
PYEOF

echo
echo "Terminé (patch_ch06_fig03_output_name)."
