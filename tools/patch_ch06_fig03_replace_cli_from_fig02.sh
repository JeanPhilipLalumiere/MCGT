#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] Script interrompu avec code $code";
  echo "[ASTUCE] Seul scripts/06_early_growth_jwst/plot_fig03_delta_cls_relative.py est touché, avec backup .bak_replace_cli.";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== PATCH CH06 – Remplacement du bloc CLI de fig_03 par celui de fig_02 =="

python - << 'PYEOF'
from pathlib import Path
import shutil
import sys

path02 = Path("scripts/06_early_growth_jwst/plot_fig02_cls_lcdm_vs_mcgt.py")
path03 = Path("scripts/06_early_growth_jwst/plot_fig03_delta_cls_relative.py")

for p in (path02, path03):
    if not p.exists():
        print(f"[ERROR] Fichier introuvable: {p}")
        sys.exit(1)

backup = path03.with_suffix(".py.bak_replace_cli")
shutil.copy2(path03, backup)
print(f"[BACKUP] {backup} créé")

lines02 = path02.read_text().splitlines()
lines03 = path03.read_text().splitlines()

def find_main_guard(lines):
    for i, line in enumerate(lines):
        if line.strip().startswith('if __name__') and "__main__" in line:
            return i
    return None

idx02 = find_main_guard(lines02)
idx03 = find_main_guard(lines03)

if idx02 is None:
    print("[ERROR] Impossible de trouver le bloc 'if __name__ == \"__main__\"' dans fig_02.")
    sys.exit(1)

if idx03 is None:
    print("[WARN] Aucun bloc 'if __name__ == \"__main__\"' trouvé dans fig_03, on ajoutera le CLI à la fin.")
    pre03 = lines03
else:
    pre03 = lines03[:idx03]

cli_block = lines02[idx02:]
print(f"[INFO] Bloc CLI extrait de fig_02 à partir de la ligne {idx02+1} ({len(cli_block)} lignes).")

new_lines = pre03 + [""] + cli_block
path03.write_text("\n".join(new_lines) + "\n")
print("[WRITE] Bloc CLI de fig_03 remplacé par une version propre dérivée de fig_02.")
PYEOF

echo
echo "Terminé (patch_ch06_fig03_replace_cli_from_fig02)."
