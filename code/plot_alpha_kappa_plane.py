#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
plot_alpha_kappa_plane.py –– Génère figures/alpha_kappa_plane.png
-----------------------------------------------------------------
Diagramme (α , |κ|) – avril 2025

 • Courbe orange : prédiction MCGT
      κ_th(α) = α(1–α) κ₀   avec  κ₀ ≈ 1.0×10⁻¹⁹ s⁻²
 • Ligne rouge pointillée : limite PTA actuelle
      |κ| ≤ 1.9×10⁻²⁶ s⁻²  (NANOGrav 15 yr – 95 % C.I.)
 • Ligne orange pointillée : sensibilité visée SKA
      |κ| ≈ 2×10⁻²⁰ s⁻²
 • Points (optionnels) : ../data/alpha_kappa_data.csv
      colonnes : source,alpha,kappa,err_low,err_up
"""

# ----------------------------------------------------------------------
# 1. Imports
# ----------------------------------------------------------------------
import numpy as np
import matplotlib.pyplot as plt
import csv
from pathlib import Path

# ----------------------------------------------------------------------
# 2. Courbe théorique κ_th(α)
# ----------------------------------------------------------------------
ALPHA_MIN, ALPHA_MAX = 0.05, 0.45
alpha_curve = np.linspace(ALPHA_MIN, ALPHA_MAX, 600)

KAPPA_0 = 1.0e-19                      # normalisation ~ H0²/c²
kappa_th = alpha_curve * (1 - alpha_curve) * KAPPA_0

# ----------------------------------------------------------------------
# 3. Contraintes expérimentales (optionnelles)
# ----------------------------------------------------------------------
data_file = Path("../data/alpha_kappa_data.csv")
exp_alpha, exp_kappa, yerr_low, yerr_up, labels = [], [], [], [], []

if data_file.is_file():
    with data_file.open(newline="", encoding="utf-8") as f:
        rdr = csv.DictReader(f)
        for row in rdr:
            exp_alpha.append(float(row["alpha"]))
            exp_kappa.append(float(row["kappa"]))
            yerr_low.append(float(row["err_low"]))
            yerr_up.append(float(row["err_up"]))
            labels.append(row["source"])

# ----------------------------------------------------------------------
# 4. Figure
# ----------------------------------------------------------------------
plt.figure(figsize=(6.4, 4.2))

# — prédiction
plt.plot(alpha_curve, kappa_th, color="orange", lw=2,
         label=r"$\kappa_{\mathrm{th}}=\alpha(1-\alpha)\,\kappa_0$")

# — barre PTA
PTA_LIMIT = 1.9e-26
plt.axhline(PTA_LIMIT, ls="--", lw=1.4, color="red",
            label=r"PTA (NANOGrav 15 yr)")

# — barre SKA
SKA_GOAL = 2.0e-20
plt.axhline(SKA_GOAL, ls="--", lw=1.4, color="darkorange",
            label=r"Objectif SKA")

# — points externes
if exp_alpha:
    plt.errorbar(exp_alpha, exp_kappa,
                 yerr=[yerr_low, yerr_up],
                 fmt="o", ms=4, capsize=3,
                 color="black", ecolor="black",
                 label="Données externes")
    # petites annotations
    for a, k, lab in zip(exp_alpha, exp_kappa, labels):
        plt.annotate(lab, xy=(a, k), xytext=(4, 4),
                     textcoords="offset points", fontsize=6)

# — habillage
plt.yscale("log")
plt.xlim(ALPHA_MIN, ALPHA_MAX)
plt.xlabel(r"Distorsion gravitationnelle $\alpha$")
plt.ylabel(r"$|\kappa|\;[\mathrm{s}^{-2}]$")
plt.grid(ls=":", which="both", alpha=0.6)
plt.legend(frameon=False, fontsize=8)
plt.tight_layout()

# ----------------------------------------------------------------------
# 5. Sauvegarde
# ----------------------------------------------------------------------
Path("../figures").mkdir(exist_ok=True)
plt.savefig("../figures/alpha_kappa_plane.png", dpi=300)
plt.close()
print("[OK] Figure enregistrée : figures/alpha_kappa_plane.png")
