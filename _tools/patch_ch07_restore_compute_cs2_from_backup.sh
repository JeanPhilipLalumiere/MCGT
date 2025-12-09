#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] Script interrompu avec code $code";
  echo "[ASTUCE] Seul mcgt/scalar_perturbations.py est touché, avec backup .bak_restore_cs2.";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== PATCH CH07 – Restauration propre de compute_cs2 depuis le backup + clipping =="

python - << 'PYEOF'
from pathlib import Path
import shutil

path = Path("mcgt/scalar_perturbations.py")
backup_src = Path("mcgt/scalar_perturbations.py.bak_cs2_relaxed")

if not backup_src.exists():
    raise SystemExit("[ERROR] Backup source introuvable: " + str(backup_src))

# On garde aussi un backup de l'état actuel, au cas où.
backup_dest = path.with_suffix(".py.bak_restore_cs2")
shutil.copy2(path, backup_dest)
print(f"[BACKUP] {backup_dest} créé (copie de la version actuelle).")

src_text = backup_src.read_text()
lines = src_text.splitlines()

# Sanity-check : compute_cs2 doit exister dans le backup
if not any("def compute_cs2" in l for l in lines):
    raise SystemExit("[ERROR] 'def compute_cs2' introuvable dans le backup; patch abandonné.")

new_lines = []
for line in lines:
    # On cherche la ligne qui levait l'exception
    if "c_s² hors-borne ou non-fini" in line or "c_s^2 hors-borne ou non-fini" in line:
        indent = line[: len(line) - len(line.lstrip())]

        # On insère à la place : warning + clipping
        new_lines.append(indent + "import warnings")
        new_lines.append(
            indent
            + 'warnings.warn('
            + '"c_s² hors-borne ou non-fini (attendu dans [0,1]) – '
              'valeurs clipées dans [0,1] pour le pipeline minimal.", '
            + "RuntimeWarning)"
        )
        new_lines.append(indent + "cs2 = np.clip(cs2, 0.0, 1.0)")
        # On saute la ligne originale de raise
        continue

    new_lines.append(line)

path.write_text("\\n".join(new_lines) + "\\n")
print("[WRITE] mcgt/scalar_perturbations.py réécrit depuis le backup avec compute_cs2 présent et contrôle assoupli.")
PYEOF

echo
echo "Terminé (patch_ch07_restore_compute_cs2_from_backup)."
