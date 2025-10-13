#!/usr/bin/env python3
# tracer_fig08_ricci_fR_contre_T.py

"""
Trace f_R et f_RR aux points jalons en fonction de l’âge de l’Univers (Gyr) — Chapitre 3
=======================================================================================

Entrée :
    zz-data/chapter03/03_ricci_fR_vs_T.csv
Colonnes requises :
    R_over_R0, f_R, f_RR, T_Gyr

Sortie :
    zz-figures/chapter03/03_fig_08_ricci_fr_vs_t.png
"""

import logging
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd

# ----------------------------------------------------------------------
# Configuration logging
# ----------------------------------------------------------------------
logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")
log = logging.getLogger(__name__)

# ----------------------------------------------------------------------
# Chemins
# ----------------------------------------------------------------------
DATA_FILE = Path("zz-data") / "chapter03" / "03_ricci_fR_vs_T.csv"
FIG_DIR = Path("zz-figures") / "chapter03"
FIG_PATH = FIG_DIR / "fig_08_ricci_fR_vs_T.png"


def main() -> None:
    # 1. Lecture des données
    if not DATA_FILE.exists():
        log.error("Fichier introuvable : %s", DATA_FILE)
        return

    df = pd.read_csv(DATA_FILE)
    required = {"R_over_R0", "f_R", "f_RR", "T_Gyr"}
    missing = required - set(df.columns)
    if missing:
        log.error("Colonnes manquantes dans %s : %s", DATA_FILE, missing)
        return

    # 2. Filtrer T>0 et trier
    df = df[df["T_Gyr"] > 0].sort_values("T_Gyr")
    if df.empty:
        log.error("Aucune donnée positive pour T_Gyr dans %s", DATA_FILE)
        return

    # 3. Préparation du dossier figure
    FIG_DIR.mkdir(parents=True, exist_ok=True)

    # 4. Tracé principal avec double axe Y
    fig, ax1 = plt.subplots(dpi=300, figsize=(6, 4))

    # Axe de gauche : f_R
    color1 = "tab:blue"
    ax1.scatter(df["T_Gyr"], df["f_R"], c=color1, marker="o", s=40, label=r"$f_R$")
    ax1.plot(df["T_Gyr"], df["f_R"], c=color1, lw=1, alpha=0.6)
    ax1.set_xscale("log")
    ax1.set_yscale("log")
    ax1.set_xlabel("Âge de l’Univers $T$ (Gyr)")
    ax1.set_ylabel(r"$f_R$", color=color1)
    ax1.tick_params(axis="y", labelcolor=color1)
    ax1.grid(True, which="both", ls=":", alpha=0.3)

    # Axe de droite : f_RR
    ax2 = ax1.twinx()
    color2 = "tab:orange"
    ax2.scatter(df["T_Gyr"], df["f_RR"], c=color2, marker="s", s=50, label=r"$f_{RR}$")
    ax2.plot(df["T_Gyr"], df["f_RR"], c=color2, lw=1, alpha=0.6, linestyle="--")
    ax2.set_yscale("log")
    ax2.set_ylabel(r"$f_{RR}$", color=color2)
    ax2.tick_params(axis="y", labelcolor=color2)

    # 5. Légende commune
    handles1, labels1 = ax1.get_legend_handles_labels()
    handles2, labels2 = ax2.get_legend_handles_labels()
    ax1.legend(
        handles1 + handles2,
        labels1 + labels2,
        loc="best",
        framealpha=0.8,
        edgecolor="black",
    )

    # 6. Titre
    Tmin, Tmax = df["T_Gyr"].min(), df["T_Gyr"].max()
    ax1.set_title(
        rf"Jalons $f_R$ et $f_{{RR}}$ vs âge $T\in[{Tmin:.2f},{Tmax:.2f}]\,$Gyr"
    )

    # 7. Finalisation
    fig.subplots_adjust(left=0.04, right=0.98, bottom=0.06, top=0.96)
    fig.savefig(FIG_PATH)
    plt.close(fig)
    log.info("Figure enregistrée → %s", FIG_PATH)


if __name__ == "__main__":
    main()
