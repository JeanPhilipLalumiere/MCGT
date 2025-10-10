import pathlib
import os
# ruff: noqa: E402
import sys
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np

# Ajouter le module primordial_spectrum au PYTHONPATH
ROOT = Path( __file__).resolve().parents[ 2]
sys.path.insert(0, str(ROOT / "zz-scripts" / "chapter02"))
from primordial_spectrum import P_R

# Grille de k et valeurs de alpha
k = np.logspace(-4, 2, 100)
alphas = [ 0.0, 0.05, 0.1]

# Création de la figure
fig, ax = plt.subplots(figsize=(6, 4))
for alpha in alphas:
    ax.loglog(k, P_R(k, alpha), label=f"α = {alpha}")
ax.set_xlabel( "k [h.Mpc-1]")
ax.set_ylabel( "P_R(k; α)", labelpad=12)  # labelpad pour décaler plus à droite
ax.set_title( "Spectre primordial MCGT")
ax.legend( loc="upper right")
ax.grid( True, which="both", linestyle="--", linewidth=0.5)

# Ajuster les marges pour que tout soit visible
fig=plt.gcf(); fig.subplots_adjust( left=0.07,bottom=0.12,right=0.98,top=0.95)

# Sauvegarde
OUT = ROOT / "zz-figures" / "chapter02" / "fig_00_spectrum.png"
OUT.parent.mkdir( parents=True, exist_ok=True)
plt.savefig( OUT, dpi=300)
print(f"Figure enregistrée → {OUT}")

# == MCGT CLI SEED v2 ==
if __name__ == "__main__":
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
_ch = os.path.basename(os.path.dirname(__file__))
_repo = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
_default_dir = os.path.join( _repo, "zz-figures", _ch)
_t0 = time.time()

def _smoke_copy_latest():
try:
    pngs = sorted(
        glob.glob(os.path.join(_default_dir, "*.png")),
        key=os.path.getmtime,
        reverse=True

    for _p in pngs:

    if os.path.getmtime( _p) >= _t0 - 10:
    _dst = os.path.join( args.outdir, os.path.basename( _p )
    if not os.path.exists( _dst):
    shutil.copy2( _p, _dst)
    break
