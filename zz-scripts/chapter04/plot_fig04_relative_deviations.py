#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Fig. 04 — Écarts relatifs des invariants I2 et I3 : ε_i = (I_i - I_i,ref)/I_i,ref
Affiche un zoom |ε_i| ≤ 0.2 avec seuils ±1% et ±10% et T en log.
"""

from pathlib import Path
import argparse
import os

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt


ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "zz-data" / "chapter04" / "04_dimensionless_invariants.csv"
TP_GYR = 0.087  # point de transition (Gyr)


def main():
    parser = argparse.ArgumentParser(
        description="Fig. 04 — Écarts relatifs des invariants I2 et I3"
    )
    parser.add_argument("--outdir", default=os.environ.get("MCGT_OUTDIR", "zz-figures/_smoke/chapter04"))
    parser.add_argument("--dpi", type=int, default=300)
    parser.add_argument("--format", "--fmt", dest="fmt", choices=["png", "pdf", "svg"], default="png")
    parser.add_argument("--transparent", action="store_true")
    parser.add_argument("--tol", type=float, default=0.10, help="Seuil de masquage |ε|≤tol affiché (défaut 0.10)")
    args = parser.parse_args()

    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)
    outpath = outdir / f"fig_04_relative_deviations.{args.fmt}"

    if not DATA.exists():
        raise FileNotFoundError(f"CSV introuvable: {DATA}")

    df = pd.read_csv(DATA)
    for col in ["T_Gyr", "I2", "I3"]:
        if col not in df.columns:
            raise KeyError(f"Colonne manquante: {col}")

    T = pd.to_numeric(df["T_Gyr"], errors="coerce").to_numpy()
    I2 = pd.to_numeric(df["I2"], errors="coerce").to_numpy()
    I3 = pd.to_numeric(df["I3"], errors="coerce").to_numpy()

    # Références
    I2_ref = 1e-35
    I3_ref = 1e-6

    eps2 = (I2 - I2_ref) / I2_ref
    eps3 = (I3 - I3_ref) / I3_ref

    # Masquage hors tolérance (pour ne montrer que la zone zoomée)
    eps2_plot = np.where(np.abs(eps2) <= args.tol, eps2, np.nan)
    eps3_plot = np.where(np.abs(eps3) <= args.tol, eps3, np.nan)

    fig, ax = plt.subplots(figsize=(8, 5), dpi=args.dpi)
    ax.set_xscale("log")
    ax.plot(T, eps2_plot, color="C0", label=r"$\varepsilon_2$")
    ax.plot(T, eps3_plot, color="C2", label=r"$\varepsilon_3$")

    # Seuils ±1% et ±10%
    ax.axhline(0.01, color="k", ls="--", label=r"$\pm 1\%$")
    ax.axhline(-0.01, color="k", ls="--")
    ax.axhline(0.10, color="gray", ls=":", label=r"$\pm 10\%$")
    ax.axhline(-0.10, color="gray", ls=":")

    ax.set_ylim(-0.2, 0.2)
    ax.set_xlabel(r"$T\ \mathrm{(Gyr)}$")
    ax.set_ylabel(r"$\varepsilon_i$")
    ax.set_title("Fig. 04 — Écarts relatifs des invariants $I_2$ et $I_3$", pad=16)
    ax.text(0.5, 1.02, "Plage zoomée : |εᵢ| ≤ 0,10", transform=ax.transAxes, ha="center", va="bottom", fontsize="small")

    # Marqueur de transition
    ax.axvline(TP_GYR, color="C3", ls=":", label=rf"$T_p={TP_GYR}\ \mathrm{{Gyr}}$", zorder=5)

    ax.grid(True, which="both", ls=":", lw=0.6, alpha=0.7)
    ax.legend(loc="upper right", fontsize="small")
    fig.subplots_adjust(left=0.07, right=0.98, bottom=0.10, top=0.90)

    fig.savefig(outpath, transparent=args.transparent)
    print(f"[OK] Figure sauvegardée : {outpath}")


if __name__ == "__main__":
    main()
