#!/usr/bin/env python3
# tracer_fig02_fR_fRR_contre_R.py
"""
Trace f_R et f_RR en fonction de R/R₀ — Chapitre 3
=================================================

Entrée :
    zz-data/chapter03/03_fR_stability_data.csv
Colonnes requises :
    R_over_R0, f_R, f_RR

Sortie :
    zz-figures/chapter03/03_fig_02_fr_frr_vs_r.png
"""

from pathlib import Path
import logging

import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.ticker import NullLocator, FixedLocator, FuncFormatter

# ----------------------------------------------------------------------
# Configuration logging
# ----------------------------------------------------------------------
logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")
log = logging.getLogger(__name__)

# ----------------------------------------------------------------------
# Chemins
# ----------------------------------------------------------------------
DATA_FILE = Path("zz-data") / "chapter03" / "03_fR_stability_data.csv"
FIG_DIR   = Path("zz-figures") / "chapter03"
FIG_PATH  = FIG_DIR / "fig_02_fR_fRR_vs_R.png"

# ----------------------------------------------------------------------
# Main
# ----------------------------------------------------------------------
def main() -> None:
    # 1. Lecture des données
    if not DATA_FILE.exists():
        log.error("Fichier introuvable : %s", DATA_FILE)
        return

    df = pd.read_csv(DATA_FILE)
    required = {"R_over_R0", "f_R", "f_RR"}
    missing = required - set(df.columns)
    if missing:
        log.error("Colonnes manquantes dans %s : %s", DATA_FILE, missing)
        return

    # 2. Préparation du dossier de sortie
    FIG_DIR.mkdir(parents=True, exist_ok=True)

    # 3. Graphique principal
    fig, ax = plt.subplots(dpi=300, figsize=(6, 4))
    ax.loglog(df["R_over_R0"], df["f_R"],  color="tab:blue",  lw=1.5, label=r"$f_R(R)$")
    ax.loglog(df["R_over_R0"], df["f_RR"], color="tab:orange", lw=1.5, label=r"$f_{RR}(R)$")

    ax.set_xlabel(r"$R/R_0$")
    ax.set_ylabel(r"$f_R,\;f_{RR}$")
    ax.set_title(r"$f_R$ et $f_{RR}$ en fonction de $R/R_0$")
    ax.grid(True, which="both", ls=":", alpha=0.3)

    # 4. Légende à mi-hauteur complètement à gauche
    ax.legend(
        loc="center left",
        bbox_to_anchor=(0.01, 0.5),
        framealpha=0.8,
        edgecolor="black"
    )

    # 5. Inset zoom sur f_RR (premiers 50 points)
    import numpy as np

    df_zoom = df.iloc[:50]
    ax_in = fig.add_axes([0.62, 0.30, 0.30, 0.30])
    ax_in.loglog(df_zoom["R_over_R0"], df_zoom["f_RR"], color="tab:orange", lw=1.5)

    ax_in.set_xscale("log")
    ax_in.set_yscale("linear")
    ax_in.set_xlim(df_zoom["R_over_R0"].min(), df_zoom["R_over_R0"].max())

    # graduations x (4 points logarithmiques)
    lmin, lmax = np.log10(df_zoom["R_over_R0"].min()), np.log10(df_zoom["R_over_R0"].max())
    xticks = 10 ** np.linspace(lmin, lmax, 4)
    ax_in.xaxis.set_major_locator(FixedLocator(xticks))
    ax_in.xaxis.set_major_formatter(FuncFormatter(lambda x, _: f"{x:.0f}"))
    ax_in.xaxis.set_minor_locator(NullLocator())

    # graduations y (4 points linéaires)
    ymin, ymax = df_zoom["f_RR"].min(), df_zoom["f_RR"].max()
    yticks = np.linspace(ymin, ymax, 4)
    ax_in.yaxis.set_major_locator(FixedLocator(yticks))
    ax_in.yaxis.set_major_formatter(FuncFormatter(lambda y, _: f"{y:.2e}"))
    ax_in.yaxis.set_minor_locator(NullLocator())

    ax_in.set_title(r"Zoom $f_{RR}$", fontsize=8)
    ax_in.grid(True, which="both", ls=":", alpha=0.3)

    # 6. Sauvegarde
    plt.tight_layout()
    fig.savefig(FIG_PATH)
    plt.close(fig)
    log.info("Figure enregistrée → %s", FIG_PATH)


if __name__ == "__main__":
    main()
