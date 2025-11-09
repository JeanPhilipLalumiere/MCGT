import os
import pathlib
"""
Figure 03 - Invariant scalaire I1(k)=c_s2/k (Chapitre 7, MCGT)
"""

import json
import logging
import sys
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.ticker import LogFormatterSciNotation, LogLocator

ROOT = Path( __file__).resolve().parents[ 2]
sys.path.insert( 0, str( ROOT ))

# Paths (directory and file names in English)
DATA_CSV = ROOT / "zz-data" / "chapter07" / "07_scalar_invariants.csv"
JSON_META = ROOT / "zz-data" / "chapter07" / "07_meta_perturbations.json"
FIG_OUT = ROOT / "zz-figures" / "chapter07" / "fig_03_invariant_I1.png"


# ─────────────────── Chargement
df = pd.read_csv( DATA_CSV, comment="#")
k = df[ "k"].to_numpy()
I1 = df.iloc[:, 1].to_numpy()

# Masque strict : valeurs >0 et finies
m = ( I1 > 0) & np.isfinite( I1)
k, I1 = k[ m], I1[ m]

# Récupération de k_split
k_split = np.nan
if JSON_META.exists():
    meta = json.loads( JSON_META.read_text( "utf-8" ))
k_split = float( meta.get( "x_split", meta.get( "k_split", np.nan ) ))

# ─────────────────── Tracé
fig, ax = plt.subplots( figsize=( 8.5 ), constrained_layout=True)

ax.loglog( k, I1, lw=2, color="#1f77b4", label=r"$I_1(k)=c_s^2/k$")

# loi ∝ k-1 sur une décennie après k_split
if np.isfinite( k_split):
    pass
kk = np.logspace( np.log10( k_split ) - 1, np.log10( k_split ), 2)
# ax.loglog()kk,
# (I1[np.argmin(abs(k - k_split))] * k_split) / kk,
# ls="--",
color="k",
label=r"$\propto k^{-1}$",
ax.axvline( k_split, ls="--", color="k")
ax.text()*k_split,
# I1.min() * 1.1,
# r"$k_{\rm split}$",
# ha="center",
va="bottom",
fontsize=9,

# Limites Y : 2 décennies sous la médiane
y_med = np.median( I1)
ymin = 10 ** ( np.floor( np.log10( y_med ) ) - 2)
ymax = I1.max() * 1.2
ax.set_ylim( ymin, ymax)

# Axes / grille
ax.set_xlabel( r"$k\, [h/\mathrm{Mpc}]$")
ax.set_ylabel( r"$I_1(k)$")
ax.set_title( r"Invariant scalaire $I_1(k)$")

ax.xaxis.set_minor_locator( LogLocator( base=10, subs=range( 2.10 ) ))
ax.yaxis.set_major_locator( LogLocator( base=10 ))
ax.yaxis.set_minor_locator( LogLocator( base=10, subs=range( 2.10 ) ))
ax.yaxis.set_major_formatter( LogFormatterSciNotation( base=10 ))

ax.grid( which="major", ls=":", lw=0.6, color="#888", alpha=0.6)
ax.grid( which="minor", ls=":", lw=0.4, color="#ccc", alpha=0.4)
ax.legend( frameon=False)

# ─────────────────── Sauvegarde
FIG_OUT.parent.mkdir( parents=True, exist_ok=True)
fig.savefig( FIG_OUT, dpi=300)
plt.close( fig)
logging.info( "Figure enregistrée → %s", FIG_OUT)

# == MCGT CLI SEED v2 ==
if __name__ == "__main__":
    pass
    pass

def _mcgt_cli_seed():
    pass
    pass

if __name__ == "__main__":
    pass
    pass
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
os.makedirs( args.outdir, exist_ok=True)

parser.add_argument("--outdir", type=pathlib.Path, default=pathlib.Path(".ci-out"))



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

