#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] Script interrompu avec code $code";
  echo "[ASTUCE] Seul scripts/chapter09/plot_fig02_residual_phase.py est touché, avec backup .bak_reorder_seed.";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== PATCH CH09 – Repositionnement du bloc CLI par défaut après from __future__ =="

python - << 'PYEOF'
from pathlib import Path
import shutil

path = Path("scripts/chapter09/plot_fig02_residual_phase.py")
if not path.exists():
    raise SystemExit("[ERROR] Fichier introuvable: " + str(path))

backup = path.with_suffix(".py.bak_reorder_seed")
shutil.copy2(path, backup)
print(f"[BACKUP] {backup} créé")

text = path.read_text()
lines = text.splitlines()

seed_marker = "# Seed automatique des arguments CLI lorsqu'aucun n'est fourni"
future_line = "from __future__ import annotations"

# Localisation du bloc seed
try:
    idx_seed = next(i for i, l in enumerate(lines) if seed_marker in l)
except StopIteration:
    raise SystemExit("[ERROR] Bloc seed CLI introuvable (marker manquant).")

# Localisation du from __future__
try:
    idx_future = next(i for i, l in enumerate(lines) if future_line in l)
except StopIteration:
    raise SystemExit("[ERROR] from __future__ import annotations introuvable.")

# Si le bloc seed est déjà après, on sort
if idx_seed > idx_future:
    print("[INFO] Bloc seed déjà après from __future__; aucun changement nécessaire.")
    raise SystemExit(0)

# Snippet canonical à réinjecter après from __future__
snippet = [
    "import sys",
    "from pathlib import Path",
    "",
    "# Seed automatique des arguments CLI lorsqu'aucun n'est fourni",
    "if __name__ == \"__main__\" and len(sys.argv) == 1:",
    "    ROOT = Path(__file__).resolve().parents[2]",
    "    csv_default = ROOT / \"assets/zz-data\" / \"chapter09\" / \"09_phase_diff.csv\"",
    "    meta_default = ROOT / \"assets/zz-data\" / \"chapter09\" / \"09_metrics_phase.json\"",
    "    out_default = ROOT / \"assets/zz-figures\" / \"chapter09\" / \"09_fig_02_residual_phase.png\"",
    "    sys.argv.extend([",
    "        \"--csv\", str(csv_default),",
    "        \"--meta\", str(meta_default),",
    "        \"--out\", str(out_default),",
    "    ])",
    "",
]

# On supprime l'ancien bloc seed (et ce qui est entre lui et le from __future__)
new_lines = lines[:idx_seed] + lines[idx_future:]

# On retrouve l'index du from __future__ dans new_lines
idx_future_new = next(i for i, l in enumerate(new_lines) if future_line in l)

# Insertion du snippet juste après le from __future__
insertion_pos = idx_future_new + 1
new_lines = new_lines[:insertion_pos] + [""] + snippet + new_lines[insertion_pos:]

path.write_text("\n".join(new_lines) + "\n")
print("[PATCH] Bloc seed CLI déplacé après from __future__ import annotations.")
PYEOF

echo
echo "Terminé (patch_ch09_fig02_reorder_future_and_seed)."
