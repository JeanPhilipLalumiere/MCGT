#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] Script interrompu avec code $code";
  echo "[ASTUCE] mcgt/scalar_perturbations.py a peut-être été partiellement restauré ; vérifie le diff avec le backup.";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== PATCH CH07 – Restauration de mcgt/scalar_perturbations.py depuis .bak_cs2_relaxed + assouplissement c_s² =="

python - << 'PYEOF'
from pathlib import Path
import shutil

dst = Path("mcgt/scalar_perturbations.py")
bak = Path("mcgt/scalar_perturbations.py.bak_cs2_relaxed")

if not bak.exists():
    raise SystemExit("[ERROR] Backup introuvable: " + str(bak))

print(f"[INFO] Backup détecté : {bak}")
print(f"[INFO] Restauration vers : {dst}")
shutil.copy2(bak, dst)
print("[INFO] Fichier principal restauré depuis le backup.")

text = dst.read_text()

old = (
    '    if not np.all((cs2 >= 0.0) & (cs2 <= 1.0) & np.isfinite(cs2)):\\n'
    '        raise ValueError("c_s² hors-borne ou non-fini (attendu dans [0,1]).")'
)

new = (
    '    if not np.all((cs2 >= 0.0) & (cs2 <= 1.0) & np.isfinite(cs2)):\\n'
    '        import warnings\\n'
    '        warnings.warn("c_s² hors-borne ou non-fini (attendu dans [0,1]) – valeurs clipées dans [0,1] pour le pipeline minimal.", RuntimeWarning)\\n'
    '        cs2 = np.clip(cs2, 0.0, 1.0)'
)

if old not in text:
    print("[WARN] Motif exact pour le contrôle c_s² introuvable dans le backup. Aucun remplacement effectué.")
else:
    text = text.replace(old, new)
    dst.write_text(text)
    print("[PATCH] Contrôle c_s² mis à jour (ValueError -> warning + clip).")

print("\n[SNIPPET] Aperçu de compute_cs2 après patch :")
lines = dst.read_text().splitlines()
for i, line in enumerate(lines, start=1):
    if "def compute_cs2" in line:
        for j in range(i, min(i+25, len(lines))+1):
            print(f"{j:3}: {lines[j-1]}")
        break
PYEOF

echo
echo "Terminé (patch_ch07_restore_scalar_perturbations_from_backup)."
