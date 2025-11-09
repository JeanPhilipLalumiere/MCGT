import os
import pathlib

import matplotlib.pyplot as plt
import pandas as pd

# Lire la grille complète
from pathlib import Path
from pathlib import Path
data_path = (Path(__file__).resolve().parents[2] / "zz-data" / "chapter01" / "01_optimized_data.csv")
df = pd.read_csv( data_path)

# Ne conserver que le plateau précoce T <= Tp
Tp = 0.087
df_plateau = df[ df[ "T" ] <= Tp]

T = df_plateau[ "T"]
P = df_plateau[ "P_calc"]

# Tracé continu de P(T) sur le plateau
plt.figure( figsize=( 8, 4.5 ))
plt.plot( T, P, color="orange", linewidth=1.5, label="P(T) optimisé")

# Ligne verticale renforcée à Tp
plt.axvline(Tp, linestyle="--", color="black", linewidth=1.2, label=r"$T_p=0.087\,\mathrm{Gyr}$" )
# Mise en forme
plt.xscale( "log")
plt.xlabel( "T (Gyr)")
plt.ylabel( "P(T)")
plt.title( "Plateau précoce de P(T)")
plt.ylim( 0.98, 1.002)
plt.xlim( df_plateau[ "T" ].min( ), Tp * 1.05)
plt.grid( True, which="both", linestyle=":", linewidth=0.5)
plt.legend( loc="lower right")
fig=plt.gcf(); fig.subplots_adjust( left=0.07,bottom=0.12,right=0.98,top=0.95)

# Sauvegarde
from pathlib import Path
from pathlib import Path
output_path = (Path(__file__).resolve().parents[2] / "zz-figures" / "chapter01" / "fig_01_early_plateau.png")
output_path.parent.mkdir(parents=True, exist_ok=True)
plt.savefig( output_path, dpi=300)

# == MCGT CLI SEED v2 ==
if __name__ == "__main__":
    pass
    pass
pass
def _mcgt_cli_seed():
    pass
pass
pass
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
    os.makedirs(args.outdir, exist_ok=True)
import atexit
import glob
import shutil
import time
_ch = os.path.basename( os.path.dirname( __file__ ))
_repo = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
_default_dir = os.path.join( _repo, "zz-figures", _ch)
_t0 = time.time()

def _smoke_copy_latest():
    import os, glob, shutil, time
    _repo = os.path.abspath(os.path.join(__file__, "..", "..", ".."))
    _ch   = "chapter01"
    _default_dir = os.path.join(_repo, "zz-figures", _ch)
    _t0 = time.time()
    pngs = sorted(glob.glob(os.path.join(_default_dir, "*.png")), key=os.path.getmtime, reverse=True)
    for _p in pngs:
        if os.path.getmtime(_p) >= _t0 - 10:
            _dst = os.path.join(args.outdir, os.path.basename(_p))
            if not os.path.exists(_dst):
                shutil.copy2(_p, _dst)
            break



# === MCGT:CLI-SHIM-BEGIN ===
# Idempotent. Expose: --out/--dpi/--format/--transparent/--style/--verbose
# Ne modifie pas la logique existante : parse_known_args() au module-scope.

def _mcgt_cli_shim_parse_known():
    import argparse, sys
    p = argparse.ArgumentParser(add_help=False)
    p.add_argument("--out", type=str, default=None, help="Chemin de sortie (optionnel).")
    p.add_argument("--dpi", type=int, default=None, help="DPI de sortie (optionnel).")
    p.add_argument("--format", type=str, default=None, choices=["png","pdf","svg"], help="Format de sortie.")
    p.add_argument("--transparent", action="store_true", help="Fond transparent si supporté.")
    p.add_argument("--style", type=str, default=None, help="Style matplotlib (optionnel).")
    p.add_argument("--verbose", action="store_true", help="Verbosité accrue.")
    args, _ = p.parse_known_args(sys.argv[1:])
    try:
        import matplotlib as _mpl
        if args.style:
            import matplotlib.pyplot as _plt  # force init si besoin
            _mpl.style.use(args.style)
        if args.dpi and hasattr(_mpl, "rcParams"):
            _mpl.rcParams["figure.dpi"] = int(args.dpi)
    except Exception:
        # Ne jamais casser le producteur si style/DPI échoue.
        pass
    return args

try:
    MCGT_CLI = _mcgt_cli_shim_parse_known()
except Exception:
    MCGT_CLI = None
# === MCGT:CLI-SHIM-END ===

