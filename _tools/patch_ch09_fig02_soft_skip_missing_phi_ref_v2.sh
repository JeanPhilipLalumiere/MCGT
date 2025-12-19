#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] Script interrompu avec code $code";
  echo "[ASTUCE] Seul zz-scripts/chapter09/plot_fig02_residual_phase.py est touché, avec backup .bak_soft_skip_v2.";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== PATCH CH09 v2 – Colonnes manquantes pour fig02 : warning + skip (exit 0) =="

python - << 'PYEOF'
from pathlib import Path
import shutil

path = Path("zz-scripts/chapter09/plot_fig02_residual_phase.py")
if not path.exists():
    raise SystemExit("[ERROR] Fichier introuvable: " + str(path))

backup = path.with_suffix(".py.bak_soft_skip_v2")
shutil.copy2(path, backup)
print(f"[BACKUP] {backup} créé")

lines = path.read_text().splitlines()

target_idx = None
for i, line in enumerate(lines):
    if "Colonnes manquantes pour fig02" in line:
        target_idx = i
        break

if target_idx is None:
    print("[WARN] Aucune ligne contenant 'Colonnes manquantes pour fig02' trouvée, aucun changement appliqué.")
    raise SystemExit(0)

orig_line = lines[target_idx]
indent = orig_line[: len(orig_line) - len(orig_line.lstrip())]

# Nouveau message : warning + info skip
lines[target_idx] = (
    f'{indent}print(f"[WARNING] Colonnes manquantes pour fig02: {{missing}} – fig02 sautée pour le pipeline minimal.")'
)

# Chercher la première ligne avec SystemExit après ce print, et la transformer en exit 0
for j in range(target_idx + 1, len(lines)):
    if "SystemExit(" in lines[j]:
        if "SystemExit(1)" in lines[j]:
            lines[j] = lines[j].replace("SystemExit(1)", "SystemExit(0)")
        else:
            indent2 = lines[j][: len(lines[j]) - len(lines[j].lstrip())]
            lines[j] = f"{indent2}raise SystemExit(0)"
        break

path.write_text("\n".join(lines) + "\n")
print("[PATCH] Cas 'Colonnes manquantes pour fig02' transformé en warning + exit 0 (skip).")
PYEOF

echo
echo "Terminé (patch_ch09_fig02_soft_skip_missing_phi_ref_v2)."
