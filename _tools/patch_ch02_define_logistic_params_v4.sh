#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] patch_ch02_define_logistic_params_v4 interrompu (code $code)";
  echo "[ASTUCE] Seul zz-scripts/chapter02/generate_data_chapter02.py est touché, à partir du backup .bak_logistic_fix.";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== PATCH CH02 v4 – Paramètres logistiques globaux insérés après les imports =="

python - << 'PYEOF'
import pathlib

backup = pathlib.Path("zz-scripts/chapter02/generate_data_chapter02.py.bak_logistic_fix")
target = pathlib.Path("zz-scripts/chapter02/generate_data_chapter02.py")

if not backup.exists():
    raise SystemExit("[ERREUR] Backup .bak_logistic_fix introuvable – impossible de repartir propre.")

src = backup.read_text()
lines = src.splitlines()

i = 0

# 1) Sauter shebang et commentaires / lignes vides du tout début
while i < len(lines) and (
    lines[i].startswith("#!") or
    lines[i].strip() == "" or
    lines[i].lstrip().startswith("#")
):
    i += 1

# 2) Sauter un éventuel docstring de module
if i < len(lines) and (lines[i].lstrip().startswith('"""') or lines[i].lstrip().startswith("'''")):
    quote = lines[i].lstrip()[:3]
    i += 1
    while i < len(lines) and quote not in lines[i]:
        i += 1
    if i < len(lines):
        i += 1  # sauter la ligne qui ferme le docstring

# 3) Zone d'import
import_start = i
found_json = False
while i < len(lines) and (
    lines[i].lstrip().startswith("import ") or
    lines[i].lstrip().startswith("from ")
):
    if "import json" in lines[i]:
        found_json = True
    i += 1
import_end = i

# 3bis) Ajouter import json si absent
if not found_json:
    lines.insert(import_end, "import json")
    import_end += 1

# 4) Bloc global: lecture de 02_optimal_parameters.json
block_lines = [
    'with open("zz-data/chapter02/02_optimal_parameters.json") as f:',
    '    _params = json.load(f)',
    'a0 = _params["a0"]',
    'ainf = _params["ainf"]',
    'Tc = _params["Tc"]',
    'Delta = _params["Delta"]',
    ''
]

for offset, ln in enumerate(block_lines):
    lines.insert(import_end + offset, ln)

new_text = "\n".join(lines) + "\n"

# 5) Sauvegarder l'état actuel (cassé) avant d'écraser
if target.exists():
    bad_backup = target.with_suffix(target.suffix + ".bak_before_v4")
    bad_backup.write_text(target.read_text())
    print(f"[BACKUP] {bad_backup}")

target.write_text(new_text)
print(f"[WRITE] {target} réécrit à partir de {backup} avec bloc global logistique.")
PYEOF
