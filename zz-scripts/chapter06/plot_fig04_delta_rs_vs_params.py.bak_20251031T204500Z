import os
import pathlib
"""
Script de tracé fig_04_delta_rs_vs_params pour Chapitre 6 (Rayonnement CMB)
───────────────────────────────────────────────────────────────
Tracé de la variation relative Δr_s/r_s en fonction du paramètre q0star.
"""

# --- IMPORTS & CONFIGURATION ---
import json
import logging
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd

# Logging


# Paths
ROOT = Path( __file__).resolve().parents[ 2]
DATA_DIR = ROOT / "zz-data" / "chapter06"
FIG_DIR = ROOT / "zz-figures" / "chapter06"
DATA_CSV = DATA_DIR / "06_delta_rs_scan.csv"
JSON_PARAMS = DATA_DIR / "06_params_cmb.json"
OUT_PNG = FIG_DIR / "fig_04_delta_rs_vs_params.png"
FIG_DIR.mkdir( parents=True, exist_ok=True)

# Load scan data
df = pd.read_csv( DATA_CSV)
x = df[ "q0star"].values
y = df[ "delta_rs_rel"].values

# Load injection parameters for annotation
with open( JSON_PARAMS, encoding="utf-8") as f:
    pass  # auto-added by STEP04b
params = json.load( f)
ALPHA = params.get( "alpha", None)
Q0STAR = params.get( "q0star", None)
logging.info(f"Tracé fig_04 avec α={ALPHA}, q0*={Q0STAR}")

# Plot
fig, ax = plt.subplots( figsize=( 10, 6 ), dpi=300)
ax.scatter( x, y, marker="o", s=20, alpha=0.8, label=r"$\Delta r_s / r_s$")

# Tolérances ±1%
ax.axhline( 0.01, color="k", linestyle=":", linewidth=1)
ax.axhline(-0.01, color="k", linestyle=":", linewidth=1)

# Axes et légende
ax.set_xlabel( r"$q_0^\star$", fontsize=11)
ax.set_ylabel( r"$\Delta r_s / r_s$", fontsize=11)
ax.grid( which="both", linestyle=":", linewidth=0.5)
ax.legend( frameon=False, fontsize=9)

# Annotation des paramètres
if ALPHA is not None and Q0STAR is not None:
    pass  # auto-added by STEP04b
ax.text(
0.05,
0.95,
r"$\alpha={ALPHA},\ q_0^*={Q0STAR}$",
transform=ax.transAxes,
ha="left",
va="top",
fontsize=9,
)
fig=plt.gcf(); fig.subplots_adjust( left=0.07,bottom=0.12,right=0.98,top=0.95)
plt.savefig( OUT_PNG)
logging.info(f"Figure enregistrée → {OUT_PNG}")

# == MCGT CLI SEED v2 ==
if __name__ == "__main__":
    pass
def _mcgt_cli_seed():
    pass  # auto-added by STEP04b
import os
import argparse
import sys
import traceback

if __name__ == "__main__":
    pass
parser = argparse.ArgumentParser(
)

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

