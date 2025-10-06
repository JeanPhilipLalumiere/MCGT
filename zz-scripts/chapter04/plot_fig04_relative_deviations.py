#!/usr/bin/env python3
"""
plot_fig04_relative_deviations.py

Script corrigé pour tracer les écarts relatifs des invariants I2 et I3 :
- Lit le CSV des invariants en tenant compte de plusieurs emplacements possibles
- Calcule ε₂ et ε₃ correctement, en ne saturant pas l'échelle avec ε₂ à haute T
- Trace les seuils ±1% et ±10%
- Sauvegarde la figure PNG 800×500 px, DPI 300
"""

import os

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd


def main():
    # ----------------------------------------------------------------------
    # 1bis. Définition de la transition logistique
    # ----------------------------------------------------------------------
    Tp = 0.087  # Gyr, point de transition issu du script d’intégration

    # ----------------------------------------------------------------------
    # 1. Chargement des données
    # ----------------------------------------------------------------------
    possible_paths = [
        "zz-data/chapter04/04_dimensionless_invariants.csv",
        "/mnt/data/04_dimensionless_invariants.csv",
    ]
    df = None
    for path in possible_paths:
        if os.path.isfile(path):
            df = pd.read_csv(path)
            print(f"Chargé {path}")
            break
    if df is None:
        raise FileNotFoundError(f"Aucun CSV trouvé parmi : {possible_paths}")

    for col in ["T_Gyr", "I2", "I3"]:
        if col not in df.columns:
            raise KeyError(f"Colonne '{col}' manquante dans {path}")

    T = df["T_Gyr"].values
    I2 = df["I2"].values
    I3 = df["I3"].values

    # Références théoriques
    I2_ref = 1e-35
    I3_ref = 1e-6

    # ----------------------------------------------------------------------
    # 2. Calcul des écarts relatifs et masquage hors tolérance ±10 %
    # ----------------------------------------------------------------------
    eps2 = (I2 - I2_ref) / I2_ref
    eps3 = (I3 - I3_ref) / I3_ref

    # Pour ne faire apparaître que les écarts dans ±10 %, masquer le reste
    tol = 0.10  # 10 %  → mettre 0.01 pour ±1 %
    eps2_plot = np.where(np.abs(eps2) <= tol, eps2, np.nan)
    eps3_plot = np.where(np.abs(eps3) <= tol, eps3, np.nan)

    # ----------------------------------------------------------------------
    # 3. Création de la figure (zoomée sur ε ∈ [−0.2, 0.2])
    # ----------------------------------------------------------------------
    fig, ax = plt.subplots(figsize=(8, 5), dpi=300)
    ax.set_xscale("log")
    ax.plot(
        T,
        eps2_plot,
        color="C1",
        label=r"$\varepsilon_2 = \frac{I_2 - I_{2,\mathrm{ref}}}{I_{2,\mathrm{ref}}}$",
    )
    ax.plot(
        T,
        eps3_plot,
        color="C2",
        label=r"$\varepsilon_3 = \frac{I_3 - I_{3,\mathrm{ref}}}{I_{3,\mathrm{ref}}}$",
    )

    # Seuils ±1% et ±10%
    ax.axhline(0.01, color="k", linestyle="--", label=r"$\pm1\%$")
    ax.axhline(-0.01, color="k", linestyle="--")
    ax.axhline(0.10, color="gray", linestyle=":", label=r"$\pm10\%$")
    ax.axhline(-0.10, color="gray", linestyle=":")

    # Zoom vertical ±0.2
    ax.set_ylim(-0.2, 0.2)

    # Graduations mineures sur l’axe T
    from matplotlib.ticker import LogLocator

    ax.xaxis.set_minor_locator(LogLocator(base=10.0, subs=range(1, 10)))
    ax.xaxis.set_tick_params(which="minor", length=3)

    # ----------------------------------------------------------------------
    # 4. Titres, légende, grille
    # ----------------------------------------------------------------------
    ax.set_xlabel(r"$T\ (\mathrm{Gyr})$")
    ax.set_ylabel(r"$\varepsilon_i$")

    # Titre principal
    ax.set_title(
        "Fig. 04 – Écarts relatifs des invariants $I_2$ et $I_3$",
        pad=32)

    # Sous-titre pour préciser la plage zoomée
    ax.text(
        0.5,
        1.02,
        "Plage zoomée : |εᵢ| ≤ 0,10",
        transform=ax.transAxes,
        ha="center",
        va="bottom",
        fontsize="small",
    )
    ax.grid(True, which="both", linestyle=":", linewidth=0.5, zorder=0)
    ax.axvline(
        Tp,
        color="C3",
        linestyle=":",
        label=r"$T_p=0.087\ \mathrm{Gyr}$",
        zorder=5 )

    ax.legend(fontsize="small", loc="upper right")

    # ----------------------------------------------------------------------
    # 5. Sauvegarde
    # ----------------------------------------------------------------------
    output_fig = "zz-figures/chapter04/04_fig_04_relative_deviations.png"
    plt.tight_layout()
    plt.savefig(output_fig)
    print(f"Figure sauvegardée : {output_fig}")


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
