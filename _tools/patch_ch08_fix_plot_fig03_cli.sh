#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] Script interrompu avec code $code";
  echo "[ASTUCE] Seul zz-scripts/chapter08/plot_fig03_mu_vs_z.py est touché, avec backup .bak_fix_cli.";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== PATCH CH08 – CLI propre pour plot_fig03_mu_vs_z.py =="

python - << 'PYEOF'
from pathlib import Path
import shutil

path = Path("zz-scripts/chapter08/plot_fig03_mu_vs_z.py")
if not path.exists():
    raise SystemExit(f"[ERROR] Fichier introuvable: {path}")

backup = path.with_suffix(".py.bak_fix_cli")
shutil.copy2(path, backup)
print(f"[BACKUP] {backup} créé")

text = path.read_text()

marker = 'if __name__ == "__main__"'
idx = text.find(marker)
if idx == -1:
    raise SystemExit("[ERROR] Bloc '__main__' introuvable dans plot_fig03_mu_vs_z.py")

prefix = text[:idx]

# On essaie de deviner la fonction d'entrée
entry_name = "main"
if "def main(" in text:
    entry_name = "main"
elif "def plot_fig03" in text:
    entry_name = "plot_fig03"
elif "def run(" in text:
    entry_name = "run"

new_block = f'''
if __name__ == "__main__":
    # CLI simplifiée pour le pipeline minimal (CH08 – μ(z))
    import argparse
    import os

    parser = argparse.ArgumentParser(
        description="Trace μ(z) pour le Chapitre 8 (couplage sombre)."
    )
    parser.add_argument(
        "--outdir",
        default=os.environ.get("MCGT_OUTDIR", str(FIG_DIR)),
        help="Dossier de sortie (défaut: MCGT_OUTDIR ou zz-figures/chapter08).",
    )
    parser.add_argument(
        "--dpi",
        type=int,
        default=150,
        help="DPI de la figure (défaut: 150).",
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="count",
        default=0,
        help="Niveau de verbosité (-v, -vv).",
    )

    args = parser.parse_args()
    os.makedirs(args.outdir, exist_ok=True)
    os.environ["MCGT_OUTDIR"] = args.outdir

    {entry_name}()
'''

new_text = prefix + new_block.lstrip("\\n")
path.write_text(new_text)
print("[WRITE] Bloc CLI réécrit pour plot_fig03_mu_vs_z.py (verbose/dpi séparés, plus de SyntaxError).")
PYEOF

echo
echo "Terminé (patch_ch08_fix_plot_fig03_cli)."
