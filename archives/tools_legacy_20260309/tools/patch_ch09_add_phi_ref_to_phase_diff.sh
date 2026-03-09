#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] Script interrompu avec code $code";
  echo "[ASTUCE] Seul assets/zz-data/09_dark_energy_cpl/09_phase_diff.csv est touché, avec backup .bak_add_phi_ref.";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== PATCH CH09 – Ajout de phi_ref dans 09_phase_diff.csv à partir de 09_phases_imrphenom.csv =="

python - << 'PYEOF'
from pathlib import Path
import csv
import shutil

diff_path = Path("assets/zz-data/09_dark_energy_cpl/09_phase_diff.csv")
ref_path = Path("assets/zz-data/09_dark_energy_cpl/09_phases_imrphenom.csv")

if not diff_path.exists():
    raise SystemExit("[ERREUR] Fichier introuvable: assets/zz-data/09_dark_energy_cpl/09_phase_diff.csv")
if not ref_path.exists():
    raise SystemExit("[ERREUR] Fichier introuvable: assets/zz-data/09_dark_energy_cpl/09_phases_imrphenom.csv")

backup = diff_path.with_suffix(".csv.bak_add_phi_ref")
shutil.copy2(diff_path, backup)
print(f"[BACKUP] {backup} créé")

def key_from_str(s: str) -> str:
    try:
        return f"{float(s):.9f}"
    except ValueError:
        return s

# 1) Charger phi_ref depuis 09_phases_imrphenom.csv
with ref_path.open(newline="", encoding="utf-8") as f:
    reader = csv.DictReader(f)
    if reader.fieldnames is None:
        raise SystemExit("[ERREUR] 09_phases_imrphenom.csv semble vide.")
    if "f_Hz" not in reader.fieldnames:
        raise SystemExit("[ERREUR] Colonne 'f_Hz' absente de 09_phases_imrphenom.csv")
    if "phi_ref" not in reader.fieldnames:
        raise SystemExit("[ERREUR] Colonne 'phi_ref' absente de 09_phases_imrphenom.csv")

    ref_map = {}
    for row in reader:
        k = key_from_str(row["f_Hz"])
        ref_map[k] = row["phi_ref"]

print(f"[INFO] Phases de référence chargées: {len(ref_map)} fréquences.")

# 2) Charger 09_phase_diff.csv
with diff_path.open(newline="", encoding="utf-8") as f:
    reader = csv.DictReader(f)
    if reader.fieldnames is None:
        raise SystemExit("[ERREUR] 09_phase_diff.csv semble vide.")
    fieldnames = list(reader.fieldnames)
    if "f_Hz" not in fieldnames:
        raise SystemExit("[ERREUR] Colonne 'f_Hz' absente de 09_phase_diff.csv")
    if "phi_ref" in fieldnames:
        print("[INFO] Colonne 'phi_ref' déjà présente dans 09_phase_diff.csv – aucun changement effectué.")
        raise SystemExit(0)
    rows = list(reader)

# 3) Injection de phi_ref dans chaque ligne
added = 0
missing = 0
for row in rows:
    k = key_from_str(row["f_Hz"])
    phi_ref = ref_map.get(k)
    if phi_ref is None:
        missing += 1
        row["phi_ref"] = ""
    else:
        added += 1
        row["phi_ref"] = phi_ref

print(f"[INFO] phi_ref ajouté pour {added} lignes ; {missing} sans correspondance exacte.")

fieldnames.append("phi_ref")

with diff_path.open("w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=fieldnames)
    writer.writeheader()
    writer.writerows(rows)

print("[OK] assets/zz-data/09_dark_energy_cpl/09_phase_diff.csv mis à jour avec une colonne 'phi_ref'.")
PYEOF

echo
echo "Terminé (patch_ch09_add_phi_ref_to_phase_diff)."
