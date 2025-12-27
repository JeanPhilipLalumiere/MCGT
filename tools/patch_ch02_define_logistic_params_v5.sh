#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] Script interrompu avec code $code";
  echo "[ASTUCE] Seul scripts/02_primordial_spectrum/generate_data_chapter02.py a été touché (avec backup).";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== PATCH CH02 v5 – Paramètres logistiques mappés sur segments['low'] =="

target="scripts/02_primordial_spectrum/generate_data_chapter02.py"
backup="${target}.bak_v5_$(date -u +%Y%m%dT%H%M%SZ)"

cp "$target" "$backup"
echo "[BACKUP] $backup"

python - << 'PYEOF'
import pathlib

path = pathlib.Path("scripts/02_primordial_spectrum/generate_data_chapter02.py")
text = path.read_text()

needle = 'with open("assets/zz-data/02_primordial_spectrum/02_optimal_parameters.json") as f:'
if needle not in text:
    raise SystemExit("[ERREUR] Bloc de chargement 02_optimal_parameters.json introuvable dans generate_data_chapter02.py")

lines = text.splitlines()

start = None
for i, line in enumerate(lines):
    if needle in line:
        start = i
        break

if start is None:
    raise SystemExit("[ERREUR] Impossible de localiser la ligne contenant 02_optimal_parameters.json")

end = start + 1
# On considère que le bloc actuel va jusqu'à la prochaine ligne vide
while end < len(lines) and lines[end].strip() != "":
    end += 1

new_block = [
'with open("assets/zz-data/02_primordial_spectrum/02_optimal_parameters.json") as f:',
'    _params = json.load(f)',
'',
'_segments = _params["segments"]',
'_low = _segments["low"]',
'',
'# Pour le pipeline minimal, on utilise le segment \"low\"',
'a0 = _low["alpha0"]',
'ainf = _low["alpha_inf"]',
'Tc = _low["Tc"]',
'Delta = _low["Delta"]',
'Tp = _low["Tp"]',
'',
]

new_lines = lines[:start] + new_block + lines[end:]
path.write_text("\n".join(new_lines))
print("[PATCH] Bloc de chargement des paramètres logistiques réécrit pour utiliser segments[\"low\"].")
PYEOF

echo "[WRITE] scripts/02_primordial_spectrum/generate_data_chapter02.py mis à jour (v5)."
echo "Terminé (patch_ch02_define_logistic_params_v5)."
