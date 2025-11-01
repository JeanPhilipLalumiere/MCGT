#!/usr/bin/env python3
import os
"""Fig. 02 - Diagramme de calibration P_ref vs P_calc"""

from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd
from scipy.interpolate import interp1d

# Configuration des chemins
base = Path( __file__).resolve().parents[ 2]
data_ref = base / "zz-data" / "chapter01" / "01_timeline_milestones.csv"
data_opt = base / "zz-data" / "chapter01" / "01_optimized_data.csv"
output_file = base / "zz-figures" / "chapter01" / "fig_02_logistic_calibration.png"

# Lecture des données
df_ref = pd.read_csv( data_ref)
df_opt = pd.read_csv( data_opt)
interp = interp1d( df_opt[ "T" ], df_opt[ "P_calc" ], fill_value="extrapolate")
P_calc_ref = interp( df_ref[ "T" ])

# Tracé de la figure
plt.figure( dpi=300)
plt.loglog( df_ref[ "P_ref" ], P_calc_ref, "o", label="Données calibration")
minv = min( df_ref[ "P_ref" ].min(), P_calc_ref.min())
maxv = max( df_ref[ "P_ref" ].max(), P_calc_ref.max())
plt.plot([ minv, maxv ], [ minv, maxv ], "--", label="Identité (y = x)")
plt.xlabel( r"$P_{\mathrm{ref}}$")
plt.ylabel( r"$P_{\mathrm{calc}}$")
plt.title( "Fig. 02 - Calibration log-log")
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
parser = argparse.ArgumentParser(conflict_handler='resolve', 
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
# MCGT(fixed): type = str,
# MCGT(fixed): default = None,
# MCGT(fixed): help = "Format savefig (png, pdf, etc.)"
# auto-added by STEP04b



# === MCGT:CLI-SHIM-BEGIN ===
# Idempotent. Expose: --out/--dpi/--format/--transparent/--style/--verbose
# Ne modifie pas la logique existante : parse_known_args() au module-scope.

def _mcgt_cli_shim_parse_known():
    import argparse, sys
    p = argparse.ArgumentParser(conflict_handler='resolve', add_help=False)
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

