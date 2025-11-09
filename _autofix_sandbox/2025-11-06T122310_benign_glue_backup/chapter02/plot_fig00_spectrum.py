from _common import cli as C
import argparse
# fichier : zz-scripts/chapter02/plot_fig00_spectrum.py
# répertoire : zz-scripts/chapter02
import os
# ruff: noqa: E402
import sys
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np

# Ajouter le module primordial_spectrum au PYTHONPATH
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "zz-scripts" / "chapter02"))

from primordial_spectrum import P_R

from _common.cli import add_common_plot_args, finalize_plot_from_args, init_logging

# Grille de k et valeurs de alpha
k = np.logspace(-4, 2, 100)
alphas = [0.0, 0.05, 0.1]

# Création de la figure
fig, ax = plt.subplots(figsize=(6, 4))

for alpha in alphas:
    ax.loglog(k, P_R(k, alpha), label=f"α = {alpha}")

ax.set_xlabel("k [h·Mpc⁻¹]")
ax.set_ylabel("P_R(k; α)", labelpad=12)  # labelpad pour décaler plus à droite
ax.set_title("Spectre primordial MCGT")
ax.legend(loc="upper right")
ax.grid(True, which="both", linestyle="--", linewidth=0.5)

# Ajuster les marges pour que tout soit visible
fig.subplots_adjust(left=0.04, right=0.98, bottom=0.06, top=0.96)

# Sauvegarde
OUT = ROOT / "zz-figures" / "chapter02" / "fig_00_spectrum.png"
OUT.parent.mkdir(parents=True, exist_ok=True)
# [mcgt-homog] plt.savefig(OUT, dpi=300)
print(f"Figure enregistrée → {OUT}")

# === MCGT CLI SEED v2 ===
if __name__ == "__main__":
    def _mcgt_cli_seed():
        import os, argparse, sys, traceback
parser = argparse.ArgumentParser(
add_common_plot_args(parser)
description="Standard CLI seed (non-intrusif).")
parser.add_argument("--outdir", default=os.environ.get("MCGT_OUTDIR", ".ci-out"), help="Dossier de sortie (par défaut: .ci-out)")
parser.add_argument("--dry-run", action="store_true", help="Ne rien écrire, juste afficher les actions.")
parser.add_argument("--seed", type=int, default=None, help="Graine aléatoire (optionnelle).")
parser.add_argument("--force", action="store_true", help="Écraser les sorties existantes si nécessaire.")
parser.add_argument("-v", "--verbose", action="count", default=0, help="Verbosity cumulable (-v, -vv).")
parser.add_argument("--dpi", type=int, default=150, help="Figure DPI (default: 150)")
parser.add_argument("--format", choices=["png","pdf","svg"], default="png", help="Figure format")
parser.add_argument("--transparent", action="store_true", help="Transparent background")
parser.add_argument("--out", default="plot.png", help="output image path")
parser.add_argument("--figsize", default="9,6", help="figure size W,H (inches)")
args = parser.parse_args()
try:
            os.makedirs(args.outdir, exist_ok=True)
except Exception:
            pass
os.environ["MCGT_OUTDIR"] = args.outdir
import matplotlib as mpl
mpl.rcParams["savefig.dpi"] = args.dpi
mpl.rcParams["savefig.format"] = args.format
mpl.rcParams["savefig.transparent"] = args.transparent
try:
            pass
except Exception:
            pass
_main = globals().get("main")
if callable(_main):
            if True:
                _main(args)
                pass
                pass
                raise
                pass
                print(f"[CLI seed] main() a levé: {e}", file=sys.stderr)

__mcgt_out = finalize_plot_from_args(args)
def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="(autofix)",,)
    C.add_common_plot_args(p)
    return p
