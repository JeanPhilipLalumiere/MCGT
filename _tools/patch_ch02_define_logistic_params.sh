#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] patch_ch02_define_logistic_params interrompu (code $code)";
  echo "[ASTUCE] Seul zz-scripts/chapter02/generate_data_chapter02.py a été modifié, avec backup .bak_logistic_fix.";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== PATCH CH02 – Injection des paramètres logistiques (a0, ainf, Tc, Delta) =="

python - << 'PYEOF'
import pathlib

path = pathlib.Path("zz-scripts/chapter02/generate_data_chapter02.py")
text = path.read_text()

needle = "a_log = a0 + (ainf - a0) / (1 + np.exp(-(T - Tc) / Delta))"

if needle not in text:
    raise SystemExit("Ligne cible introuvable dans generate_data_chapter02.py – patch annulé.")

# Si les paramètres existent déjà, on ne touche à rien
if all(name in text for name in ("a0 =", "ainf =", "Tc =", "Delta =")):
    print("[INFO] Les paramètres a0, ainf, Tc, Delta semblent déjà définis. Aucun changement.")
    raise SystemExit(0)

snippet = '''import json

with open("zz-data/chapter02/02_optimal_parameters.json") as f:
    _params = json.load(f)
a0 = _params["a0"]
ainf = _params["ainf"]
Tc = _params["Tc"]
Delta = _params["Delta"]

'''

before, after = text.split(needle, 1)
new_text = before + snippet + needle + after

backup = path.with_suffix(path.suffix + ".bak_logistic_fix")
backup.write_text(text)
print(f"[BACKUP] {backup}")

path.write_text(new_text)
print(f"[WRITE] {path} mis à jour avec chargement des paramètres logistiques.")
PYEOF
