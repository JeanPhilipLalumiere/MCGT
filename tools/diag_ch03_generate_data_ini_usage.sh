#!/usr/bin/env bash
set -Eeuo pipefail

echo "== DIAG CH03 – Usage de gw_phase.ini dans generate_data_chapter03.py =="
echo

python - << 'PYEOF'
from pathlib import Path

path = Path("scripts/03_stability_domain/generate_data_chapter03.py")
if not path.exists():
    print("[ERROR] Fichier scripts/03_stability_domain/generate_data_chapter03.py introuvable.")
else:
    lines = path.read_text().splitlines()
    hits = []
    for i, line in enumerate(lines, start=1):
        if "gw_phase.ini" in line or "[scan]" in line or "ConfigParser(" in line:
            hits.append(i)

    if not hits:
        print("[INFO] Aucun usage évident de gw_phase.ini / [scan] trouvé.")
    else:
        for idx in hits:
            start = max(1, idx - 10)
            end = min(len(lines), idx + 20)
            print("="*70)
            print(f"[CONTEXT] autour de la ligne {idx}")
            print("-"*70)
            for j in range(start, end + 1):
                print(f"{j:3}: {lines[j-1]}")
            print()
PYEOF

echo
echo "Terminé (diag_ch03_generate_data_ini_usage)."
echo "Appuie sur Entrée pour revenir au shell..."
read -r _
