#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
zz-scripts/chapter08/plot_fig04_chi2_heatmap.py
Carte de chaleur χ²(q0⋆, p2) avec contours de confiance
"""

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.colors import LogNorm
from pathlib import Path

# --- chemins ---
ROOT     = Path(__file__).resolve().parents[2]
DATA_DIR = ROOT / "zz-data"  / "chapter08"
FIG_DIR  = ROOT / "zz-figures"  / "chapter08"
FIG_DIR.mkdir(parents=True, exist_ok=True)

# --- importer le scan 2D ---
csv2d = DATA_DIR / "08_chi2_scan2D.csv"
if not csv2d.exists():
    raise FileNotFoundError(f"Scan 2D χ² introuvable : {csv2d}")
df = pd.read_csv(csv2d)

# extraire les grilles
p1 = np.sort(df["q0star"].unique())
p2 = np.sort(df["param2"].unique())

# pivoter en matrice
M = (
    df
    .pivot(index="param2", columns="q0star", values="chi2")
    .loc[p2, p1]
    .values
)

# calculer les bords pour pcolormesh
dp1 = np.diff(p1).mean()
dp2 = np.diff(p2).mean()
x_edges = np.concatenate([p1 - dp1/2, [p1[-1] + dp1/2]])
y_edges = np.concatenate([p2 - dp2/2, [p2[-1] + dp2/2]])

# trouver le minimum global
i_min, j_min = np.unravel_index(np.argmin(M), M.shape)
q0_min       = p1[j_min]
p2_min       = p2[i_min]
chi2_min     = M[i_min, j_min]

# tracer
plt.rcParams.update({"font.size": 12})
fig, ax = plt.subplots(figsize=(7, 5))

# heatmap en lognorm pour renforcer le contraste
pcm = ax.pcolormesh(
    x_edges, y_edges, M,
    norm=LogNorm(vmin=M.min(), vmax=M.max()),
    cmap="viridis",
    shading="auto"
)

# contours de confiance Δχ² = 2.30, 6.17, 11.8 (68%, 95%, 99.7% pour 2 paramètres)
levels = chi2_min + np.array([2.30, 6.17, 11.8])
cont = ax.contour(
    p1, p2, M,
    levels=levels,
    colors="white",
    linestyles=["-","--",":"],
    linewidths=1.2
)
ax.clabel(cont, fmt={lvl:f"{int(lvl-chi2_min)}" for lvl in levels}, inline=True, fontsize=10)

# point du minimum
ax.plot(q0_min, p2_min, "o", color="black", ms=6)

# annotation du minimum
bbox = dict(boxstyle="round,pad=0.4", fc="white", ec="gray", alpha=0.8)
txt = (
    f"min χ² = {chi2_min:.1f}\n"
    f"q₀⋆ = {q0_min:.3f}, p₂ = {p2_min:.3f}"
)
ax.text(
    0.98, 0.95, txt,
    transform=ax.transAxes,
    va="top", ha="right",
    bbox=bbox
)

# axes et titre
ax.set_xlabel(r"$q_0^\star$")
ax.set_ylabel(r"$p_2$")
ax.set_title(r"Carte de chaleur $\chi^2$ (scan 2D)")

# quadrillage discret
ax.grid(True, linestyle=":", linewidth=0.5, alpha=0.5)

# colorbar ajustée
cbar = fig.colorbar(pcm, ax=ax, extend="both")
cbar.set_label(r"$\chi^2$ (log)", labelpad=10)
cbar.ax.yaxis.set_label_position("right")
cbar.ax.tick_params(labelsize=10)

fig.tight_layout()
fig.savefig(FIG_DIR / "fig_04_chi2_heatmap.png", dpi=300)
print(f"✅ fig_04_chi2_heatmap.png générée dans {FIG_DIR}")
