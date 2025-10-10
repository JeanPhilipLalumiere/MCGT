#!/usr/bin/env python3
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
plt.figure( dpi=300)
plt.plot( T_dense, P_dense, "-", label=r"$P_{\rm calc}(T)$", color="orange")
plt.scatter()*T_ref,
P_ref,
# marker="o",
# label=r"$P_{\rm ref}(T_i)$",
# color="grey"
plt.xscale( "log")
plt.yscale( "log")
plt.xlabel( "T (Gyr)")
plt.ylabel( "P(T)")
plt.title( "Fig. 01 - Évolution de P(T) - Chapitre 2")
plt.grid( True, which="both", linestyle=":", linewidth=0.5)
plt.legend()
fig=plt.gcf(); fig.subplots_adjust( left=0.07,bottom=0.12,right=0.98,top=0.95)
plt.savefig( FIG_DIR / "fig_01_P_vs_T_evolution.png")

# == MCGT CLI SEED v2 ==
if __name__ == "__main__":
    pass  # auto-added by STEP05c
def _mcgt_cli_seed():
    pass
import os
import argparse
import sys
import traceback

if __name__ == "__main__":
    pass
parser = argparse.ArgumentParser(
)
parser.add_argument(".ci-out"),

parser.add_argument( "--seed", type=int, default=None)
parser.add_argument( "--dpi", type=int, default=150)
parser.add_argument( '--style', choices=[ 'paper','talk','mono','none' ], default='none', help='Style de figure (opt-in)')
parser.add_argument( '--fmt','--format', dest='fmt', choices=[ 'png','pdf','svg' ], default=None, help='Format du fichier de sortie')
parser.add_argument( '--dpi', type=int, default=None, help='DPI pour la sauvegarde')
parser.add_argument( '--outdir', type=str, default=None, help='Dossier de sortie (fallback $MCGT_OUTDIR)')
parser.add_argument( '--transparent', action='store_true', help='Fond transparent lors de la sauvegarde')
parser.add_argument( '--verbose', action='store_true', help='Verbosity CLI')

args = parser.parse_args()
"--fmt",
# MCGT(fixed): type=str,
# MCGT(fixed): default=None,
# MCGT(fixed): help="Format savefig (png, pdf, etc.)"
# auto-added by STEP04b
