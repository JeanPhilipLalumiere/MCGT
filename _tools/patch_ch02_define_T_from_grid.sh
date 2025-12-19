#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] Script interrompu avec code $code";
  echo "[ASTUCE] Seul zz-scripts/chapter02/generate_data_chapter02.py a été touché (avec backup).";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== PATCH CH02 v6 – Définition de T à partir de 02_P_vs_T_grid_data.dat =="

target="zz-scripts/chapter02/generate_data_chapter02.py"
backup="${target}.bak_v6_$(date -u +%Y%m%dT%H%M%SZ)"

cp "$target" "$backup"
echo "[BACKUP] $backup"

python - << 'PYEOF'
from pathlib import Path

path = Path("zz-scripts/chapter02/generate_data_chapter02.py")
text = path.read_text()

needle = 'Tp = _low["Tp"]'
if needle not in text:
    raise SystemExit("[ERREUR] Ligne 'Tp = _low[\"Tp\"]' introuvable, patch v6 non applicable.")

insertion = '''Tp = _low["Tp"]

# Grille temporelle T extraite du fichier P(T)
_grid_PT = np.loadtxt("zz-data/chapter02/02_P_vs_T_grid_data.dat")
T = _grid_PT[:, 0]
'''

new_text = text.replace(needle, insertion, 1)
path.write_text(new_text)
print("[PATCH] Ajout de la définition de T à partir de 02_P_vs_T_grid_data.dat juste après Tp.")
PYEOF

echo "[WRITE] zz-scripts/chapter02/generate_data_chapter02.py mis à jour (v6)."
echo "Terminé (patch_ch02_define_T_from_grid)."
