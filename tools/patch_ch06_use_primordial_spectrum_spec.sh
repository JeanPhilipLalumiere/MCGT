#!/usr/bin/env bash
set -Eeuo pipefail

echo "== PATCH CH06 – SPEC2_FILE → 02_primordial_spectrum_spec.json =="

python - << 'PYEOF'
from pathlib import Path
import shutil

path = Path("scripts/chapter06/generate_data_chapter06.py")
if not path.exists():
    print("[ERROR] Fichier generate_data_chapter06.py introuvable.")
    raise SystemExit(1)

backup = path.with_suffix(".py.bak_spec2")
shutil.copy2(path, backup)
print(f"[BACKUP] {backup} créé")

text = path.read_text()

old_token = "02_spec_spectrum.json"
new_token = "02_primordial_spectrum_spec.json"

if old_token not in text:
    print(f"[WARN] Motif '{old_token}' introuvable dans le fichier. Aucun remplacement effectué.")
else:
    text = text.replace(old_token, new_token)
    path.write_text(text)
    print(f"[PATCH] Toutes les occurrences de '{old_token}' ont été remplacées par '{new_token}'.")

PYEOF

echo
echo "Terminé (patch_ch06_use_primordial_spectrum_spec)."
