#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Figure 07 – Invariant scalaire I₂ = k·(δφ/φ)
Chapitre 7 – Perturbations scalaires (MCGT).
"""

import json
import logging
from pathlib import Path

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt


def main():
    # --- chemins ---
    ROOT = Path(__file__).resolve().parents[2]
    DATA_DIR = ROOT / "zz-data" / "chapter07"
    CSV_DATA = DATA_DIR / "07_scalar_perturbations_results.csv"
    JSON_META = DATA_DIR / "07_meta_perturbations.json"
    FIG_DIR = ROOT / "zz-figures" / "chapter07"
    FIG_OUT = FIG_DIR / "fig_07_invariant_I2.png"
    FIG_DIR.mkdir(parents=True, exist_ok=True)

    # --- logging ---
    logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")
    logging.info("→ génération de la figure 07 – Invariant I₂")

    # --- chargement des données ---
    df = pd.read_csv(CSV_DATA)
    if df.empty:
        raise RuntimeError(f"Aucune donnée dans {CSV_DATA}")
    if "delta_phi_interp" not in df.columns:
        raise KeyError("La colonne 'delta_phi_interp' est introuvable dans le CSV")

    k = df["k"].to_numpy()
    delta_phi = df["delta_phi_interp"].to_numpy()

    # --- calcul de I₂ ---
    I2 = k * delta_phi

    # --- lecture de k_split ---
    if JSON_META.exists():
        meta = json.loads(JSON_META.read_text("utf-8"))
        k_split = float(meta.get("x_split", 0.02))
    else:
        logging.warning("Méta-paramètres non trouvés → k_split=0.02")
        k_split = 0.02
    logging.info("k_split = %.2e h/Mpc", k_split)

    # --- préparation du tracé ---
    fig, ax = plt.subplots(figsize=(8, 5))
    ax.loglog(
        k, I2, color="C3", linewidth=2, label=r"$I_2(k)=k\,\frac{\delta\phi}{\phi}$"
    )

    # --- bornes Y centrées sur le plateau (k < k_split) ---
    mask_plateau = k < k_split
    if not np.any(mask_plateau):
        raise RuntimeError("Aucune valeur de k < k_split pour définir le plateau.")
    bottom = I2[mask_plateau].min() * 0.5
    top = I2[mask_plateau].max() * 1.2
    ax.set_ylim(bottom, top)

    # --- ligne verticale k_split ---
    ax.axvline(k_split, color="k", ls="--", lw=1)
    ax.text(
        k_split,
        bottom * 1.2,
        r"$k_{\rm split}$",
        ha="center",
        va="bottom",
        fontsize=10,
        backgroundcolor="white",
    )

    # --- annotation Plateau ---
    x_plt = k[mask_plateau][len(k[mask_plateau]) // 2]
    y_plt = I2[mask_plateau].mean()
    ax.text(
        x_plt,
        y_plt,
        "Plateau",
        fontsize=9,
        bbox=dict(boxstyle="round,pad=0.3", fc="white", ec="gray", alpha=0.7),
    )

    # --- axes, titre, labels ---
    ax.set_xlabel(r"$k\;[h/\mathrm{Mpc}]$", fontsize=12)
    ax.set_ylabel(r"$I_2(k)$", fontsize=12)
    ax.set_title("Invariant scalaire $I_2(k)$", fontsize=14)

    # --- ticks Y explicites ---
    dmin = int(np.floor(np.log10(bottom)))
    dmax = int(np.ceil(np.log10(top)))
    decades = np.arange(dmin, dmax + 1)
    y_ticks = 10.0**decades
    ax.set_yticks(y_ticks)
    ax.set_yticklabels([f"$10^{{{d}}}$" for d in decades])

    # --- grille et légende ---
    ax.grid(which="both", ls=":", lw=0.5, color="gray", alpha=0.7)
    ax.legend(loc="upper right", frameon=True)

    # --- sauvegarde ---
    fig.tight_layout()
    fig.savefig(FIG_OUT, dpi=300)
    logging.info("Figure enregistrée → %s", FIG_OUT)


if __name__ == "__main__":
    main()
