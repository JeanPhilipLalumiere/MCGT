#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
plot_PT_derivatives.py  ––  Génère figures/PT_derivatives.png
----------------------------------------------------------------
Dérivées (log–log) de la loi de recalibrage temporel

        P(T) = T* · (T / T*)**α

• vitesse         :  dP/dT  = α · (T/T*)**(α-1)
• accélération    : |d²P/dT²| = α(1-α) · (T/T*)**(α-2) / T*

Paramètres (avril 2025) : α = 0.30 ± 0.05.
"""

# ----------------------------------------------------------------------
# 1. Imports
# ----------------------------------------------------------------------
import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path

# ----------------------------------------------------------------------
# 2. Paramètres
# ----------------------------------------------------------------------
T_STAR      = 1.0          # Gyr  (échelle de normalisation)
alpha_cen   = 0.30         # valeur centrale
sigma_alpha = 0.05         # incertitude 1 σ
alpha_low   = alpha_cen - sigma_alpha
alpha_high  = alpha_cen + sigma_alpha

# Grille de temps : 0.01 Gyr → 20 Gyr
T = np.logspace(-2, np.log10(20), 700)   # Gyr

def dP_dT(T_arr: np.ndarray, alpha: float) -> np.ndarray:
    """Première dérivée dP/dT."""
    return alpha * (T_arr / T_STAR) ** (alpha - 1)

def d2P_dT2(T_arr: np.ndarray, alpha: float) -> np.ndarray:
    """Valeur absolue de la seconde dérivée |d²P/dT²|."""
    return np.abs(alpha * (alpha - 1) *
                  (T_arr / T_STAR) ** (alpha - 2) / T_STAR)

# ----------------------------------------------------------------------
# 3. Calculs pour bande ±1σ
# ----------------------------------------------------------------------
v_cen  = dP_dT(T, alpha_cen)
v_low  = dP_dT(T, alpha_low)
v_high = dP_dT(T, alpha_high)

a_cen  = d2P_dT2(T, alpha_cen)
a_low  = d2P_dT2(T, alpha_low)
a_high = d2P_dT2(T, alpha_high)

# ----------------------------------------------------------------------
# 4. Figure
# ----------------------------------------------------------------------
plt.figure(figsize=(6, 4))

# --- vitesse dP/dT -----------------------------------------------------
plt.fill_between(T, v_low, v_high,
                 color="tab:blue", alpha=0.25)      # sans label
plt.loglog(T, v_cen, color="tab:blue", lw=1.8,
           label=fr"$\dot P(T)$ (α = {alpha_cen:.2f})")

# --- accélération |d²P/dT²| -------------------------------------------
plt.fill_between(T, a_low, a_high,
                 color="tab:orange", alpha=0.25)    # sans label
plt.loglog(T, a_cen, color="tab:orange", lw=1.8, ls="--",
           label=fr"$|\ddot P(T)|$ (α = {alpha_cen:.2f})")

plt.xlabel(r"Temps cosmique $T$ [Gyr]")
plt.ylabel(r"Valeur (échelle log)")
plt.grid(True, which="both", ls=":")
plt.legend(frameon=False, fontsize=8)
plt.tight_layout()

# ----------------------------------------------------------------------
# 5. Sauvegarde
# ----------------------------------------------------------------------
Path("../figures").mkdir(exist_ok=True)
out = Path("../figures/PT_derivatives.png")
plt.savefig(out, dpi=300)
plt.close()
print(f"[OK] Figure enregistrée : {out}")
