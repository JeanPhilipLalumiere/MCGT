#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Figure 03 – Invariant scalaire I₁(k)=c_s²(k)/k (Chapitre 7, MCGT)
"""

import json
import logging
import sys
from pathlib import Path

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.ticker import LogLocator, LogFormatterSciNotation

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

DATA_CSV = ROOT / "zz-data/chapter07/07_scalar_invariants.csv"
JSON_META = ROOT / "zz-data/chapter07/07_params_perturbations.json"
FIG_OUT = ROOT / "zz-figures/chapter07/fig_03_invariant_I1.png"

logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")

# ─────────────────── Chargement
df = pd.read_csv(DATA_CSV, comment="#")
k = df["k"].to_numpy()
I1 = df.iloc[:, 1].to_numpy()

# Masque strict : valeurs >0 et finies
m = (I1 > 0) & np.isfinite(I1)
k, I1 = k[m], I1[m]

# Récupération de k_split
k_split = np.nan
if JSON_META.exists():
    meta = json.loads(JSON_META.read_text("utf-8"))
    k_split = float(meta.get("x_split", meta.get("k_split", np.nan)))

# ─────────────────── Tracé
fig, ax = plt.subplots(figsize=(8, 5), constrained_layout=True)

ax.loglog(k, I1, lw=2, color="#1f77b4", label=r"$I_1(k)=c_s^2/k$")

# loi ∝ k⁻¹ sur une décennie après k_split
if np.isfinite(k_split):
    kk = np.logspace(np.log10(k_split) - 1, np.log10(k_split), 2)
    ax.loglog(
        kk,
        (I1[np.argmin(abs(k - k_split))] * k_split) / kk,
        ls="--",
        color="k",
        label=r"$\propto k^{-1}$",
    )
    ax.axvline(k_split, ls="--", color="k")
    ax.text(
        k_split,
        I1.min() * 1.1,
        r"$k_{\rm split}$",
        ha="center",
        va="bottom",
        fontsize=9,
    )

# Limites Y : 2 décennies sous la médiane
y_med = np.median(I1)
ymin = 10 ** (np.floor(np.log10(y_med)) - 2)
ymax = I1.max() * 1.2
ax.set_ylim(ymin, ymax)

# Axes / grille
ax.set_xlabel(r"$k\, [h/\mathrm{Mpc}]$")
ax.set_ylabel(r"$I_1(k)$")
ax.set_title(r"Invariant scalaire $I_1(k)$")

ax.xaxis.set_minor_locator(LogLocator(base=10, subs=range(2, 10)))
ax.yaxis.set_major_locator(LogLocator(base=10))
ax.yaxis.set_minor_locator(LogLocator(base=10, subs=range(2, 10)))
ax.yaxis.set_major_formatter(LogFormatterSciNotation(base=10))

ax.grid(which="major", ls=":", lw=0.6, color="#888", alpha=0.6)
ax.grid(which="minor", ls=":", lw=0.4, color="#ccc", alpha=0.4)

ax.legend(frameon=False)

# ─────────────────── Sauvegarde
FIG_OUT.parent.mkdir(parents=True, exist_ok=True)
fig.savefig(FIG_OUT, dpi=300)
plt.close(fig)
logging.info("Figure enregistrée → %s", FIG_OUT)
