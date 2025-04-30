#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
plot_Pofz.py  ––  Génère figures/Pofz_log.png
------------------------------------------------
Métrique différentielle du temps

    ��(z) = 1 + β · [(1+z)^3 – 1] / (Ωₘ + 4 Ω_Λ)

Paramètre révisé (avril 2025) :
    β_cen  = –0.70   (valeur centrale)
    β_high = –0.65   (+1 σ)
    β_low  = –0.75   (−1 σ)

La bande orange clair représente l’intervalle ± 1 σ.
"""

# ----------------------------------------------------------------------
# 1. Imports
# ----------------------------------------------------------------------
import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path

# ----------------------------------------------------------------------
# 2. Constantes cosmologiques (Planck 2020)
# ----------------------------------------------------------------------
OMEGA_M = 0.315
OMEGA_L = 0.685
DENOM   = OMEGA_M + 4 * OMEGA_L          # = 3.055

# ----------------------------------------------------------------------
# 3. Paramètre β et incertitude
# ----------------------------------------------------------------------
beta_cen   = -0.70          # valeur centrale révisée
sigma_beta =  0.05          # incertitude 1 σ
beta_low   = beta_cen - sigma_beta
beta_high  = beta_cen + sigma_beta

# ----------------------------------------------------------------------
# 4. Grille de redshift : 10⁻² ≤ z ≤ 10³  (log)
# ----------------------------------------------------------------------
z = np.logspace(-2, 3, 500)              # 0.01 … 1000

def P_of_z(z_arr: np.ndarray, beta: float) -> np.ndarray:
    """��(z) = dτ/dt pour un β donné."""
    return 1.0 + beta * ((1 + z_arr) ** 3 - 1) / DENOM

P_cen  = P_of_z(z, beta_cen)
P_low  = P_of_z(z, beta_low)
P_high = P_of_z(z, beta_high)

# ----------------------------------------------------------------------
# 5. Figure
# ----------------------------------------------------------------------
plt.figure(figsize=(5.4, 4.2))

# Bande ± 1 σ
plt.fill_between(z, P_low, P_high,
                 color="orange", alpha=0.3,
                 label=r"$\beta_c \pm 1\sigma$")

# Courbe centrale
plt.loglog(z, P_cen, lw=2, color="tab:blue",
           label=fr"$\beta={beta_cen:+.2f}$")

# Ligne �� = 1 (horloge standard)
plt.axhline(1.0, ls="--", lw=1.2, color="grey",
            label=r"Horloge standard")

# Habillage
plt.xlabel(r"Redshift $z$")
plt.ylabel(r"$\mathcal{P}(z)=\mathrm d\tau/\mathrm dt$")
plt.ylim(0.3, 1.05)
plt.grid(True, which="both", ls=":")
plt.legend(frameon=False, fontsize=9)
plt.title("Métrique différentielle du temps (β = −0.70 ± 0.05)")
plt.tight_layout()

# ----------------------------------------------------------------------
# 6. Sauvegarde
# ----------------------------------------------------------------------
Path("../figures").mkdir(exist_ok=True)
out = Path("../figures/Pofz_log.png")
plt.savefig(out, dpi=300)
plt.close()
print(f"[OK] Figure enregistrée : {out}")
