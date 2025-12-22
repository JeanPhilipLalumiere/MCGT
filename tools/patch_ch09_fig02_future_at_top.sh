#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] Script interrompu avec code $code";
  echo "[ASTUCE] Seul scripts/09_dark_energy_cpl/plot_fig02_residual_phase.py est touché, avec backup .bak_future_top.";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== PATCH CH09 – Réordonner from __future__ en tête du module =="

python - << 'PYEOF'
from pathlib import Path
import shutil

path = Path("scripts/09_dark_energy_cpl/plot_fig02_residual_phase.py")
if not path.exists():
    raise SystemExit("[ERROR] Fichier introuvable: " + str(path))

backup = path.with_suffix(".py.bak_future_top")
shutil.copy2(path, backup)
print(f"[BACKUP] {backup} créé")

lines = path.read_text().splitlines()

# 1) Shebang éventuel
shebang = []
start = 0
if lines and lines[0].startswith("#!"):
    shebang = [lines[0]]
    start = 1

rest = lines[start:]

# 2) Préambule = commentaires / lignes vides / docstring triple-quotée au tout début
preamble = []
i = 0
in_doc = False
doc_quote = None

while i < len(rest):
    line = rest[i]
    stripped = line.strip()

    if in_doc:
        preamble.append(line)
        # fermeture docstring (approche simple : on voit à nouveau les triple quotes)
        if doc_quote and doc_quote in stripped:
            in_doc = False
        i += 1
        continue

    # Ouverture éventuelle de docstring
    if stripped.startswith('"""') or stripped.startswith("'''"):
        in_doc = True
        doc_quote = '"""' if stripped.startswith('"""') else "'''"
        preamble.append(line)
        # docstring sur une seule ligne
        if stripped.count(doc_quote) >= 2:
            in_doc = False
        i += 1
        continue

    # Commentaire ou ligne vide au début → reste dans le préambule
    if stripped.startswith("#") or stripped == "":
        preamble.append(line)
        i += 1
        continue

    # Première ligne de *code réel* (import, fonctions, etc.) → on s'arrête là
    break

body_original = rest[i:]

if not any("from __future__ import annotations" in l for l in body_original):
    print("[WARN] Aucun 'from __future__ import annotations' trouvé dans le corps; aucun changement appliqué.")
    raise SystemExit(0)

# 3) Retirer tous les 'from __future__ import annotations' du corps
body_wo_future = []
for line in body_original:
    if "from __future__ import annotations" in line:
        continue
    body_wo_future.append(line)

future_line = "from __future__ import annotations"

# 4) Reconstruire le fichier
new_lines = []
new_lines.extend(shebang)
if shebang:
    # on garde une ligne vide après le shebang si elle n'existe pas déjà
    if not (preamble and preamble[0].strip() == ""):
        new_lines.append("")

new_lines.extend(preamble)
# s'assurer d'une ligne vide avant from __future__ si le préambule n'en a pas déjà
if new_lines and new_lines[-1].strip() != "":
    new_lines.append("")

new_lines.append(future_line)

# Ligne vide après le from __future__ pour la lisibilité
if body_wo_future and body_wo_future[0].strip() != "":
    new_lines.append("")

new_lines.extend(body_wo_future)

path.write_text("\n".join(new_lines) + "\n")
print("[PATCH] 'from __future__ import annotations' repositionné juste après le préambule (docstring/commentaires).")
PYEOF

echo
echo "Terminé (patch_ch09_fig02_future_at_top)."
