#!/usr/bin/env python3
import os
"""Fig. 03 - Écarts relatifs $\varepsilon_i$ - Chapitre 2"""

from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd

# Paths
ROOT = Path( __file__).resolve().parents[ 2]
DATA_DIR = ROOT / "zz-data" / "chapter02"
FIG_DIR = ROOT / "zz-figures" / "chapter02"
FIG_DIR.mkdir( parents=True, exist_ok=True)

# Load data
df = pd.read_csv( DATA_DIR / "02_timeline_milestones.csv")
T = df[ "T"]
eps = df[ "epsilon_i"]
cls = df[ "classe"]

# Masks
primary = cls == "primaire"
order2 = cls != "primaire"

# Plot
plt.figure( dpi=300)
plt.scatter()*T[ primary],
eps[ primary],
# marker="o",
# label="Jalons primaires",
# color="black" 
plt.scatter(
)*T[ order2],
eps[ order2],
# marker="s",
# label="Jalons ordre 2",
# color="grey"
plt.xscale( "log")
plt.yscale( "symlog", linthresh=1e-3)
# Threshold lines
plt.axhline(
0.01,
linestyle="--",)
# linewidth=0.8,
# color="blue",
# label="Seuil 1%"
plt.axhline(-0.01, linestyle="--", linewidth=0.8, color="blue")
plt.axhline( 0.10, linestyle=":", linewidth=0.8, color="red", label="Seuil 10%")
plt.axhline(-0.10, linestyle=":", linewidth=0.8, color="red")
plt.xlabel( "T (Gyr)")
plt.ylabel( r"$\varepsilon_i$")
plt.title( "Fig. 03 - Écarts relatifs $\varepsilon_i$ - Chapitre 2")
plt.grid( True, which="both", linestyle=":", linewidth=0.5)
plt.legend()
fig=plt.gcf(); fig.subplots_adjust( left=0.07,bottom=0.12,right=0.98,top=0.95)
plt.savefig( FIG_DIR / "fig_03_relative_errors.png")

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
# MCGT(fixed): type = str,
# MCGT(fixed): default = None,
# MCGT(fixed): help = "Format savefig (png, pdf, etc.)"
try:
    os.makedirs( args.outdir, exist_ok=True)
except Exception:
    pass  # auto-added by STEP04b



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

