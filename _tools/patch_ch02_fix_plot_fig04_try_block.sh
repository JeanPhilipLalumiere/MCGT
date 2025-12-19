#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] Script interrompu avec code $code";
  echo "[ASTUCE] Seul zz-scripts/chapter02/plot_fig04_pipeline_diagram.py est touché (backup .bak_fix_try).";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== PATCH CH02 – Nettoyage du bloc try dans plot_fig04_pipeline_diagram.py =="

python - << 'PYEOF'
from pathlib import Path
import shutil

path = Path("zz-scripts/chapter02/plot_fig04_pipeline_diagram.py")
backup = path.with_suffix(".py.bak_fix_try")
shutil.copy2(path, backup)
print(f"[BACKUP] {backup} créé")

lines = path.read_text().splitlines()
new_lines = []

inside_cli = False

for line in lines:
    stripped = line.lstrip()

    # Détection du début de _mcgt_cli_seed
    if "def _mcgt_cli_seed" in line:
        inside_cli = True
        new_lines.append(line)
        continue

    # On reste dans le mode "inside_cli" jusqu'à la fin du fichier (assez sûr ici)
    if inside_cli:
        # On supprime le 'try:' orphelin
        if stripped == "try:":
            print("[PATCH] Ligne 'try:' supprimée dans _mcgt_cli_seed.")
            continue

        # Normalisation d'indentation pour ces lignes clés
        if stripped.startswith("os.makedirs(") \
           or stripped.startswith('os.environ["MCGT_OUTDIR"]') \
           or stripped.startswith("import matplotlib as mpl") \
           or stripped.startswith('mpl.rcParams["savefig.dpi"]'):
            new_lines.append("        " + stripped)
            continue

    new_lines.append(line)

path.write_text("\n".join(new_lines) + "\n", encoding="utf-8")
print("[WRITE] Bloc try nettoyé et indentation normalisée pour os.makedirs / os.environ / mpl.*")

PYEOF

echo
echo "Terminé (patch_ch02_fix_plot_fig04_try_block)."
echo "Appuie sur Entrée pour revenir au shell..."
read -r _
