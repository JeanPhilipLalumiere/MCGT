#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] Script interrompu avec code $code";
  echo "[ASTUCE] Seul zz-scripts/chapter02/plot_fig04_pipeline_diagram.py est touché, avec backup .bak_fix_cli.";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== PATCH CH02 – Fix argparse dans plot_fig04_pipeline_diagram.py =="

python - << 'PYEOF'
from pathlib import Path
import shutil

path = Path("zz-scripts/chapter02/plot_fig04_pipeline_diagram.py")
backup = path.with_suffix(".py.bak_fix_cli")
shutil.copy2(path, backup)
print(f"[BACKUP] {backup} créé")

text = path.read_text()

old = 'parser.add_argument("-v", "--verbose", action="count", default=0, help="Verbosity cumulable (-v, -vv).")        parser.add_argument("--dpi", type=int, default=150, help="Figure DPI (default: 150)")'

new = (
    'parser.add_argument("-v", "--verbose", action="count", default=0, '
    'help="Verbosity cumulable (-v, -vv).")\n'
    '    parser.add_argument("--dpi", type=int, default=150, '
    'help="Figure DPI (default: 150)")'
)

if old not in text:
    print("[WARN] Motif exact non trouvé dans le fichier. Aucun remplacement effectué.")
else:
    text = text.replace(old, new)
    path.write_text(text, encoding="utf-8")
    print("[WRITE] Ligne argparse corrigée (séparation -v / --dpi).")

PYEOF

echo
echo "Terminé (patch_ch02_fix_plot_fig04_cli)."
echo "Appuie sur Entrée pour revenir au shell..."
read -r _
