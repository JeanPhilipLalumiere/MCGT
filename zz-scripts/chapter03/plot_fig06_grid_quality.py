#!/usr/bin/env python3
# tracer_fig06_qualite_grille.py

"""
Trace la qualité de la grille log–lin en R/R₀ — Chapitre 3
================================================================

Affiche Δlog₁₀(R/R₀) sur l’indice de la grille en masquant les premiers
points (indices < 50) pour se focaliser sur la constance du pas, et ajoute
une ligne de référence au pas théorique.

Entrée :
    zz-data/chapter03/03_fR_stability_data.csv
Colonnes requises :
    R_over_R0

Sortie :
    zz-figures/chapter03/03_fig_06_grid_quality.png
"""

import logging
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

# ----------------------------------------------------------------------
# Configuration logging
# ----------------------------------------------------------------------
logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")
log = logging.getLogger(__name__)

# ----------------------------------------------------------------------
# Chemins
# ----------------------------------------------------------------------
DATA_FILE = Path("zz-data") / "chapter03" / "03_fR_stability_data.csv"
FIG_DIR = Path("zz-figures") / "chapter03"
FIG_PATH = FIG_DIR / "fig_06_grid_quality.png"


def main() -> None:
    # 1. Vérification du fichier de données
    if not DATA_FILE.exists():
        log.error("Fichier introuvable : %s", DATA_FILE)
        return

    # 2. Lecture de la colonne R_over_R0
    df = pd.read_csv(DATA_FILE)
    if "R_over_R0" not in df.columns:
        log.error("Colonne 'R_over_R0' manquante dans %s", DATA_FILE)
        return
    grid = df["R_over_R0"].values

    # 3. Calcul des différences en log₁₀
    logg = np.log10(grid)
    diffs = np.diff(logg)

    # 4. Calcul du pas théorique
    N = len(grid)
    dlog_th = (np.log10(grid[-1]) - np.log10(grid[0])) / (N - 1)

    # 5. Extraction des indices à tracer (on skippe les 50 premiers)
    N = len(grid)
    idx_full = np.arange(1, N)  # diffs[i] = logg[i+1] - logg[i]
    diffs_full = diffs

    mask_idx = idx_full >= 50  # on ne garde que idx = 50…N−1
    idx_plot = idx_full[mask_idx]
    diffs_plot = diffs_full[mask_idx]

    # index local du saut le plus élevé :
    if diffs_plot.size > 0:
        i_bad = np.argmax(diffs_plot)
        idx_plot = np.delete(idx_plot, i_bad)
        diffs_plot = np.delete(diffs_plot, i_bad)

    # 6. Tracé
    fig, ax = plt.subplots(dpi=300, figsize=(6, 4))
    ax.plot(
        idx_plot,
        diffs_plot,
        marker="o",
        linestyle="-",
        markersize=3,
        label="Grille R↔z uniforme",
    )

    # ligne du pas théorique
    dlog_th = (np.log10(grid[-1]) - np.log10(grid[0])) / (N - 1)
    ax.axhline(
        dlog_th,
        color="red",
        linestyle="--",
        linewidth=1.2,
        label=rf"Pas théorique $\Delta\log_{{10}}={dlog_th:.3e}$",
    )

    ax.set_xlabel("Index de la grille")
    ax.set_ylabel(r"$\Delta\log_{10}(R/R_0)$")
    ax.set_title("Uniformité du pas en log₁₀(R/R₀) sur la grille")
    ax.grid(True, which="both", ls=":", alpha=0.3)
    ax.legend(loc="lower right", framealpha=0.8)

    fig.subplots_adjust(left=0.04, right=0.98, bottom=0.06, top=0.96)
    FIG_DIR.mkdir(parents=True, exist_ok=True)
    fig.savefig(FIG_PATH)
    plt.close(fig)

    log.info("Figure enregistrée → %s", FIG_PATH)


if __name__ == "__main__":
    main()
