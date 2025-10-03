#!/usr/bin/env python3
# plot_fig01_chi2_total_vs_q0.py
# Trace χ² total et sa dérivée vs q0⋆ (Chapter 8 – Dark coupling, MCGT)
# Inset centré et légèrement décalé vers le haut

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from pathlib import Path
from matplotlib.ticker import MaxNLocator
from mpl_toolkits.axes_grid1.inset_locator import inset_axes, mark_inset

def main():
    # --- Répertoires ---
    ROOT     = Path(__file__).resolve().parents[2]
    DATA_DIR = ROOT / "zz-data"  / "chapter08"
    FIG_DIR  = ROOT / "zz-figures"  / "chapter08"
    FIG_DIR.mkdir(parents=True, exist_ok=True)

    # --- Chargement des données ---
    df   = pd.read_csv(DATA_DIR / "08_chi2_total_vs_q0.csv", encoding="utf-8")
    q0   = df["q0star"].to_numpy()
    chi2 = df["chi2_total"].to_numpy()
    if "dchi2_smooth" in df:
        dchi2 = df["dchi2_smooth"].to_numpy()
    else:
        dchi2 = np.gradient(chi2, q0)

    # --- Figure principale ---
    fig, ax = plt.subplots(figsize=(8,5), dpi=100)
    ax.plot(q0, chi2, color="C0", lw=2, label=r"$\chi^2$")
    ax.set_xlabel(r"$q_0^\star$", fontsize=14)
    ax.set_ylabel(r"$\chi^2$", fontsize=14, color="C0")
    ax.tick_params(axis="y", labelcolor="C0")
    ax.xaxis.set_major_locator(MaxNLocator(nbins=6, prune="both"))
    ax.yaxis.set_major_locator(MaxNLocator(nbins=6, prune="both"))

    ax2 = ax.twinx()
    ax2.plot(q0, dchi2, color="C1", lw=2, label=r"$d\chi^2/dq_0^\star$")
    ax2.set_ylabel(r"$d\chi^2/dq_0^\star$", fontsize=14, color="C1")
    ax2.tick_params(axis="y", labelcolor="C1")
    ax2.yaxis.set_major_locator(MaxNLocator(nbins=6, prune="both"))

    ax.grid(which="major", linestyle=":", linewidth=0.7)
    ax.minorticks_on()

    # Marges
    xmin, xmax = q0.min(), q0.max()
    xpad = 0.03 * (xmax - xmin)
    ax.set_xlim(xmin - xpad, xmax + xpad)
    cmin, cmax = chi2.min(), chi2.max()
    ypad = 0.10 * (cmax - cmin)
    ax.set_ylim(cmin - ypad, cmax + ypad)

    # --- Minimum et annotation ---
    idx_min    = np.argmin(chi2)
    q0_min     = q0[idx_min]
    chi2_min   = chi2[idx_min]
    ax.plot(q0_min, chi2_min, "o", color="k", markersize=6)
    ax.annotate(
        f"Min χ² = {chi2_min:.1f}\n$q_0^* = {q0_min:.3f}$",
        xy=(q0_min, chi2_min),
        xytext=(0, 30), textcoords="offset points",
        ha="center", va="bottom",
        fontsize=12,
        arrowprops=dict(arrowstyle="->", lw=1.0, color="k",
                        shrinkA=0, shrinkB=2, connectionstyle="angle3")
    )

    # --- Inset légèrement vers le haut ---
    # width="50%", height="5%" du parent, bbox_to_anchor au milieu-haut
    axins = inset_axes(
        ax,
        "80%", "80%",
        loc="upper left",
        bbox_to_anchor=(0.5, 0.6, 0.3, 0.3),
        bbox_transform=ax.transAxes
    )
    lo, hi = q0_min - 0.1, q0_min + 0.1
    mask   = (q0 >= lo) & (q0 <= hi)
    axins.plot(q0[mask], chi2[mask], color="C0", lw=1.5)
    c2min, c2max = chi2[mask].min(), chi2[mask].max()
    cpad = 0.1 * (c2max - c2min)
    axins.set_xlim(lo, hi)
    axins.set_ylim(c2min - cpad, c2max + cpad)
    axins.set_xticks([lo, q0_min, hi])
    axins.set_yticks([])
    axins.grid(True, linestyle=":")

    mark_inset(ax, axins, loc1=2, loc2=4, fc="none", ec="0.5", lw=1)

    # --- Légende en haut à droite ---
    h1, l1 = ax.get_legend_handles_labels()
    h2, l2 = ax2.get_legend_handles_labels()
    ax.legend(h1 + h2, l1 + l2,
              loc="upper right", fontsize=12, frameon=False)

    plt.tight_layout()
    outpath = FIG_DIR / "fig_01_chi2_total_vs_q0.png"
    plt.savefig(outpath, dpi=300)
    print(f"✅ Figure enregistrée → {outpath}")

if __name__ == "__main__":
    main()
