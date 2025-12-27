#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] Script interrompu avec code $code";
  echo "[ASTUCE] Seul scripts/02_primordial_spectrum/generate_data_chapter02.py a été modifié, avec backup .bak_header_dotp_cleanup.";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== PATCH CH02 – Réorganisation de l'entête + nettoyage de dotP dupliqué =="
echo

python - << 'PYEOF'
from pathlib import Path
import shutil

path = Path("scripts/02_primordial_spectrum/generate_data_chapter02.py")
backup = path.with_suffix(".py.bak_header_dotp_cleanup")
shutil.copy2(path, backup)
print(f"[BACKUP] {backup} créé")

orig_lines = path.read_text().splitlines()

# 1) Trouver la fin de la docstring (2e occurrence de \"\"\")
doc_indices = [i for i, line in enumerate(orig_lines) if '"""' in line]
if len(doc_indices) < 2:
    raise RuntimeError("Impossible de trouver la docstring de tête (2x \"\"\").")
doc_end = doc_indices[1]

# 2) Trouver la première définition de dotP (début des fonctions utilitaires)
dotp_index = None
for i, line in enumerate(orig_lines):
    if line.startswith("def dotP("):
        dotp_index = i
        break
if dotp_index is None:
    raise RuntimeError("Impossible de trouver def dotP dans le fichier.")

new_lines = []
# Garder le shebang + docstring telles quelles
new_lines.extend(orig_lines[: doc_end + 1])
new_lines.append("")

# --- Entête canonique : imports + logging + paramètres logistiques + T ---
new_lines.extend([
    "# --- Section 1 : Imports et configuration ---",
    "import argparse",
    "import json",
    "import logging",
    "import subprocess",
    "from pathlib import Path",
    "import glob",
    "",
    "import numpy as np",
    "import pandas as pd",
    "from scipy.interpolate import PchipInterpolator",
    "from scipy.optimize import minimize",
    "from scipy.signal import savgol_filter",
    "",
    "logging.basicConfig(level=logging.INFO, format=\"%(levelname)s: %(message)s\")",
    "",
    "# Paramètres logistiques pré-calibrés depuis 02_optimal_parameters.json",
    "with open(\"assets/zz-data/02_primordial_spectrum/02_optimal_parameters.json\") as f:",
    "    _params = json.load(f)",
    "",
    "_segments = _params[\"segments\"]",
    "_low = _segments[\"low\"]",
    "",
    "# Pour le pipeline minimal, on utilise le segment \"low\"",
    "a0 = _low[\"alpha0\"]",
    "ainf = _low[\"alpha_inf\"]",
    "Tc = _low[\"Tc\"]",
    "Delta = _low[\"Delta\"]",
    "Tp = _low[\"Tp\"]",
    "",
    "# Grille temporelle T extraite du fichier P(T)",
    "_grid_PT = np.loadtxt(\"assets/zz-data/02_primordial_spectrum/02_P_vs_T_grid_data.dat\")",
    "T = _grid_PT[:, 0]",
    "",
    "# --- Section 2 : Fonctions utilitaires ---",
])

# 3) Ajouter le reste du fichier à partir de la première def dotP
new_lines.extend(orig_lines[dotp_index:])

# 4) Deuxième passe : enlever la 2e def dotP et le bloc parasite qui suit
final_lines = []
seen_first_dotp = False
skipping_second = False

for line in new_lines:
    if line.startswith("def dotP("):
        if not seen_first_dotp:
            seen_first_dotp = True
            final_lines.append(line)
        else:
            # Début de la 2e définition : on commence à skipper
            skipping_second = True
        continue

    if skipping_second:
        # On saute tout jusqu'au prochain 'def ' top-level qui n'est pas dotP
        if line.startswith("def ") and not line.startswith("def dotP("):
            skipping_second = False
            final_lines.append(line)
        # Sinon, on continue à ignorer les lignes parasites
        continue

    final_lines.append(line)

path.write_text("\n".join(final_lines) + "\n", encoding="utf-8")
print(f"[WRITE] {path} mis à jour (entête réorganisée + dotP dupliqué supprimé).")
PYEOF

echo
echo "Terminé (patch_ch02_header_and_dotp_cleanup)."
echo "Appuie sur Entrée pour revenir au shell..."
read -r _
