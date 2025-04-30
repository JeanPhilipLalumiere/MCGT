#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
plot_kappa_constraints.py –– Génère figures/kappa_constraints.png
-----------------------------------------------------------------
Limites (95 % C.I.) sur |κ| obtenues par les PTA majeurs :
    • NANOGrav 15 yr (2024)
    • EPTA DR2       (2023)
    • PPTA DR3       (2023)

Si ../data/kappa_limits.csv existe (colonnes : PTA,kappa,err),
il écrase les valeurs par défaut.
"""

# ----------------------------------------------------------------------
# 1. Imports
# ----------------------------------------------------------------------
import csv
import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path

# ----------------------------------------------------------------------
# 2. Lecture des données
# ----------------------------------------------------------------------
csv_path = Path("../data/kappa_limits.csv")

if csv_path.is_file():
    PTA, K, E = [], [], []
    with csv_path.open(newline="", encoding="utf-8") as f:
        rdr = csv.DictReader(f)
        for row in rdr:
            PTA.append(row["PTA"])
            K  .append(float(row["kappa"]))
            E  .append(float(row["err"]))
else:
    PTA = ["NANOGrav 15 yr", "EPTA DR2", "PPTA DR3"]
    K   = [1.9e-26,          2.5e-26,    3.0e-26]
    E   = [0.3e-26,          0.4e-26,    0.5e-26]

# Passage en ndarray + tri par valeur croissante de |κ|
pta   = np.array(PTA)
kappa = np.array(K)
err   = np.array(E)

order = np.argsort(kappa)
pta, kappa, err = pta[order], kappa[order], err[order]
idx = np.arange(len(pta))

# ----------------------------------------------------------------------
# 3. Figure
# ----------------------------------------------------------------------
plt.figure(figsize=(6.4, 4.0))

colors = ["tab:blue", "tab:orange", "tab:green"]
plt.errorbar(idx, kappa, yerr=err,
             fmt="o", ms=6, capsize=4, lw=1.4,
             color="black", ecolor=[colors[i] for i in idx],
             markeredgecolor=colors)

plt.yscale("log")
plt.xticks(idx, pta, rotation=10, ha="center")
plt.ylabel(r"$|\kappa|\;[\mathrm{s}^{-2}]$")
plt.title(r"Limites PTA (95 % C.I.) sur la dérive quadratique ($\kappa$)")
plt.grid(ls=":", which="both", alpha=0.5)
plt.tight_layout()

# ----------------------------------------------------------------------
# 4. Sauvegarde
# ----------------------------------------------------------------------
Path("../figures").mkdir(exist_ok=True)
out = Path("../figures/kappa_constraints.png")
plt.savefig(out, dpi=300)
plt.close()
print(f"[OK] Figure enregistrée : {out}")
