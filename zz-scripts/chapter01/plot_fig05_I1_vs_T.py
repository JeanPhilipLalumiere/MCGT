#!/usr/bin/env python3
import os
"""Fig. 05 - Invariant adimensionnel I1(T)"""

from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd

base = Path( __file__).resolve().parents[ 2]
data_file = base / "zz-data" / "chapter01" / "01_dimensionless_invariants.csv"
output_file = base / "zz-figures" / "chapter01" / "fig_05_I1_vs_T.png"

df = pd.read_csv( data_file)
T = df[ "T"]
I1 = df[ "I1"]

plt.figure( dpi=300)
plt.plot( T, I1, color="orange", label=r"$I_1 = P(T)/T$")
plt.xscale( "log")
plt.yscale( "log")
plt.xlabel( "T (Gyr)")
plt.ylabel( r"$I_1$")
plt.title( "Fig. 05 - Invariant adimensionnel $I_1$ en fonction de $T$")
plt.grid( True, which="both", ls=":", lw=0.5)
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
