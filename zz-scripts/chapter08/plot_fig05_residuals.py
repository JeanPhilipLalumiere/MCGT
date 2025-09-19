#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
zz-scripts/chapter08/tracer_fig05_residus.py

Trace les résidus BAO et Pantheon+ : 
  (a) ΔD_V = D_V^obs - D_V^th  avec barres d'erreur σ_DV
  (b) Δμ   = μ^obs   - μ^th    avec barres d'erreur σ_μ

Échelles homogènes, ±1σ, annotations, légendes internes.
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path

# --- Répertoires ---
ROOT     = Path(__file__).resolve().parents[2]
DATA_DIR = ROOT / "zz-data"  / "chapitre8"
FIG_DIR  = ROOT / "zz-figures" / "chapitre8"
FIG_DIR.mkdir(parents=True, exist_ok=True)

def main():
    # --- Chargement des données BAO + théorique ---
    bao    = pd.read_csv(DATA_DIR / "08_donnees_bao.csv",    encoding="utf-8")
    dv_th  = pd.read_csv(DATA_DIR / "08_dv_theorie_z.csv",   encoding="utf-8")
    df_bao = pd.merge(bao, dv_th, on="z", how="inner")
    df_bao["dv_resid"] = df_bao["DV_obs"] - df_bao["DV_calc"]
    df_bao["dv_err"]   = df_bao["sigma_DV"]

    # --- Chargement des données Pantheon+ + théorique ---
    pant   = pd.read_csv(DATA_DIR / "08_donnees_pantheon.csv", encoding="utf-8")
    mu_th  = pd.read_csv(DATA_DIR / "08_mu_theorie_z.csv",      encoding="utf-8")
    df_pant = pd.merge(pant, mu_th, on="z", how="inner")
    df_pant["mu_resid"] = df_pant["mu_obs"] - df_pant["mu_calc"]
    df_pant["mu_err"]   = df_pant["sigma_mu"]

    # --- Calcul des dispersions σ ---
    dv_std = df_bao["dv_resid"].std()
    mu_std = df_pant["mu_resid"].std()

    # --- Tracé ---
    plt.rcParams.update({"font.size": 11})
    fig, (ax1, ax2) = plt.subplots(2, 1, sharex=True, figsize=(7, 6))

    # (a) BAO
    ax1.errorbar(
        df_bao["z"], df_bao["dv_resid"], yerr=df_bao["dv_err"],
        fmt="o", ms=5, alpha=0.8, capsize=3,
        label=r"$D_V^{\rm obs}-D_V^{\rm th}$"
    )
    ax1.set_xscale("log")
    ax1.set_ylabel(r"$\Delta D_V\ \mathrm{[Mpc]}$")
    ax1.set_ylim(-50, 400)
    ax1.axhline(0,          ls="--", color="black", lw=1)
    ax1.axhline(dv_std,     ls=":",  color="gray",  lw=1, label=r"$\pm1\sigma$")
    ax1.axhline(-dv_std,    ls=":",  color="gray",  lw=1)
    ax1.text(
        0.02, 0.90, "(a) BAO",
        transform=ax1.transAxes, weight="bold"
    )
    ax1.legend(loc="upper right", framealpha=0.5)
    ax1.grid(which="both", ls=":", lw=0.5, alpha=0.6)

    # (b) Supernovae Pantheon+
    ax2.errorbar(
        df_pant["z"], df_pant["mu_resid"], yerr=df_pant["mu_err"],
        fmt="o", ms=4, alpha=0.4, capsize=2,
        label=r"$\mu^{\rm obs}-\mu^{\rm th}$"
    )
    ax2.set_xscale("log")
    ax2.set_ylabel(r"$\Delta \mu\ \mathrm{[mag]}$")
    ax2.set_xlabel("Redshift $z$")
    ax2.set_ylim(-1.0, 1.0)
    ax2.axhline(0,          ls="--", color="black", lw=1)
    ax2.axhline(mu_std,     ls=":",  color="gray",  lw=1)
    ax2.axhline(-mu_std,    ls=":",  color="gray",  lw=1)
    ax2.text(
        0.02, 0.90, "(b) Supernovae",
        transform=ax2.transAxes, weight="bold"
    )
    ax2.legend(loc="upper right", framealpha=0.5)
    ax2.grid(which="both", ls=":", lw=0.5, alpha=0.6)

    # --- Ajustements finaux ---
    fig.suptitle("Résidus en fonction du redshift", y=0.98)
    fig.tight_layout(rect=[0, 0, 1, 0.95])

    outpath = FIG_DIR / "fig_05_residus.png"
    fig.savefig(outpath, dpi=300)
    print(f"✅ {outpath.name} générée")

if __name__ == "__main__":
    main()
