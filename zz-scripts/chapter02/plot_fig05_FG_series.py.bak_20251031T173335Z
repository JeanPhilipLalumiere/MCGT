#!/usr/bin/env python3
"""
Tracer les séries brutes F(α)−1 et G(α) pour le Chapitre 2 (MCGT)

Produit :
- zz-figures/chapter02/02_fig_05_fg_series.png

Données sources :
- zz-data/chapter02/02_As_ns_vs_alpha.csv
"""

from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd

# Constantes Planck 2018
A_S0 = 2.10e-9
NS0 = 0.9649

# Chemins
ROOT = Path(__file__).resolve().parents[2]
DATA_IN = ROOT / "zz-data" / "chapter02" / "02_As_ns_vs_alpha.csv"
OUT_PLOT = ROOT / "zz-figures" / "chapter02" / "fig_05_FG_series.png"


def main():
    # Lecture des données
    df = pd.read_csv(DATA_IN)
    alpha = df["alpha"].values
    As = df["A_s"].values
    ns = df["n_s"].values

    # Calcul des séries
    Fm1 = As / A_S0 - 1.0
    Gm = ns - NS0

    # Tracé
    plt.figure()
    plt.plot(alpha, Fm1, marker="o", linestyle="-", label=r"$F(\alpha)-1$")
    plt.plot(alpha, Gm, marker="s", linestyle="--", label=r"$G(\alpha)$")
    plt.xlabel(r"$\alpha$")
    plt.ylabel("Valeur")
    plt.title("Séries $F(\\alpha)-1$ et $G(\\alpha)$")
    plt.grid(True, which="both", ls=":")
    plt.legend()
    fig.subplots_adjust(left=0.04, right=0.98, bottom=0.06, top=0.96)
    plt.savefig(OUT_PLOT, dpi=300)
    plt.close()
    print(f"Figure enregistrée → {OUT_PLOT}")


if __name__ == "__main__":
    main()

# [MCGT POSTPARSE EPILOGUE v2]
# (compact) delegate to common helper; best-effort wrapper
try:
    import os
    import sys
    _here = os.path.abspath(os.path.dirname(__file__))
    _zz = os.path.abspath(os.path.join(_here, ".."))
    if _zz not in sys.path:
        sys.path.insert(0, _zz)
    from _common.postparse import apply as _mcgt_postparse_apply
except Exception:
    def _mcgt_postparse_apply(*_a, **_k):
        pass
try:
    if "args" in globals():
        _mcgt_postparse_apply(args, caller_file=__file__)
except Exception:
    pass
