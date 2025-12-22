#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] patch_ch02_define_logistic_params_v2 interrompu (code $code)";
  echo "[ASTUCE] Seul scripts/02_primordial_spectrum/generate_data_chapter02.py est touché, avec backup supplémentaire .bak_bad_indent_v2.";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== PATCH CH02 v2 – Réinjection des paramètres logistiques avec indentation correcte =="

python - << 'PYEOF'
import pathlib

backup = pathlib.Path("scripts/02_primordial_spectrum/generate_data_chapter02.py.bak_logistic_fix")
target = pathlib.Path("scripts/02_primordial_spectrum/generate_data_chapter02.py")

if not backup.exists():
    raise SystemExit("[ERREUR] Backup .bak_logistic_fix introuvable – patch v2 annulé.")

text = backup.read_text()

needle = "a_log = a0 + (ainf - a0) / (1 + np.exp(-(T - Tc) / Delta))"

if needle not in text:
    raise SystemExit("[ERREUR] Ligne cible 'a_log = ...' introuvable dans le backup – patch v2 annulé.")

pos = text.index(needle)
line_start = text.rfind("\n", 0, pos) + 1
indent_segment = text[line_start:pos]
# indentation = leading spaces/tabs avant 'a_log'
indent = indent_segment[:len(indent_segment) - len(indent_segment.lstrip(" \t"))]

snippet = f"""{indent}import json
{indent}with open("assets/zz-data/chapter02/02_optimal_parameters.json") as f:
{indent}    _params = json.load(f)
{indent}a0 = _params["a0"]
{indent}ainf = _params["ainf"]
{indent}Tc = _params["Tc"]
{indent}Delta = _params["Delta"]

"""

new_text = text[:pos] + snippet + text[pos:]

# On sauvegarde l’ancienne version (celle avec mauvaise indentation) au cas où
bad_backup = target.with_suffix(target.suffix + ".bak_bad_indent_v2")
if target.exists():
    bad_backup.write_text(target.read_text())
    print(f"[BACKUP] {bad_backup}")

target.write_text(new_text)
print(f"[WRITE] {target} réécrit à partir du backup avec indentation correcte.")
PYEOF
