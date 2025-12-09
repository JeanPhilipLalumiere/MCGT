#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] Script interrompu avec code $code";
  echo "[ASTUCE] Seul zz-scripts/chapter06/generate_pdot_plateau_vs_z.py est touché, avec backup .bak_cleanup.";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== PATCH CH06 – Nettoyage de generate_pdot_plateau_vs_z.py (chemin + bloc __main__) =="

python - << 'PYEOF'
from pathlib import Path
import shutil, sys

path = Path("zz-scripts/chapter06/generate_pdot_plateau_vs_z.py")
if not path.exists():
    print("[ERROR] Fichier introuvable:", path)
    sys.exit(1)

backup = path.with_suffix(".py.bak_cleanup")
shutil.copy2(path, backup)
print(f"[BACKUP] {backup} créé")

text = path.read_text()

# 1) Corriger le dossier de sortie: 'zz-config' -> 'zz-configuration'
if "zz-config" in text:
    text = text.replace("zz-config", "zz-configuration")
    print("[PATCH] Remplacement de 'zz-config' par 'zz-configuration'.")
else:
    print("[INFO] Aucun motif 'zz-config' trouvé (rien à corriger pour le chemin).")

# 2) Supprimer complètement le bloc if __name__ == '__main__'
lines = text.splitlines()
idx_main = None
for i, line in enumerate(lines):
    normalized = line.replace("'", '"')
    if 'if __name__ == "__main__"' in normalized:
        idx_main = i
        break

if idx_main is None:
    print("[WARN] Aucun bloc if __name__ == '__main__' trouvé: rien à supprimer.")
    new_lines = lines
else:
    print(f"[PATCH] Bloc __main__ détecté à la ligne {idx_main+1}, suppression de la fin du fichier.")
    new_lines = lines[:idx_main]

path.write_text("\n".join(new_lines) + "\n")
print("[WRITE] Fichier mis à jour (chemin corrigé + bloc __main__ supprimé).")
PYEOF

echo
echo "Terminé (patch_ch06_generate_pdot_cleanup)."
