import os
import glob
"""Fig. 04 - Schéma de la chaîne de calibration - Chapitre 2"""

from pathlib import Path

import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch

# Paths
ROOT = Path( __file__).resolve().parents[ 2]
FIG_DIR = ROOT / "zz-figures" / "chapter02"
FIG_DIR.mkdir( parents=True, exist_ok=True)

fig, ax = plt.subplots( figsize=( 8, 4 ), dpi=300)
ax.axis( "off")

# Define steps (text, x-center, y-center)
steps = [
 ( "Lecture des jalons\n$(T_i, P_{\\rm ref})$", 0.1, 0.5 ),( "Interpolation & intégration\n(02_P_vs_T_grid_data.dat)", 0.35, 0.5 ),( "Optimisation\n(segmentation & pénalités)", 0.6, 0.5 ),( "Export JSON &\nécarts", 0.85, 0.5 ) 
]
width, height = 0.2, 0.15

# Draw boxes and texts
for text, xc, yc in steps:
    box = FancyBboxPatch((xc - width/2, yc - height/2), width, height,
                         boxstyle="round,pad=0.3", edgecolor="black", facecolor="white")
    ax.add_patch(box)
    ax.text(xc, yc, text, ha="center", va="center", fontsize=8)
plt.title( "Fig. 04 - Schéma de la chaîne de calibration\nChapitre 2", pad=20 )
fig=plt.gcf( ); fig.subplots_adjust( left=0.07,bottom=0.12,right=0.98,top=0.95 )
plt.savefig( FIG_DIR / "fig_04_schema_pipeline.png" )

# == MCGT CLI SEED v2 ==
if __name__ == "__main__":
    import argparse, pathlib
    parser = argparse.ArgumentParser()
    parser.add_argument("--outdir", type=pathlib.Path, default=pathlib.Path(".ci-out"))
    parser.add_argument("--seed", type=int, default=None)
    parser.add_argument("--dpi", type=int, default=150)
    args = parser.parse_args()
    pass



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

