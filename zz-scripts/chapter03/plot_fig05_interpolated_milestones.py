#!/usr/bin/env python3
# tracer_fig05_interpolation_jalons.py

"""
Visualisation de l’interpolation PCHIP vs points de jalons — Chapitre 3
=======================================================================

Entrées :
    zz-data/chapter03/03_ricci_fR_milestones.csv
    zz-data/chapter03/03_fR_stability_data.csv

Colonnes jalons :
    R_over_R0, f_R, f_RR

Sortie :
    zz-figures/chapter03/03_fig_05_interpolated_milestones.png
"""

import logging
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from scipy.interpolate import PchipInterpolator

# ----------------------------------------------------------------------
# Configuration logging
# ----------------------------------------------------------------------
logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")
log = logging.getLogger(__name__)

# ----------------------------------------------------------------------
# Chemins
# ----------------------------------------------------------------------
DATA_DIR = Path("zz-data") / "chapter03"
RAW_FILE = DATA_DIR / "03_ricci_fR_milestones.csv"
GRID_FILE = DATA_DIR / "03_fR_stability_data.csv"
FIG_DIR = Path("zz-figures") / "chapter03"
FIG_PATH = FIG_DIR / "fig_05_interpolated_milestones.png"


def main() -> None:
    # 1. Lecture des données
    if not RAW_FILE.exists() or not GRID_FILE.exists():
        log.error("Fichiers introuvables : %s ou %s", RAW_FILE, GRID_FILE)
        return

    jalons = pd.read_csv(RAW_FILE)
    grid = pd.read_csv(GRID_FILE)

    # On garde seulement R>0 pour log–log
    jalons = jalons[jalons["R_over_R0"] > 0].sort_values("R_over_R0")
    if jalons.empty:
        log.error("Aucun jalon valide dans %s", RAW_FILE)
        return

    # 2. Préparation du dossier figure
    FIG_DIR.mkdir(parents=True, exist_ok=True)

    # 3. Construire l’interpolateur PCHIP sur log10(R/R0)
    logR_j = np.log10(jalons["R_over_R0"].values)
    p_fR = PchipInterpolator(logR_j, np.log10(jalons["f_R"].values), extrapolate=True)
    p_fRR = PchipInterpolator(logR_j, np.log10(jalons["f_RR"].values), extrapolate=True)

    # 4. Grille dense en R/R0 pour tracer la courbe lisse
    logR_min, logR_max = logR_j.min(), logR_j.max()
    logR_dense = np.linspace(logR_min, logR_max, 400)
    R_dense = 10**logR_dense
    fR_dense = 10 ** p_fR(logR_dense)
    fRR_dense = 10 ** p_fRR(logR_dense)

    # 5. Tracé
    fig, ax1 = plt.subplots(dpi=300, figsize=(6, 4))

    #   5a. Courbe PCHIP fR
    color1 = "tab:blue"
    ax1.plot(R_dense, fR_dense, color=color1, lw=1.5, label=r"PCHIP $f_R$")
    #   5b. Points jalons fR
    ax1.scatter(
        jalons["R_over_R0"],
        jalons["f_R"],
        c=color1,
        marker="o",
        s=40,
        alpha=0.8,
        label=r"Jalons $f_R$",
    )

    ax1.set_xscale("log")
    ax1.set_yscale("log")
    ax1.set_xlabel(r"$R/R_0$")
    ax1.set_ylabel(r"$f_R$", color=color1)
    ax1.tick_params(axis="y", labelcolor=color1)
    ax1.grid(True, which="both", ls=":", alpha=0.3)

    #   5c. Courbe PCHIP fRR sur axe droit
    ax2 = ax1.twinx()
    color2 = "tab:orange"
    ax2.plot(
        R_dense,
        fRR_dense,
        color=color2,
        lw=1.5,
        linestyle="--",
        label=r"PCHIP $f_{RR}$",
    )
    #   5d. Points jalons fRR
    ax2.scatter(
        jalons["R_over_R0"],
        jalons["f_RR"],
        c=color2,
        marker="s",
        s=50,
        alpha=0.8,
        label=r"Jalons $f_{RR}$",
    )
    ax2.set_yscale("log")
    ax2.set_ylabel(r"$f_{RR}$", color=color2)
    ax2.tick_params(axis="y", labelcolor=color2)

    # 6. Légende commune
    h1, l1 = ax1.get_legend_handles_labels()
    h2, l2 = ax2.get_legend_handles_labels()
    ax1.legend(h1 + h2, l1 + l2, loc="best", framealpha=0.8, edgecolor="black")

    # 7. Titre
    ax1.set_title("Interpolation PCHIP vs points de jalons")

    # 8. Finalisation et sauvegarde
    fig.tight_layout()
    fig.savefig(FIG_PATH)
    plt.close(fig)
    log.info("Figure enregistrée → %s", FIG_PATH)


if __name__ == "__main__":
    main()
