#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] Script interrompu avec code $code";
  echo "[ASTUCE] Seul zz-scripts/chapter06/generate_data_chapter06.py est touché, avec backup .bak_fix_cli.";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== PATCH CH06 – Fix argparse CLI dans generate_data_chapter06.py =="
echo

python - << 'PYEOF'
from pathlib import Path
import shutil

path = Path("zz-scripts/chapter06/generate_data_chapter06.py")
if not path.exists():
    print("[ERROR] Fichier introuvable :", path)
    raise SystemExit(1)

backup = path.with_suffix(".py.bak_fix_cli")
shutil.copy2(path, backup)
print(f"[BACKUP] {backup} créé")

lines = path.read_text().splitlines()
modified = False

for i, line in enumerate(lines):
    if "Verbosity cumulable" in line and "Figure DPI" in line:
        indent = line[: len(line) - len(line.lstrip())]
        print(f"[INFO] Ligne CLI problématique trouvée à l’index {i+1}")
        lines[i] = (
            f'{indent}parser.add_argument("-v", "--verbose", action="count", '
            f'default=0, help="Verbosity cumulable (-v, -vv).")'
        )
        lines.insert(
            i + 1,
            f'{indent}parser.add_argument("--dpi", type=int, default=150, '
            f'help="Figure DPI (default: 150)")',
        )
        modified = True
        break

if not modified:
    print("[WARN] Aucune ligne contenant à la fois 'Verbosity cumulable' et 'Figure DPI' n’a été trouvée.")
else:
    path.write_text("\n".join(lines) + "\n")
    print("[PATCH] Ligne verbose/dpi séparée en deux lignes correctement indentées.")

PYEOF

echo
echo "Terminé (patch_ch06_fix_cli_args)."
