#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
plot_kappa_local_limit.py –– Génère figures/kappa_local_limit.png
-----------------------------------------------------------------
Comparaison logarithmique entre la prédiction |κ| du MCGT (α = 0.30)
et la meilleure limite PTA (NANOGrav 15 yr, 95 % C.I.).
CSV facultatifs : ../data/kappa_theory.csv, ../data/kappa_limit.csv
"""

# ----------------------------------------------------------------------
# 1. Imports
# ----------------------------------------------------------------------
from pathlib import Path
import csv
import matplotlib.pyplot as plt

# ----------------------------------------------------------------------
# 2. Constantes & valeurs par défaut
# ----------------------------------------------------------------------
ALPHA_DEF = 0.30
T0_SEC    = 13.8e9 * 3.1536e7          # 13.8 Gyr → s
kappa_th  = ALPHA_DEF * (1 - ALPHA_DEF) * T0_SEC ** (ALPHA_DEF - 2)
err_th    = 0.20 * kappa_th            # ±20 %

label_lim = "NANOGrav 15 yr (95 % C.I.)"
kappa_lim = 1.9e-26
err_lim   = 0.3e-26

# ----------------------------------------------------------------------
# 3. Surcharges éventuelles (CSV)
# ----------------------------------------------------------------------
def load_single_csv(path, fields):
    with path.open(newline="", encoding="utf-8") as f:
        return next(csv.DictReader(f))[fields[0]], next(csv.DictReader(f))[fields[1]]

theory_csv = Path("../data/kappa_theory.csv")
limit_csv  = Path("../data/kappa_limit.csv")

if theory_csv.is_file():
    with theory_csv.open(newline="", encoding="utf-8") as f:
        row = next(csv.DictReader(f))
        kappa_th = float(row["kappa"])
        err_th   = (abs(float(row["err_low"])) + abs(float(row["err_up"]))) / 2

if limit_csv.is_file():
    with limit_csv.open(newline="", encoding="utf-8") as f:
        row = next(csv.DictReader(f))
        label_lim = row.get("label", label_lim)
        kappa_lim = float(row["kappa"])
        err_lim   = (abs(float(row["err_low"])) + abs(float(row["err_up"]))) / 2

# ----------------------------------------------------------------------
# 4. Figure
# ----------------------------------------------------------------------
plt.figure(figsize=(6, 4))

# --- Prédiction théorique ---------------------------------------------
plt.errorbar([0], [kappa_th],
             yerr=[[err_th], [err_th]],
             fmt="s", ms=7, capsize=5,
             color="orange", ecolor="orange",
             label=r"$|\kappa_{\mathrm{th}}|$  (MCGT)")

# --- Limite PTA --------------------------------------------------------
plt.errorbar([1], [kappa_lim],
             yerr=[[err_lim], [err_lim]],
             fmt="o", ms=7, capsize=5,
             color="tab:blue", ecolor="tab:blue",
             label=label_lim)

# Mise en forme
plt.yscale("log")
plt.xticks([0, 1],
           [r"$\kappa_{\mathrm{th}}$", r"$\kappa_{\mathrm{lim}}$"])
plt.ylabel(r"$|\kappa|\;[\mathrm{s}^{-2}]$")
plt.title("Prédiction MCGT vs. limite PTA (95 %)")

# Encadrement vertical adapté
y_min = min(kappa_lim - err_lim, kappa_th - err_th) / 5
y_max = max(kappa_lim + err_lim, kappa_th + err_th) * 5
plt.ylim(y_min, y_max)

plt.grid(ls=":", which="both", alpha=0.6)
plt.legend(frameon=False, fontsize=9)
plt.tight_layout()

# ----------------------------------------------------------------------
# 5. Sauvegarde
# ----------------------------------------------------------------------
Path("../figures").mkdir(exist_ok=True)
out = Path("../figures/kappa_local_limit.png")
plt.savefig(out, dpi=300)
plt.close()
print(f"[OK] Figure enregistrée : {out}")
