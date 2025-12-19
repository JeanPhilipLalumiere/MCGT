#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] Script interrompu avec code $code";
  echo "[ASTUCE] Seul zz-scripts/chapter08/plot_fig04_chi2_heatmap.py est touché, avec backup .bak_fix_cli_nocall.";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== PATCH CH08 – CLI fig_04 sans appel main() =="

python - << 'PYEOF'
from pathlib import Path
import shutil
import sys
import os

path = Path("zz-scripts/chapter08/plot_fig04_chi2_heatmap.py")
if not path.exists():
    sys.exit(f"[ERROR] Fichier introuvable: {path}")

backup = path.with_suffix(".py.bak_fix_cli_nocall")
shutil.copy2(path, backup)
print(f"[BACKUP] {backup} créé")

text = path.read_text()

marker = 'if __name__ == "__main__"'
idx = text.find(marker)
if idx == -1:
    sys.exit("[ERROR] Bloc '__main__' introuvable dans plot_fig04_chi2_heatmap.py")

prefix = text[:idx]

new_block = '''
if __name__ == "__main__":
    # CLI simplifiée pour le pipeline minimal : le tracé est exécuté au
    # niveau top-level, ici on se contente de configurer le dossier de sortie
    # via MCGT_OUTDIR pour rester homogène avec les autres scripts.
    import argparse

    parser = argparse.ArgumentParser(
        description="Entry point fig_04 χ² heatmap – pipeline minimal."
    )
    parser.add_argument(
        "--outdir",
        default=os.environ.get("MCGT_OUTDIR", str(FIG_DIR)),
        help="Dossier de sortie (défaut: MCGT_OUTDIR ou zz-figures/chapter08).",
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
'''

# On écrase tout le bloc __main__ existant par ce stub propre
path.write_text(prefix + new_block.lstrip("\\n"))
print("[WRITE] Bloc __main__ remplacé sans appel à main().")
PYEOF

echo
echo "Terminé (patch_ch08_plot_fig04_cli_nocall)."
