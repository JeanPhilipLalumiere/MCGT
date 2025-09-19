#!/usr/bin/env python3
"""
Tracer les séries brutes F(α)−1 et G(α) pour le Chapitre 2 (MCGT)

Produit :
- zz-figures/chapter02/fig_05_series_FG.png

Données sources :
- zz-data/chapter02/02_As_ns_vs_alpha.csv
"""
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from pathlib import Path

# Constantes Planck 2018
A_S0 = 2.10e-9
NS0  = 0.9649

# Chemins
ROOT     = Path(__file__).resolve().parents[2]
DATA_IN  = ROOT / "zz-data" / "chapitre2" / "02_As_ns_vs_alpha.csv"
OUT_PLOT = ROOT / "zz-figures" / "chapitre2" / "fig_05_series_FG.png"

def main():
    # Lecture des données
    df = pd.read_csv(DATA_IN)
    alpha = df["alpha"].values
    As    = df["A_s"].values
    ns    = df["n_s"].values

    # Calcul des séries
    Fm1 = As / A_S0 - 1.0
    Gm  = ns - NS0

    # Tracé
    plt.figure()
    plt.plot(alpha, Fm1, marker="o", linestyle="-", label=r"$F(\alpha)-1$")
    plt.plot(alpha, Gm,  marker="s", linestyle="--", label=r"$G(\alpha)$")
    plt.xlabel(r"$\alpha$")
    plt.ylabel("Valeur")
    plt.title("Séries $F(\\alpha)-1$ et $G(\\alpha)$")
    plt.grid(True, which="both", ls=":")
    plt.legend()
    plt.tight_layout()
    plt.savefig(OUT_PLOT, dpi=300)
    plt.close()
    print(f"Figure enregistrée → {OUT_PLOT}")

if __name__ == "__main__":
    main()
