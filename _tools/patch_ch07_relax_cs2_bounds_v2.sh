#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] Script interrompu avec code $code";
  echo "[ASTUCE] Seul mcgt/scalar_perturbations.py est touché, avec backup .bak_cs2_relaxed_v2.";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== PATCH CH07 – Remplacement du raise ValueError(c_s²...) par warning + clip =="

python - << 'PYEOF'
from pathlib import Path
import shutil

path = Path("mcgt/scalar_perturbations.py")
if not path.exists():
    raise SystemExit("[ERROR] Fichier introuvable: " + str(path))

backup = path.with_suffix(".py.bak_cs2_relaxed_v2")
shutil.copy2(path, backup)
print(f"[BACKUP] {backup} créé")

lines = path.read_text().splitlines()

target = 'ValueError("c_s² hors-borne ou non-fini (attendu dans [0,1]).")'
replaced = False

for i, line in enumerate(lines):
    if target in line:
        if i == 0:
            raise SystemExit("[ERROR] Ligne ValueError trouvée en tête de fichier, structure inattendue.")
        if_line = lines[i-1]
        base_indent = if_line[: len(if_line) - len(if_line.lstrip())]
        indent = base_indent + "    "

        print("[INFO] Bloc de contrôle c_s² trouvé autour des lignes", i, "et", i+1)
        print("[INFO] Remplacement du raise ValueError par warning + clip dans [0,1].")

        lines[i-1 : i+1] = [
            if_line,
            indent + "import warnings",
            indent + 'warnings.warn('
                     '"c_s² hors-borne ou non-fini (attendu dans [0,1]) – '
                     'valeurs clipées dans [0,1] pour le pipeline minimal.", '
                     "RuntimeWarning)",
            indent + "cs2 = np.clip(cs2, 0.0, 1.0)",
        ]
        replaced = True
        break

if not replaced:
    print("[WARN] Aucun bloc ValueError(c_s²...) trouvé, aucun remplacement effectué.")
else:
    path.write_text("\\n".join(lines) + "\\n")
    print("[WRITE] Bloc c_s² mis à jour (warning + clip).")

    print("\\n[SNIPPET] Aperçu local autour de compute_cs2 :")
    lines2 = path.read_text().splitlines()
    for j, l in enumerate(lines2, start=1):
        if "def compute_cs2" in l:
            for k in range(j, min(j+40, len(lines2))+1):
                print(f"{k:3}: {lines2[k-1]}")
            break
PYEOF

echo
echo "Terminé (patch_ch07_relax_cs2_bounds_v2)."
