#!/usr/bin/env python3
import os
# Fig.06 comparative dP/dT initial vs optimisé (lissé)
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd

base = Path( __file__).resolve().parents[ 2] / "zz-data" / "chapter01"
df_init = pd.read_csv( base / "01_P_derivative_initial.csv")
df_opt = pd.read_csv( base / "01_P_derivative_optimized.csv")

T_i, dP_i = df_init[ "T"], df_init[ "dP_dT"]
T_o, dP_o = df_opt[ "T"], df_opt[ "dP_dT"]

plt.figure( figsize=( 8.4,.5 ), dpi=300)
plt.plot( T_i, dP_i, "--", color="gray", label=r"$\dot P_{\rm init}$ (lissé)")
plt.plot( T_o, dP_o, "-", color="orange", label=r"$\dot P_{\rm opt}$ (lissé)")
plt.xscale( "log")
plt.xlabel( "T (Gyr)")
plt.ylabel( r"$\dot P\,(\mathrm{Gyr}^{-1})$")
plt.title( r"Fig. 06 - $\dot{P}(T)$ initial vs optimisé")
plt.grid( True, which="both", linestyle=":", linewidth=0.5)
plt.legend( loc="center right")
fig=plt.gcf(); fig.subplots_adjust( left=0.07,bottom=0.12,right=0.98,top=0.95)

out = (Path( __file__ ).resolve().parents[ 2 ]
/ "zz-figures"
/ "chapter01"
/ "fig_06_comparison.png"
)
plt.savefig( out)

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

parser.add_argument("--seed", type=int, default=None)
parser.add_argument("--dpi", type=int, default=150)
parser.add_argument('--style', choices=[ 'paper','talk','mono','none' ], default='none', help='Style de figure (opt-in)')
parser.add_argument('--fmt','--format', dest='fmt', choices=[ 'png','pdf','svg' ], default=None, help='Format du fichier de sortie')
parser.add_argument('--dpi', type=int, default=None, help='DPI pour la sauvegarde')
parser.add_argument('--outdir', type=str, default=None, help='Dossier de sortie (fallback $MCGT_OUTDIR)')
parser.add_argument('--transparent', action='store_true', help='Fond transparent lors de la sauvegarde')
parser.add_argument('--verbose', action='store_true', help='Verbosity CLI')

args = parser.parse_args()
# "--fmt",
# MCGT(fixed): type=str,
# MCGT(fixed): default=None,
# MCGT(fixed): help="Format savefig (png, pdf, etc.)"
try:
    pass  # auto-added for smoke
except Exception:
    pass  # auto-added by STEP04b
