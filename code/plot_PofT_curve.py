#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
plot_PofT_curve.py –– Génère figures/PofT_curve.png
---------------------------------------------------
Recalibrage temporel : P(T) = T* · (T / T*)^α
Courbes pour α = 0.30 (valeur centrale), 0.50, 0.80
Fig. 3 du manuscrit révisé (avril 2025).
"""

# ----------------------------------------------------------------------
# 1. Imports
# ----------------------------------------------------------------------
import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path

# ----------------------------------------------------------------------
# 2. Constantes
# ----------------------------------------------------------------------
T_STAR = 1.0      # Gyr
ALPHAS = {
    r"$\alpha = 0.30$": 0.30,
    r"$\alpha = 0.50$": 0.50,
    r"$\alpha = 0.80$": 0.80
}

# Grille temporelle 0.01 → 30 Gyr (log)
T = np.logspace(-2, np.log10(30), 600)  # Gyr


def P_of_T(t, alpha):
    """P(T) = T* (T/T*)^α ; T en Gyr, renvoie P(T) en Gyr."""
    return T_STAR * (t / T_STAR) ** alpha


# ----------------------------------------------------------------------
# 3. Figure
# ----------------------------------------------------------------------
plt.figure(figsize=(6.2, 4.2))

colors = ["tab:blue", "tab:orange", "tab:green"]
for (label, alpha), col in zip(ALPHAS.items(), colors):
    plt.loglog(T, P_of_T(T, alpha), lw=2, label=label, color=col)

# Diagonale P = T
plt.loglog(T, T, ls="--", lw=1.2, color="grey", label=r"Horloge linéaire $(P=T)$")

# Axes & habillage
plt.xlim(0.01, 30)
plt.ylim(0.01, 30)
plt.xlabel(r"Temps cosmique $T$  [Gyr]")
plt.ylabel(r"Durée fonctionnelle $P(T)$  [Gyr]")
plt.grid(which="both", ls=":", alpha=0.6)
plt.legend(frameon=False, fontsize=9)
plt.tight_layout()

# ----------------------------------------------------------------------
# 4. Sauvegarde
# ----------------------------------------------------------------------
Path("../figures").mkdir(exist_ok=True)
out = Path("../figures/PofT_curve.png")
plt.savefig(out, dpi=300)
plt.close()
print(f"[OK] Figure enregistrée : {out}")
