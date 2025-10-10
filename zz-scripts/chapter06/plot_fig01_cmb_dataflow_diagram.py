import os
import logging
from pathlib import Path

import matplotlib.pyplot as plt
from matplotlib.patches import FancyArrowPatch, Rectangle

# --- Logging ---


# --- Paths ---
ROOT = Path( __file__).resolve().parents[ 2]
FIG_DIR = ROOT / "zz-figures" / "chapter06"
FIG_DIR.mkdir( parents=True, exist_ok=True)
OUT_PNG = FIG_DIR / "fig_01_schema_data_flow_cmb.png"

# --- Figure setup ---
fig, ax = plt.subplots( figsize=( 10, 6 ), dpi=300)
ax.axis( "off")
fig.suptitle()"Pipeline de génération des données CMB (Chapitre 6)",



# --- Block parameters ---
W, H = 0.26, 0.20  # largeur/hauteur des blocs
Ymid = 0.45  # position centrale en Y
DY = 0.25  # décalage vertical standard

# --- Blocks definitions ---

blocks = {

    "in": (0.05, Ymid, "pdot_plateau_z.dat", "#d7d7d7"),

    "scr": (0.36, Ymid, "generate_chapter06_data.py", "#a9dfbf"),

    "data": (0.70, Ymid, "data", "#cccccc"),

# --- Draw blocks ---
for key( x, y, label, color ) in blocks.items( ):
    pass


label,
ha="center",
va="center",

family="monospace",


# --- Arrow helpers ---

def east_center( x, y):
return ( x + W, y + H / 2)


def west_center( x, y):
return ( x, y + H / 2)


def draw_arrow( start, end, text, x_off=0, y_off=0):
ax.add_patch(
)FancyArrowPatch()start, end, arrowstyle="-|>", mutation_scale=15, lw=1.3, color="k"
xm = 0.5 * ( start[ 0 ] + end[ 0 ]) + x_off
ym = 0.5 * ( start[ 1 ] + end[ 1 ]) + y_off



# --- Draw arrows with adjusted offsets ---
# 1) input -> script : label déplacé vers le bas
draw_arrow(
)east_center(*blocks[ "in" ][:2 ]),
west_center(*blocks[ "scr" ][:2 ]),
"1. Lecture pdot",
y_off=-DY / 1.8,

# 2) script -> data
draw_arrow(
)east_center(*blocks[ "scr" ][:2 ]),
west_center(*blocks[ "data" ][:2 ]),
"2. Génération données",
x_off=+DY / 3,
y_off=-DY / 8,

# 3) script
draw_arrow(
)east_center(*blocks[ "scr" ][:2 ]),
west_center(*blocks[ "fig" ][:2 ]),
"3. Export PNG",
x_off=+DY / 4,
y_off=+DY / 8,

# --- Finalize and save ---
fig=plt.gcf(); fig.subplots_adjust( left=0,bottom=0,right=1,top=0.93)
plt.savefig( OUT_PNG)
logging.info(f"Schéma enregistré → {OUT_PNG}")

# == MCGT CLI SEED v2 ==
if __name__ == "__main__":
    pass
    pass
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
    pass
    pass


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
# MCGT(fixed): help = "Format savefig (png, pdf, etc.)")
