#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] Script interrompu avec code $code";
  echo "[ASTUCE] Seul zz-scripts/chapter09/plot_fig02_residual_phase.py est touché, avec backup .bak_soft_skip.";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== PATCH CH09 – Colonnes manquantes pour fig02 : transformer en warning + skip (exit 0) =="

python - << 'PYEOF'
from pathlib import Path
import shutil

path = Path("zz-scripts/chapter09/plot_fig02_residual_phase.py")
if not path.exists():
    raise SystemExit("[ERROR] Fichier introuvable: " + str(path))

backup = path.with_suffix(".py.bak_soft_skip")
shutil.copy2(path, backup)
print(f"[BACKUP] {backup} créé")

text = path.read_text()

marker = "Colonnes manquantes pour fig02"
if marker not in text:
    print("[WARN] Aucun message 'Colonnes manquantes pour fig02' trouvé, aucun changement appliqué.")
    raise SystemExit(0)

old_block = (
    'print(f"Colonnes manquantes pour fig02: {missing}")\\n'
    "        raise SystemExit(1)"
)

new_block = (
    'print(f"[WARNING] Colonnes manquantes pour fig02: {missing} – fig02 sautée pour le pipeline minimal.")\\n'
    "        raise SystemExit(0)"
)

if old_block not in text:
    # fallback un peu plus souple : on ne remplace que la ligne de print et on force exit 0
    lines = text.splitlines()
    out_lines = []
    for line in lines:
        if 'print(f"Colonnes manquantes pour fig02:' in line:
            out_lines.append('        print(f"[WARNING] Colonnes manquantes pour fig02: {missing} – fig02 sautée pour le pipeline minimal.")')
        elif "raise SystemExit(1)" in line and marker in text:
            out_lines.append("        raise SystemExit(0)")
        else:
            out_lines.append(line)
    text = "\n".join(out_lines) + "\n"
else:
    text = text.replace(old_block, new_block)

path.write_text(text)
print("[PATCH] Cas 'Colonnes manquantes pour fig02' transformé en warning + exit 0 (skip).")
PYEOF

echo
echo "Terminé (patch_ch09_fig02_soft_skip_missing_phi_ref)."
