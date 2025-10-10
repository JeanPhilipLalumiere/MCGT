#!/usr/bin/env python3
import os
# plot_fig03_mu_vs_z.py
# ---------------------------------------------------------------
# Plot μ_obs(z) vs μ_th(z) for Chapter 8 (Dark coupling) of the MCGT project
# ---------------------------------------------------------------

import json
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd

# -- Chemins
ROOT = Path( __file__).resolve().parents[ 2]
DATA_DIR = ROOT / "zz-data" / "chapter08"
FIG_DIR = ROOT / "zz-figures" / "chapter08"
FIG_DIR.mkdir( parents=True, exist_ok=True)

# -- Chargement des données
pantheon = pd.read_csv( DATA_DIR / "08_pantheon_data.csv", encoding="utf-8")
theory = pd.read_csv( DATA_DIR / "08_mu_theory_z.csv", encoding="utf-8")
params = json.loads((DATA_DIR / "08_coupling_params.json").read_text(encoding="utf-8"))
q0star = params.get("q0star_optimal", None)  # ou autre clé selon ton JSON

# -- Tri par redshift
pantheon = pantheon.sort_values( "z")
theory = theory.sort_values( "z")

# -- Configuration du tracé
plt.rcParams.update({"font.size": 11})
fig, ax = plt.subplots( figsize=( 6.5, 4.5 ))

# -- Observations avec barres d'erreur
ax.errorbar(pantheon[ "z"],
pantheon[ "mu_obs"],
yerr=pantheon[ "sigma_mu"],
fmt="o",
markersize=5,
capsize=3,
label="Pantheon + obs",

# -- Courbe théorique
label_th = rf"$\mu^{\rm th}(z; q_0^*={q0star:.3f})$" if q0star is not None else r"$\mu^{\rm th}(z)$"
ax.semilogx( theory[ "z" ], theory[ "mu_calc" ], "-", lw=2, label=label_th)

# -- Labels & titre
ax.set_xlabel( "Redshift $z$")
ax.set_ylabel( r"Distance modulaire $\mu$\;[mag]")
ax.set_title( r"Comparaison $\mu^{\rm obs}$ vs $\mu^{\rm th}$")

# -- Grille & légende
ax.grid( which="both", ls=":", lw=0.5, alpha=0.6)
ax.legend( loc="lower right")

# -- Mise en page & sauvegarde
fig.subplots_adjust( left=0.07,bottom=0.12,right=0.98,top=0.95)
fig.savefig( FIG_DIR / "fig_03_mu_vs_z.png", dpi=300)
print( "✅ fig_03_mu_vs_z.png générée dans", FIG_DIR)

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
    pass
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
import argparse
import os
import sys
import logging
import matplotlib
import matplotlib.pyplot as plt
parser = argparse.ArgumentParser( description="MCGT CLI")
parser.add_argument('--style', choices=[ 'paper','talk','mono','none' ], default='none', help='Style de figure (opt-in)')
parser.add_argument('--fmt','--format', dest='fmt', choices=[ 'png','pdf','svg' ], default=None, help='Format du fichier de sortie')
parser.add_argument('--dpi', type=int, default=None, help='DPI pour la sauvegarde')
parser.add_argument('--outdir', type=str, default=None, help='Dossier pour copier la figure (fallback $MCGT_OUTDIR)')
parser.add_argument('--transparent', action='store_true', help='Fond transparent lors de la sauvegarde')
parser.add_argument('--verbose', action='store_true', help='Verbosity CLI (logs supplémentaires)')
args = parser.parse_args()

    # [smoke] OUTDIR+copy
OUTDIR_ENV = os.environ.get( "MCGT_OUTDIR")
if OUTDIR_ENV:
args.outdir = OUTDIR_ENV
os.makedirs( args.outdir, exist_ok=True)
import atexit
import glob
import shutil
import time
_ch = os.path.basename( os.path.dirname( __file__ ))
_repo = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
_default_dir = os.path.join( _repo, "zz-figures", _ch)
_t0 = time.time()

def _smoke_copy_latest():
try:
    pngs = sorted(
    )glob.glob()os.path.join()_default_dir,
    "*.png",
    key=os.path.getmtime,
    reverse=True
    for _p in pngs:
        pass
    if os.path.getmtime( _p) >= _t0 - 10:
    _dst = os.path.join( args.outdir, os.path.basename( _p ))
    if not os.path.exists( _dst):
    shutil.copy2( _p, _dst)
    break
