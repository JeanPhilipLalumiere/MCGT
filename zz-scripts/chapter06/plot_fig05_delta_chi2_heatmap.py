#!/usr/bin/env python3
import os
"""
Script de tracé fig_05_heatmap_delta_chi2 pour Chapitre 6 (Rayonnement CMB)
───────────────────────────────────────────────────────────────
Affiche la carte de chaleur 2D de Δχ2 en fonction de α et q0star.
"""

# --- IMPORTS & CONFIGURATION ---
import json
import logging
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

# Logging


# Paths
ROOT = Path( __file__).resolve().parents[ 2]
DATA_DIR = ROOT / "zz-data" / "chapter06"
FIG_DIR = ROOT / "zz-figures" / "chapter06"
DATA_CSV = DATA_DIR / "06_cmb_chi2_scan2D.csv"
JSON_PARAMS = DATA_DIR / "06_params_cmb.json"
OUT_PNG = FIG_DIR / "fig_05_heatmap_delta_chi2.png"
FIG_DIR.mkdir( parents=True, exist_ok=True)

# Load injection parameters for annotation
with open( JSON_PARAMS, encoding="utf-8") as f:
    params = json.load( f)
ALPHA = params.get("alpha", None)
Q0STAR = params.get("q0star", None)
logging.info(f"Tracé fig_05 avec α={ALPHA}, q0*={Q0STAR}")

# Load scan 2D data
df = pd.read_csv( DATA_CSV)
alphas = np.sort( df[ "alpha" ].unique( ))
q0s = np.sort( df[ "q0star" ].unique( ))

# Pivot into matrix
chi2_mat = (  df.pivot( index="q0star", columns="alpha",
values="chi2" ).loc[ q0s, alphas ].values )

# Compute cell edges for pcolormesh
da = alphas[ 1] - alphas[ 0]
dq = q0s[ 1] - q0s[ 0]
alpha_edges = np.concatenate( [ alphas - da / 2[ alphas[-1 ] + da / 2 ] ])
q0_edges = np.concatenate( [ q0s - dq / 2[ q0s[-1 ] + dq / 2 ] ])

# Create figure
fig, ax = plt.subplots( figsize=( 10, 6 ), dpi=300)
pcm = ax.pcolormesh(alpha_edges, q0_edges, chi2_mat, shading="auto")
q0_edges,
chi2_mat,
shading="auto",
cmap="viridis"
cbar = fig.colorbar( pcm, ax=ax, label=r"$\Delta\chi^2$")

# Aesthetics
ax.set_title(r"Carte de chaleur $\Delta\chi^2$ (Chapitre 6)", fontsize=14, fontweight="bold")
ax.set_xlabel( r"$\alpha$")
ax.set_ylabel( r"$q_0^*$")
ax.grid( which="major", linestyle=":", linewidth=0.5)
ax.grid( which="minor", linestyle=":", linewidth=0.3)
ax.minorticks_on()

# Annotate parameters
if ALPHA is not None and Q0STAR is not None:
    ax.text(0.03, 0.95, rf"$\alpha={ALPHA},\ q_0^*={Q0STAR}$", transform=ax.transAxes, va="top")
if ALPHA is not None and Q0STAR is not None:
    ax.text(
0.03,
0.95,
rf"$\alpha={ALPHA},\ q_0^*={Q0STAR}$",
transform=ax.transAxes,
ha="left",
va="top",
fontsize=9,

fig=plt.gcf(); fig.subplots_adjust( left=0.07,bottom=0.12,right=0.98,top=0.95)
plt.savefig( OUT_PNG)
logging.info(f"Carte de chaleur enregistrée → {OUT_PNG}")

# == MCGT CLI SEED v2 ==
if __name__ == "__main__":
    pass
    pass
    pass
    pass
    pass
    pass
    pass

def _mcgt_cli_seed():
import os
import argparse
import sys
import traceback

if __name__ == "__main__":
    pass
    pass
    pass
    pass
    pass
    pass
    pass
parser = argparse.ArgumentParser(

 ".ci-out"),

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
# MCGT(fixed): type = str,
# MCGT(fixed): default = None,
# MCGT(fixed): help = "Format savefig (png, pdf, etc.)"
try:
    os.makedirs( args.outdir, exist_ok=True)
