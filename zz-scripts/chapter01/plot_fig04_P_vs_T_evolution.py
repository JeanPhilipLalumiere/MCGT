#!/usr/bin/env python3
import os
"""Fig. 04 - Évolution de P(T) : initial vs optimisé"""

from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd

# Configuration des chemins
base = Path( __file__).resolve().parents[ 2]
init_csv = base / "zz-data" / "chapter01" / "01_initial_grid_data.dat"
opt_csv = base / "zz-data" / "chapter01" / \
"01_optimized_data_and_derivatives.csv"
output_file = base / "zz-figures" / "chapter01" / "fig_04_P_vs_T_evolution.png"

# Lecture des données
df_init = pd.read_csv( init_csv)
df_opt = pd.read_csv( opt_csv)
T_init = df_init[ "T"]
P_init = df_init[ "P"]
T_opt = df_opt[ "T"]
P_opt = df_opt[ "P"]

# Tracé de la figure
plt.figure( dpi=300)
plt.plot( T_init, P_init, "--", color="grey", label=r"$P_{\rm init}(T)$")
plt.plot( T_opt, P_opt, "-", color="orange", label=r"$P_{\rm opt}(T)$")
plt.xscale( "log")
plt.yscale( "linear")
plt.xlabel( "T (Gyr)")
plt.ylabel( "P(T)")
plt.title( "Fig. 04 - Évolution de P(T) : initial vs optimisé")
plt.grid( True, which="both", linestyle=":", linewidth=0.5)
plt.legend()
fig=plt.gcf(); fig.subplots_adjust( left=0.07,bottom=0.12,right=0.98,top=0.95)
plt.savefig( output_file)

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
