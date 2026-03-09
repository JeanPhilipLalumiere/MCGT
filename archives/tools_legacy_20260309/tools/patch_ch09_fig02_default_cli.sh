#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] Script interrompu avec code $code";
  echo "[ASTUCE] Seul scripts/09_dark_energy_cpl/plot_fig02_residual_phase.py est touché, avec backup .bak_default_cli.";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== PATCH CH09 – Injection d'arguments par défaut pour fig_02 (residual_phase) =="

python - << 'PYEOF'
from pathlib import Path
import shutil

path = Path("scripts/09_dark_energy_cpl/plot_fig02_residual_phase.py")
if not path.exists():
    raise SystemExit("[ERROR] Fichier introuvable: " + str(path))

backup = path.with_suffix(".py.bak_default_cli")
shutil.copy2(path, backup)
print(f"[BACKUP] {backup} créé")

text = path.read_text()

# Séparation éventuelle du shebang
lines = text.splitlines()
shebang = ""
start = 0
if lines and lines[0].startswith("#!"):
    shebang = lines[0]
    start = 1

body = "\n".join(lines[start:])

injection = '''import sys
from pathlib import Path

# Seed automatique des arguments CLI lorsqu'aucun n'est fourni
if __name__ == "__main__" and len(sys.argv) == 1:
    ROOT = Path(__file__).resolve().parents[2]
    csv_default = ROOT / "assets/zz-data" / "chapter09" / "09_phase_diff.csv"
    meta_default = ROOT / "assets/zz-data" / "chapter09" / "09_metrics_phase.json"
    out_default = ROOT / "assets/zz-figures" / "chapter09" / "09_fig_02_residual_phase.png"
    sys.argv.extend([
        "--csv", str(csv_default),
        "--meta", str(meta_default),
        "--out", str(out_default),
    ])

'''

if shebang:
    new_text = shebang + "\n" + injection + body
else:
    new_text = injection + body

path.write_text(new_text)
print("[PATCH] Bloc d'initialisation CLI par défaut injecté avant le reste du script.")
PYEOF

echo
echo "Terminé (patch_ch09_fig02_default_cli)."
