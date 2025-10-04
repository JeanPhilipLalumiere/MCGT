#!/usr/bin/env python3
"""
zz-scripts/chapter08/plot_fig06_normalized_residuals_distribution.py

Distribution des pulls (résidus normalisés) pour BAO et Supernovae.
Rug‐plot + KDE pour BAO, histogramme pour Supernovae
"""

import sys
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from scipy.stats import gaussian_kde, norm

# --- pour importer cosmo.py depuis utils ---
ROOT = Path(__file__).resolve().parents[2]
UTILS = ROOT / "zz-scripts" / "chapter08" / "utils"
sys.path.insert(0, str(UTILS))
from cosmo import DV, distance_modulus


def main():
    # Répertoires
    DATA_DIR = ROOT / "zz-data" / "chapter08"
    FIG_DIR = ROOT / "zz-figures" / "chapter08"
    FIG_DIR.mkdir(parents=True, exist_ok=True)

    # Lecture des données
    bao = pd.read_csv(DATA_DIR / "08_bao_data.csv", encoding="utf-8")
    pant = pd.read_csv(DATA_DIR / "08_pantheon_data.csv", encoding="utf-8")
    df1d = pd.read_csv(DATA_DIR / "08_chi2_total_vs_q0.csv", encoding="utf-8")

    # q0* optimal
    q0_star = df1d.loc[df1d["chi2_total"].idxmin(), "q0star"]

    # Calcul des pulls BAO
    z_bao = bao["z"].values
    dv_obs = bao["DV_obs"].values
    dv_sig = bao["sigma_DV"].values
    dv_th = np.array([DV(z, q0_star) for z in z_bao])
    pulls_bao = (dv_obs - dv_th) / dv_sig

    # Calcul des pulls Supernovae
    z_sn = pant["z"].values
    mu_obs = pant["mu_obs"].values
    mu_sig = pant["sigma_mu"].values
    mu_th = np.array([distance_modulus(z, q0_star) for z in z_sn])
    pulls_sn = (mu_obs - mu_th) / mu_sig

    # Statistiques
    mu_bao, sigma_bao, N_bao = pulls_bao.mean(), pulls_bao.std(ddof=1), len(pulls_bao)
    mu_sn, sigma_sn, N_sn = pulls_sn.mean(), pulls_sn.std(ddof=1), len(pulls_sn)

    # Plot
    plt.rcParams.update({"font.size": 11})
    fig, axes = plt.subplots(1, 2, figsize=(10, 4))

    # (a) BAO – rug + KDE
    ax = axes[0]
    ax.plot(pulls_bao, np.zeros_like(pulls_bao), "|", ms=20, mew=2, label="BAO pulls")
    kde = gaussian_kde(pulls_bao)
    xk = np.linspace(pulls_bao.min() - 1, pulls_bao.max() + 1, 300)
    ax.plot(xk, kde(xk), "-", lw=2, label="KDE")
    # Annotation μ,σ,N en haut-gauche
    txt_bao = rf"$\mu={mu_bao:.2f},\ \sigma={sigma_bao:.2f},\ N={N_bao}$"
    ax.text(
        0.02,
        0.95,
        txt_bao,
        transform=ax.transAxes,
        va="top",
        ha="left",
        bbox=dict(boxstyle="round,pad=0.3", fc="white", ec="0.5"),
    )
    ax.set_title("(a) BAO")
    ax.set_xlabel("Pull")
    ax.set_ylabel("Densité")
    ax.set_ylim(0, 0.1)
    ax.legend(loc="upper right", frameon=False)
    ax.grid(ls=":", lw=0.5, alpha=0.6)

    # (b) Supernovae – histogramme
    ax = axes[1]
    bins = np.linspace(-5, 5, 50)
    ax.hist(
        pulls_sn,
        bins=bins,
        density=True,
        histtype="stepfilled",
        alpha=0.8,
        color="#FF8C00",
        label="SNe pulls",
    )
    x = np.linspace(-5, 5, 400)
    ax.plot(x, norm.pdf(x, 0, 1), "k--", lw=2, label=r"$\mathcal{N}(0,1)$")
    txt_sn = rf"$\mu={mu_sn:.2f},\ \sigma={sigma_sn:.2f},\ N={N_sn}$"
    ax.text(
        0.02,
        0.95,
        txt_sn,
        transform=ax.transAxes,
        va="top",
        ha="left",
        bbox=dict(boxstyle="round,pad=0.3", fc="white", ec="0.5"),
    )
    ax.set_title("(b) Supernovae")
    ax.set_xlabel("Pull")
    ax.set_ylim(0, 0.9)
    ax.legend(loc="upper right", frameon=False)
    ax.grid(ls=":", lw=0.5, alpha=0.6)

    fig.suptitle("Distribution des pulls (résidus normalisés)", y=1.02, fontsize=14)
    fig.tight_layout()

    out_path = FIG_DIR / "fig_06_pulls.png"
    fig.savefig(out_path, dpi=300, bbox_inches="tight")
    print(f"✅ {out_path.name} générée")


if __name__ == "__main__":
    main()
