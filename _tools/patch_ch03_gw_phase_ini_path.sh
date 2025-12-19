#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] Script interrompu avec code $code";
  echo "[ASTUCE] Seul zz-scripts/chapter03/generate_data_chapter03.py est modifié, avec backup .bak_gw_ini.";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== PATCH CH03 – Default --config -> zz-configuration/gw_phase.ini =="

python - << 'PYEOF'
from pathlib import Path
import shutil

path = Path("zz-scripts/chapter03/generate_data_chapter03.py")
if not path.exists():
    print("[ERROR] Fichier introuvable :", path)
    raise SystemExit(1)

backup = path.with_suffix(".py.bak_gw_ini")
shutil.copy2(path, backup)
print(f"[BACKUP] {backup} créé")

text = path.read_text()

old = 'p.add_argument("--config", default="gw_phase.ini", help="INI avec [scan]")'
new = 'p.add_argument("--config", default="zz-configuration/gw_phase.ini", help="INI avec [scan]")'

if old not in text:
    print("[WARN] Motif exact non trouvé, aucune modification effectuée.")
else:
    text = text.replace(old, new, 1)
    path.write_text(text)
    print("[PATCH] Default --config mis à jour vers zz-configuration/gw_phase.ini")
PYEOF

echo
echo "Terminé (patch_ch03_gw_phase_ini_path)."
echo "Appuie sur Entrée pour revenir au shell..."
read -r _
