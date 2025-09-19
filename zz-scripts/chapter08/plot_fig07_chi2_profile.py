#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
zz-scripts/chapter08/tracer_fig07_chi2_profile.py

Trace le profil Δχ² en fonction de q₀⋆ autour du minimum, 
avec annotations des niveaux 1σ, 2σ, 3σ (1 degré de liberté).
"""

import pandas as pd
import matplotlib.pyplot as plt
from pathlib import Path

def main():
    # Répertoires
    ROOT     = Path(__file__).resolve().parents[2]
    DATA_DIR = ROOT / "zz-data" / "chapitre8"
    FIG_DIR  = ROOT / "zz-figures" / "chapitre8"
    FIG_DIR.mkdir(parents=True, exist_ok=True)

    # Chargement du scan 1D χ²
    df = pd.read_csv(DATA_DIR / "08_chi2_total_vs_q0.csv")
    q0 = df["q0star"].values
    chi2 = df["chi2_total"].values

    # Calcul Δχ²
    chi2_min = chi2.min()
    delta_chi2 = chi2 - chi2_min
    idx_min = delta_chi2.argmin()
    q0_best = q0[idx_min]

    # Prépare le tracé
    plt.rcParams.update({"font.size": 12})
    fig, ax = plt.subplots(figsize=(6.5, 4.5))

    # Profil Δχ²
    ax.plot(q0, delta_chi2, color="C0", lw=2,
            label=r"$\Delta\chi^2(q_0^\star)$")

    # Niveaux de confiance (1 dof)
    sigmas = [1.0, 4.0, 9.0]
    styles = ["--", "-.", ":"]
    colors = ["C1"]*3
    for lvl, ls in zip(sigmas, styles):
        ax.axhline(lvl, color="C1", linestyle=ls, lw=1.5)
        # annotation sur la ligne
        ax.text(q0_best + 0.02, lvl + 0.2,
                rf"${int(lvl**0.5)}\sigma$",
                color="C1", va="bottom")

    # Best-fit point
    ax.plot(q0_best, 0.0, "o",
            mfc="white", mec="C0", mew=2, ms=8,
            label=rf"$q_0^* = {q0_best:.3f}$")

    # Zoom autour du minimum
    dx = 0.2
    ax.set_xlim(q0_best - dx, q0_best + dx)
    ax.set_ylim(0, sigmas[-1] * 1.2)

    # Labels et titre
    ax.set_xlabel(r"$q_0^\star$")
    ax.set_ylabel(r"$\Delta\chi^2$")
    ax.set_title(r"Profil $\Delta\chi^2$ en fonction de $q_0^\star$")

    ax.grid(ls=":", lw=0.5, alpha=0.7)

    # Légende
    ax.legend(loc="upper left", frameon=True)

    fig.tight_layout()
    out = FIG_DIR / "fig_07_chi2_profile.png"
    fig.savefig(out, dpi=300)
    print(f"✅ {out.name} générée")

if __name__ == "__main__":
    main()
