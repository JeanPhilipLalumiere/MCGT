from _common import cli as C
import argparse
#!/usr/bin/env python3
# fichier : zz-scripts/chapter01/plot_fig04_P_vs_T_evolution.py
# répertoire : zz-scripts/chapter01
import os
"""Fig. 04 – Évolution de P(T) : initial vs optimisé"""

from pathlib import Path

from _common.cli import add_common_plot_args, finalize_plot_from_args, init_logging

import matplotlib.pyplot as plt
import pandas as pd

# Configuration des chemins
base = Path(__file__).resolve().parents[2]
init_csv = base / "zz-data" / "chapter01" / "01_initial_grid_data.dat"
opt_csv = base / "zz-data" / "chapter01" / "01_optimized_data_and_derivatives.csv"
output_file = base / "zz-figures" / "chapter01" / "fig_04_P_vs_T_evolution.png"

# Lecture des données
df_init = pd.read_csv(init_csv)
df_opt = pd.read_csv(opt_csv)
T_init = df_init["T"]
P_init = df_init["P"]
T_opt = df_opt["T"]
P_opt = df_opt["P"]

# Tracé de la figure
plt.figure(dpi=300)
plt.plot(T_init, P_init, "--", color="grey", label=r"$P_{\rm init}(T)$")
plt.plot(T_opt, P_opt, "-", color="orange", label=r"$P_{\rm opt}(T)$")
plt.xscale("log")
plt.yscale("linear")
plt.xlabel("T (Gyr)")
plt.ylabel("P(T)")
plt.title("Fig. 04 – Évolution de P(T) : initial vs optimisé")
plt.grid(True, which="both", linestyle=":", linewidth=0.5)
plt.legend()
fig.subplots_adjust(left=0.04, right=0.98, bottom=0.06, top=0.96)
# [mcgt-homog] plt.savefig(output_file)

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
