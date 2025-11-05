#!/usr/bin/env python3
import contextlib
# fichier : zz-scripts/chapter02/plot_fig01_P_vs_T_evolution.py
# répertoire : zz-scripts/chapter02
import os
"""Fig. 01 - Évolution de P(T) - Chapitre 2 (Validation chronologique)"""

from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

# Paths
ROOT = Path( __file__).resolve().parents[ 2]
DATA_DIR = ROOT / "zz-data" / "chapter02"
FIG_DIR = ROOT / "zz-figures" / "chapter02"
FIG_DIR.mkdir( parents=True, exist_ok=True)

# Load data
T_dense, P_dense = np.loadtxt(DATA_DIR / "02_P_vs_T_grid_data.dat", unpack=True)
results = pd.read_csv( DATA_DIR / "02_timeline_milestones.csv")
T_ref = results[ "T"]
P_ref = results[ "P_ref"]

# Plot
plt.figure(dpi=300)
plt.plot(T_dense, P_dense, "-", label=r"$P_{\rm calc}(T)$", color="orange")
plt.scatter(T_ref, P_ref, marker="o", label=r"$P_{\rm ref}(T_i)$", color="grey")
plt.xscale("log")
plt.yscale("log")
plt.xlabel("T (Gyr)")
plt.ylabel("P(T)")
plt.title("Fig. 01 - Évolution de P(T) - Chapitre 2")
plt.grid(True, which="both", linestyle=":", linewidth=0.5)
plt.legend()
fig.subplots_adjust(left=0.04, right=0.98, bottom=0.06, top=0.96)
plt.savefig(FIG_DIR / "fig_01_P_vs_T_evolution.png")

# === MCGT CLI SEED v2 ===
if __name__ == "__main__":
    def _mcgt_cli_seed():
        import os, argparse, sys, traceback
        parser = argparse.ArgumentParser(description="Standard CLI seed (non-intrusif).")
        parser.add_argument("--outdir", default=os.environ.get("MCGT_OUTDIR", ".ci-out"), help="Dossier de sortie (par défaut: .ci-out)")
        parser.add_argument("--dry-run", action="store_true", help="Ne rien écrire, juste afficher les actions.")
        parser.add_argument("--seed", type=int, default=None, help="Graine aléatoire (optionnelle).")
        parser.add_argument("--force", action="store_true", help="Écraser les sorties existantes si nécessaire.")
        parser.add_argument("-v", "--verbose", action="count", default=0, help="Verbosity cumulable (-v, -vv).")
        parser.add_argument("--dpi", type=int, default=150, help="Figure DPI (default: 150)")
        parser.add_argument("--format", choices=["png","pdf","svg"], default="png", help="Figure format")
        parser.add_argument("--transparent", action="store_true", help="Transparent background")

        args = parser.parse_args()
        with contextlib.suppress(Exception):
            os.makedirs(args.outdir, exist_ok=True)
        os.environ["MCGT_OUTDIR"] = args.outdir
        import matplotlib as mpl
        mpl.rcParams["savefig.dpi"] = args.dpi
        mpl.rcParams["savefig.format"] = args.format
        mpl.rcParams["savefig.transparent"] = args.transparent
        _main = globals().get("main")
        if callable(_main):
            with contextlib.suppress(Exception):
                _main(args)
    _mcgt_cli_seed()
