#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] Script interrompu avec code $code";
  echo "[ASTUCE] Seul _tools/run_ch02_pipeline_minimal.sh est touché (backup .bak_addplots).";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== PATCH CH02 – Ajout des figures 02/03/04 dans run_ch02_pipeline_minimal.sh =="

python - << 'PYEOF'
from pathlib import Path
import shutil

path = Path("_tools/run_ch02_pipeline_minimal.sh")
backup = path.with_suffix(".sh.bak_addplots")
shutil.copy2(path, backup)
print(f"[BACKUP] {backup} créé")

text = path.read_text()

# Si déjà patché, on ne double pas
if "plot_fig02_calibration.py" in text:
    print("[INFO] Les appels à plot_fig02/03/04 sont déjà présents, aucun changement.")
else:
    marker = "[OK] CH02 pipeline minimal terminé sans erreur."
    if marker not in text:
        raise SystemExit("[ERREUR] Marqueur final introuvable dans run_ch02_pipeline_minimal.sh")

    block = """# --- Plots additionnels pour compléter le pipeline minimal ---
python zz-scripts/chapter02/plot_fig02_calibration.py
python zz-scripts/chapter02/plot_fig03_relative_errors.py
python zz-scripts/chapter02/plot_fig04_pipeline_diagram.py

"""

    text = text.replace(marker, block + marker)
    path.write_text(text)
    print("[WRITE] Appels à plot_fig02/03/04 ajoutés avant le message final.")

PYEOF

echo
echo "Terminé (patch_ch02_pipeline_add_missing_plots)."
echo "Appuie sur Entrée pour revenir au shell..."
read -r _
