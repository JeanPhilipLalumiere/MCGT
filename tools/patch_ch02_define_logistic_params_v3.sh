#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] patch_ch02_define_logistic_params_v3 interrompu (code $code)";
  echo "[ASTUCE] Seul scripts/chapter02/generate_data_chapter02.py est touché, à partir du backup .bak_logistic_fix.";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== PATCH CH02 v3 – Paramètres logistiques globaux depuis 02_optimal_parameters.json =="

python - << 'PYEOF'
import pathlib

backup = pathlib.Path("scripts/chapter02/generate_data_chapter02.py.bak_logistic_fix")
target = pathlib.Path("scripts/chapter02/generate_data_chapter02.py")

if not backup.exists():
    raise SystemExit("[ERREUR] Backup .bak_logistic_fix introuvable – impossible de repartir propre.")

text = backup.read_text()

# 1) S’assurer qu’on a un import json dans le bloc d’imports
lines = text.splitlines()
idx = 0

# sauter shebang / commentaires / lignes vides initiales
while idx < len(lines) and (
    lines[idx].startswith("#!") or
    lines[idx].startswith("#") or
    lines[idx].strip() == "" or
    lines[idx].lstrip().startswith('"""') or
    lines[idx].lstrip().startswith("'''")
):
    idx += 1

# sauter les imports déjà présents
while idx < len(lines) and (lines[idx].lstrip().startswith("import ") or lines[idx].lstrip().startswith("from ")):
    idx += 1

if "import json" not in text:
    lines.insert(idx, "import json")
    text = "\n".join(lines)

# 2) Injecter le bloc global de chargement des paramètres logistiques
if "02_optimal_parameters.json" in text:
    # déjà présent, on ne fait rien
    new_text = text
else:
    needle = "a_log = a0 + (ainf - a0) / (1 + np.exp(-(T - Tc) / Delta))"
    if needle not in text:
        raise SystemExit("[ERREUR] Ligne 'a_log = ...' introuvable dans le backup – patch annulé.")

    block = '''
with open("assets/zz-data/chapter02/02_optimal_parameters.json") as f:
    _params = json.load(f)
a0 = _params["a0"]
ainf = _params["ainf"]
Tc = _params["Tc"]
Delta = _params["Delta"]
'''.lstrip("\n")

    # On insère ce bloc juste avant la première occurrence de 'a_log = ...'
    new_text = text.replace(needle, block + "\n" + needle, 1)

# 3) Sauvegarder l’état actuel (cassé) avant d’écraser
if target.exists():
    bad_backup = target.with_suffix(target.suffix + ".bak_indent_v3")
    bad_backup.write_text(target.read_text())
    print(f"[BACKUP] {bad_backup}")

target.write_text(new_text)
print(f"[WRITE] {target} réécrit à partir de {backup} avec bloc global pour a0, ainf, Tc, Delta.")
PYEOF
