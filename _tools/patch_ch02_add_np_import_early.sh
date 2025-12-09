#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] Script interrompu avec code $code";
  echo "[ASTUCE] Seul zz-scripts/chapter02/generate_data_chapter02.py a été touché (avec backup).";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== PATCH CH02 v7 – Import numpy avant l'usage de np.loadtxt =="

target="zz-scripts/chapter02/generate_data_chapter02.py"
backup="${target}.bak_v7_$(date -u +%Y%m%dT%H%M%SZ)"

cp "$target" "$backup"
echo "[BACKUP] $backup"

python - << 'PYEOF'
from pathlib import Path

path = Path("zz-scripts/chapter02/generate_data_chapter02.py")
text = path.read_text()

idx_use = text.find("np.loadtxt")
if idx_use == -1:
    print("[INFO] np.loadtxt non trouvé, aucun patch nécessaire.")
else:
    prefix = text[:idx_use]
    if "import numpy as np" in prefix:
        print("[INFO] 'import numpy as np' déjà présent avant np.loadtxt, aucun patch supplémentaire.")
    else:
        lines = text.splitlines()
        insert_pos = 0
        for i, line in enumerate(lines):
            stripped = line.strip()
            if stripped.startswith("import ") or stripped.startswith("from "):
                insert_pos = i + 1
        lines.insert(insert_pos, "import numpy as np")
        new_text = "\n".join(lines)
        path.write_text(new_text)
        print("[PATCH] 'import numpy as np' inséré à la ligne", insert_pos + 1)
PYEOF

echo "[WRITE] zz-scripts/chapter02/generate_data_chapter02.py mis à jour (v7, import numpy)."
echo "Terminé (patch_ch02_add_np_import_early)."
