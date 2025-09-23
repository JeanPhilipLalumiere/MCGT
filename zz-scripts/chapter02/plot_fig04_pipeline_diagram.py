#!/usr/bin/env python3
"""Fig. 04 – Schéma de la chaîne de calibration – Chapitre 2"""

import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch
from pathlib import Path

# Paths
ROOT = Path(__file__).resolve().parents[2]
FIG_DIR = ROOT / "zz-figures" / "chapter02"
FIG_DIR.mkdir(parents=True, exist_ok=True)

fig, ax = plt.subplots(figsize=(8, 4), dpi=300)
ax.axis("off")

# Define steps (text, x-center, y-center)
steps = [
    ("Lecture des jalons\n$(T_i, P_{\\rm ref})$", 0.1, 0.5),
    ("Interpolation & intégration\n(02_P_vs_T_grid_data.dat)", 0.35, 0.5),
    ("Optimisation\n(segmentation & pénalités)", 0.6, 0.5),
    ("Export JSON &\nécarts", 0.85, 0.5),
]
width, height = 0.2, 0.15

# Draw boxes and texts
for text, xc, yc in steps:
    box = FancyBboxPatch(
        (xc - width / 2, yc - height / 2),
        width,
        height,
        boxstyle="round,pad=0.3",
        edgecolor="black",
        facecolor="white",
    )
    ax.add_patch(box)
    ax.text(xc, yc, text, ha="center", va="center", fontsize=8)

# Draw arrows
for i in range(len(steps) - 1):
    x0 = steps[i][1] + width / 2
    x1 = steps[i + 1][1] - width / 2
    y = steps[i][2]
    ax.annotate("", xy=(x1, y), xytext=(x0, y), arrowprops=dict(arrowstyle="->", lw=1))

plt.title("Fig. 04 – Schéma de la chaîne de calibration\nChapitre 2", pad=20)
plt.tight_layout()
plt.savefig(FIG_DIR / "fig_04_schema_pipeline.png")
