import logging
from pathlib import Path
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle, FancyArrowPatch

# --- Logging ---
logging.basicConfig(level=logging.INFO, format='[%(levelname)s] %(message)s')

# --- Paths ---
ROOT    = Path(__file__).resolve().parents[2]
FIG_DIR = ROOT / "zz-figures" / "chapitre6"
FIG_DIR.mkdir(parents=True, exist_ok=True)
OUT_PNG = FIG_DIR / "fig_01_schema_flux_donnees_cmb.png"

# --- Figure setup ---
fig, ax = plt.subplots(figsize=(10, 6), dpi=300)
ax.axis("off")
fig.suptitle(
    "Pipeline de génération des données CMB (Chapitre 6)",
    fontsize=14, fontweight="bold", y=0.96
)

# --- Block parameters ---
W, H   = 0.26, 0.20       # largeur/hauteur des blocs
Ymid   = 0.45             # position centrale en Y
DY     = 0.25             # décalage vertical standard

# --- Blocks definitions ---
blocks = {
    "in":   (0.05,      Ymid,       "pdot_plateau_z.dat",                     "#d7d7d7"),
    "scr":  (0.36,      Ymid,       "generer_donnees_chapitre6.py",           "#a9dfbf"),
    "data": (0.67,      Ymid + DY,  "06_cls_*.dat\n06_delta_*.csv\n06_delta_rs_*.csv\n06_cmb_chi2_scan2D.csv\n06_params_cmb.json", "#d7d7d7"),
    "fig":  (0.67,      Ymid - DY,  "fig_02.png\nfig_03.png\nfig_04.png\nfig_05.png",               "#d7d7d7"),
}

# --- Draw blocks ---
for key, (x, y, label, color) in blocks.items():
    ax.add_patch(Rectangle((x, y), W, H,
                           facecolor=color, edgecolor="k", lw=1.2))
    ax.text(x + W/2, y + H/2, label,
            ha="center", va="center",
            fontsize=8, family="monospace")

# --- Arrow helpers ---
def east_center(x, y): return (x + W, y + H/2)
def west_center(x, y): return (x,     y + H/2)

def draw_arrow(start, end, text, x_off=0, y_off=0):
    ax.add_patch(FancyArrowPatch(
        start, end,
        arrowstyle="-|>", mutation_scale=15,
        lw=1.3, color="k"
    ))
    xm = 0.5*(start[0] + end[0]) + x_off
    ym = 0.5*(start[1] + end[1]) + y_off
    ax.text(xm, ym, text, ha="center", va="center", fontsize=9)

# --- Draw arrows with adjusted offsets ---
# 1) input -> script : label déplacé vers le bas
draw_arrow(
    east_center(*blocks["in"][:2]),
    west_center(*blocks["scr"][:2]),
    "1. Lecture pdot",
    y_off=-DY/1.8
)

# 2) script -> data
draw_arrow(
    east_center(*blocks["scr"][:2]),
    west_center(*blocks["data"][:2]),
    "2. Génération données",
    x_off=+DY/3,
    y_off=-DY/8
)

# 3) script 
draw_arrow(
    east_center(*blocks["scr"][:2]),
    west_center(*blocks["fig"][:2]),
    "3. Export PNG",
    x_off=+DY/4,
    y_off=+DY/8
)

# --- Finalize and save ---
plt.tight_layout(rect=[0, 0, 1, 0.93])
plt.savefig(OUT_PNG)
logging.info(f"Schéma enregistré → {OUT_PNG}")