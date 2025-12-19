#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] Script interrompu avec code $code";
  echo "[ASTUCE] Seul zz-scripts/chapter06/generate_pdot_plateau_vs_z.py est touché, avec backup .bak_fix_cli.";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== PATCH CH06 – Fix argparse CLI dans generate_pdot_plateau_vs_z.py =="

python - << 'PYEOF'
from pathlib import Path
import shutil

path = Path("zz-scripts/chapter06/generate_pdot_plateau_vs_z.py")
if not path.exists():
    print("[ERROR] Fichier introuvable :", path)
    raise SystemExit(1)

backup = path.with_suffix(".py.bak_fix_cli")
shutil.copy2(path, backup)
print(f"[BACKUP] {backup} créé")

lines = path.read_text().splitlines()

target = (
    'parser.add_argument("-v", "--verbose", action="count", default=0, help="Verbosity cumulable (-v, -vv).")        '
    'parser.add_argument("--dpi", type=int, default=150, help="Figure DPI (default: 150)")'
)

new_lines = []
replaced = False

for line in lines:
    if target in line:
        indent = line[:len(line) - len(line.lstrip())]
        new_lines.append(
            f'{indent}parser.add_argument("-v", "--verbose", action="count", default=0, '
            'help="Verbosity cumulable (-v, -vv).")'
        )
        new_lines.append(
            f'{indent}parser.add_argument("--dpi", type=int, default=150, '
            'help="Figure DPI (default: 150)")'
        )
        replaced = True
    else:
        new_lines.append(line)

if not replaced:
    print("[WARN] Motif exact non trouvé dans le fichier. Aucun remplacement effectué.")
else:
    path.write_text("\n".join(new_lines) + "\n")
    print("[PATCH] Ligne verbose/dpi scindée en deux lignes correctement indentées.")

PYEOF

echo
echo "Terminé (patch_ch06_fix_generate_pdot_cli)."
