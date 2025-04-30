#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
plot_Pofz_curve.py  ––  Génère figures/Pofz_curve.png
-----------------------------------------------------
Métrique différentielle du temps
    ��(z)=1 + β·[(1+z)^3 – 1]/(Ω_m + 4Ω_Λ)

Courbes pour β = −0.65, −0.70 (centrale), −0.75
Révision avril 2025 (β de référence −0.70).
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
DENOM   = OMEGA_M + 4 * OMEGA_L       # = 3.055

# ----------------------------------------------------------------------
# 3. Paramètres β
# ----------------------------------------------------------------------
BETAS = {
    r"$\beta = -0.65$": -0.65,
    r"$\beta = -0.70$": -0.70,   # centrale
    r"$\beta = -0.75$": -0.75
}

# ----------------------------------------------------------------------
# 4. Grille de redshift (0 ≤ z ≤ 15)
# ----------------------------------------------------------------------
z = np.linspace(0.0, 15.0, 701)

def P_of_z(z_arr: np.ndarray, beta: float) -> np.ndarray:
    """��(z)=1+β·[((1+z)^3–1)/(Ω_m+4Ω_Λ)]."""
    return 1.0 + beta * ((1 + z_arr) ** 3 - 1) / DENOM

# ----------------------------------------------------------------------
# 5. Figure
# ----------------------------------------------------------------------
plt.figure(figsize=(6.4, 4.2))

colors = ["tab:blue", "tab:orange", "tab:green"]
for (label, beta), col in zip(BETAS.items(), colors):
    plt.plot(z, P_of_z(z, beta), lw=2, label=label, color=col)

# Ligne de référence ��=1
plt.axhline(1.0, ls="--", lw=1.2, color="grey", label=r"Horloge standard $(\beta=0)$")

# Habillage
plt.xlabel(r"Redshift $z$")
plt.ylabel(r"$\mathcal{P}(z)=\mathrm d\tau/\mathrm dt$")
plt.ylim(0.4, 1.05)                 # toujours positif, marge haute
plt.xlim(0, 15)
plt.xticks(np.arange(0, 16, 2))
plt.grid(ls=":", alpha=0.6)
plt.legend(frameon=False, fontsize=9)
plt.title("Métrique différentielle du temps pour trois valeurs de β")
plt.tight_layout()

# ----------------------------------------------------------------------
# 6. Sauvegarde
# ----------------------------------------------------------------------
Path("../figures").mkdir(exist_ok=True)
out = Path("../figures/Pofz_curve.png")
plt.savefig(out, dpi=300)
plt.close()
print(f"[OK] Figure enregistrée : {out}")
