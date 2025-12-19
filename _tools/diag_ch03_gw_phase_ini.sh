#!/usr/bin/env bash
set -Eeuo pipefail

echo "== DIAG CH03 – Inspection de gw_phase.ini et de la section [scan] =="
echo

python - << 'PYEOF'
from pathlib import Path
import configparser

paths = list(Path(".").rglob("gw_phase.ini"))

if not paths:
    print("[INFO] Aucun fichier gw_phase.ini trouvé dans le dépôt.")
else:
    print(f"[INFO] Fichiers gw_phase.ini trouvés ({len(paths)}) :")
    for p in paths:
        print("  -", p)
    print()

    for p in paths:
        print("="*70)
        print(f"[FILE] {p}")
        print("-"*70)
        cp = configparser.ConfigParser()
        cp.read(p)
        print("[INFO] Sections détectées :", cp.sections())
        print()

        if "scan" in cp:
            print("[INFO] Contenu de la section [scan] :")
            for k, v in cp["scan"].items():
                print(f"  {k} = {v}")
        else:
            print("[WARN] Aucune section [scan] dans ce fichier.")

        print()
PYEOF

echo
echo "Terminé (diag_ch03_gw_phase_ini)."
echo "Appuie sur Entrée pour revenir au shell..."
read -r _
