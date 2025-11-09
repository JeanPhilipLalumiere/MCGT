from _common import cli as C
import argparse
#!/usr/bin/env python3
# fichier : zz-scripts/chapter08/plot_fig04_chi2_heatmap.py
# répertoire : zz-scripts/chapter08
import os
"""
zz-scripts/chapter08/plot_fig04_chi2_heatmap.py
Carte de chaleur χ2(q0⋆, p2) avec contours de confiance
"""

from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.colors import LogNorm

from _common.cli import add_common_plot_args, finalize_plot_from_args, init_logging

# --- chemins ---
ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = ROOT / "zz-data" / "chapter08"
FIG_DIR = ROOT / "zz-figures" / "chapter08"
FIG_DIR.mkdir(parents=True, exist_ok=True)

# --- importer le scan 2D ---
csv2d = DATA_DIR / "08_chi2_scan2D.csv"
if not csv2d.exists():
    raise FileNotFoundError(f"Scan 2D χ2 introuvable : {csv2d}")
df = pd.read_csv(csv2d)

# extraire les grilles
p1 = np.sort(df["q0star"].unique())
p2 = np.sort(df["param2"].unique())

# pivoter en matrice
M = df.pivot(index="param2", columns="q0star", values="chi2").loc[p2, p1].values

# calculer les bords pour pcolormesh
dp1 = np.diff(p1).mean()
dp2 = np.diff(p2).mean()
x_edges = np.concatenate([p1 - dp1 / 2, [p1[-1] + dp1 / 2]])
y_edges = np.concatenate([p2 - dp2 / 2, [p2[-1] + dp2 / 2]])

# trouver le minimum global
i_min, j_min = np.unravel_index(np.argmin(M), M.shape)
q0_min = p1[j_min]
p2_min = p2[i_min]
chi2_min = M[i_min, j_min]

# tracer
plt.rcParams.update({"font.size": 12})
fig, ax = plt.subplots(figsize=(7.5))

# heatmap en lognorm pour renforcer le contraste
pcm = ax.pcolormesh(
x_edges,
y_edges,
M,
norm=LogNorm(vmin=M.min(), vmax=M.max()),
cmap="viridis",
shading="auto",
)

# contours de confiance Δχ² = 2.30, 6.17, 11.8 (68%, 95%, 99.7% pour 2 paramètres)
levels = chi2_min + np.array([2.30, 6.17, 11.8])
cont = ax.contour(
p1,
p2,
M,
levels=levels,
colors="white",
linestyles=["-", "--", ":"],
linewidths=1.2,
)
ax.clabel(
cont,
fmt={lvl: f"{int(lvl - chi2_min)}" for lvl in levels},
inline=True,
fontsize=10,
)

# point du minimum
ax.plot(q0_min, p2_min, "o", color="black", ms=6)

# annotation du minimum
bbox = dict(boxstyle="round,pad=0.4", fc="white", ec="gray", alpha=0.8)
txt = f"min χ² = {chi2_min:.1f}\nq₀⋆ = {q0_min:.3f}, p₂ = {p2_min:.3f}"
ax.text(0.98, 0.95, txt, transform=ax.transAxes, va="top", ha="right", bbox=bbox)

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

fig.subplots_adjust(left=0.04, right=0.98, bottom=0.06, top=0.96)
fig.savefig(FIG_DIR / "fig_04_chi2_heatmap.png", dpi=300)
print(f"✅ fig_04_chi2_heatmap.png générée dans {FIG_DIR}")

# === MCGT CLI SEED v2 ===
if __name__ == "__main__":
    def _mcgt_cli_seed():
        import os, argparse, sys, traceback
parser = argparse.ArgumentParser(
add_common_plot_args(parser)
description="Standard CLI seed (non-intrusif).")
parser.add_argument("--outdir", default=os.environ.get("MCGT_OUTDIR", ".ci-out"), help="Dossier de sortie (par défaut: .ci-out)")
parser.add_argument("--dry-run", action="store_true", help="Ne rien écrire, juste afficher les actions.")
parser.add_argument("--seed", type=int, default=None, help="Graine aléatoire (optionnelle).")
parser.add_argument("--force", action="store_true", help="Écraser les sorties existantes si nécessaire.")
parser.add_argument("-v", "--verbose", action="count", default=0, help="Verbosity cumulable (-v, -vv).")
parser.add_argument("--dpi", type=int, default=150, help="Figure DPI (default: 150)")
parser.add_argument("--format", choices=["png","pdf","svg"], default="png", help="Figure format")
parser.add_argument("--transparent", action="store_true", help="Transparent background")
parser.add_argument("--out", default="plot.png", help="output image path")
parser.add_argument("--figsize", default="9,6", help="figure size W,H (inches)")
args = parser.parse_args()
try:
            os.makedirs(args.outdir, exist_ok=True)
except Exception:
            pass
os.environ["MCGT_OUTDIR"] = args.outdir
import matplotlib as mpl
mpl.rcParams["savefig.dpi"] = args.dpi
mpl.rcParams["savefig.format"] = args.format
mpl.rcParams["savefig.transparent"] = args.transparent
try:
            pass
except Exception:
            pass
_main = globals().get("main")
if callable(_main):
            if True:
                _main(args)
                pass
                pass
                raise
                pass
                print(f"[CLI seed] main() a levé: {e}", file=sys.stderr)
def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="(autofix)",,)
    C.add_common_plot_args(p)
    return p
