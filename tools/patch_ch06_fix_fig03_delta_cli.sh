#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] Script interrompu avec code $code";
  echo "[ASTUCE] Seul scripts/chapter06/plot_fig03_delta_cls_relative.py est touché, avec backup .bak_fix_cli.";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== PATCH CH06 – Fix argparse CLI dans plot_fig03_delta_cls_relative.py =="

python - << 'PYEOF'
from pathlib import Path
import shutil, sys

path = Path("scripts/chapter06/plot_fig03_delta_cls_relative.py")
if not path.exists():
    print("[ERROR] Fichier introuvable:", path)
    sys.exit(1)

backup = path.with_suffix(".py.bak_fix_cli")
shutil.copy2(path, backup)
print(f"[BACKUP] {backup} créé")

lines = path.read_text().splitlines()
new_lines = []
patched = False

for line in lines:
    if ('parser.add_argument("-v", "--verbose"' in line
        and 'parser.add_argument("--dpi"' in line):
        indent = line[:len(line) - len(line.lstrip())]
        new_lines.append(
            indent
            + 'parser.add_argument("-v", "--verbose", action="count", '
              'default=0, help="Verbosity cumulable (-v, -vv).")'
        )
        new_lines.append(
            indent
            + 'parser.add_argument("--dpi", type=int, default=150, '
              'help="Figure DPI (default: 150)")'
        )
        patched = True
    else:
        new_lines.append(line)

if not patched:
    print("[WARN] Ligne combinant -v et --dpi non trouvée, aucun remplacement effectué.")
else:
    path.write_text("\n".join(new_lines) + "\n")
    print("[PATCH] Ligne verbose/dpi scindée en deux lignes correctement indentées.")
PYEOF

echo
echo "Terminé (patch_ch06_fix_fig03_delta_cli)."
