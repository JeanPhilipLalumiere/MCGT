#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] Script interrompu avec code $code";
  echo "[ASTUCE] Seul zz-scripts/chapter02/plot_fig04_pipeline_diagram.py est touché (backup .bak_fix_indent).";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== PATCH CH02 – Normalisation de l'indentation du bloc argparse de plot_fig04 =="

python - << 'PYEOF'
from pathlib import Path
import shutil

path = Path("zz-scripts/chapter02/plot_fig04_pipeline_diagram.py")
backup = path.with_suffix(".py.bak_fix_indent")
shutil.copy2(path, backup)
print(f"[BACKUP] {backup} créé")

lines = path.read_text().splitlines()

targets = (
    'parser.add_argument("--dpi"',
    'parser.add_argument("--format"',
    'parser.add_argument("--transparent"',
)

new_lines = []
for line in lines:
    stripped = line.lstrip()
    if any(stripped.startswith(t) for t in targets):
        # 8 espaces pour être au même niveau que les autres options déjà indentées
        new_lines.append("        " + stripped)
    else:
        new_lines.append(line)

path.write_text("\n".join(new_lines) + "\n", encoding="utf-8")
print("[WRITE] Indentation normalisée pour --dpi / --format / --transparent.")

PYEOF

echo
echo "Terminé (patch_ch02_fix_plot_fig04_indent)."
echo "Appuie sur Entrée pour revenir au shell..."
read -r _
