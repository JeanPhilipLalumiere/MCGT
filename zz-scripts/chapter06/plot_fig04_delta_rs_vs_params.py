#!/usr/bin/env python3
"""
Script de tracé fig_04_delta_rs_vs_params pour Chapitre 6 (Rayonnement CMB)
───────────────────────────────────────────────────────────────
Tracé de la variation relative Δr_s/r_s en fonction du paramètre q0star.
"""

# --- IMPORTS & CONFIGURATION ---
import logging
from pathlib import Path
import json
import pandas as pd
import matplotlib.pyplot as plt

# Logging
logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")

# Paths
ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = ROOT / "zz-data" / "chapitre6"
FIG_DIR = ROOT / "zz-figures" / "chapitre6"
DATA_CSV = DATA_DIR / "06_delta_rs_scan.csv"
JSON_PARAMS = DATA_DIR / "06_params_cmb.json"
OUT_PNG = FIG_DIR / "fig_04_delta_rs_vs_params.png"
FIG_DIR.mkdir(parents=True, exist_ok=True)

# Load scan data
df = pd.read_csv(DATA_CSV)
x = df["q0star"].values
y = df["delta_rs_rel"].values

# Load injection parameters for annotation
with open(JSON_PARAMS, "r", encoding="utf-8") as f:
    params = json.load(f)
ALPHA = params.get("alpha", None)
Q0STAR = params.get("q0star", None)
logging.info(f"Tracé fig_04 avec α={ALPHA}, q0*={Q0STAR}")

# Plot
fig, ax = plt.subplots(figsize=(10, 6), dpi=300)
ax.scatter(x, y, marker="o", s=20, alpha=0.8, label=r"$\Delta r_s / r_s$")

# Tolérances ±1%
ax.axhline(0.01, color="k", linestyle=":", linewidth=1)
ax.axhline(-0.01, color="k", linestyle=":", linewidth=1)

# Axes et légende
ax.set_xlabel(r"$q_0^\star$", fontsize=11)
ax.set_ylabel(r"$\Delta r_s / r_s$", fontsize=11)
ax.grid(which="both", linestyle=":", linewidth=0.5)
ax.legend(frameon=False, fontsize=9)

# Annotation des paramètres
if ALPHA is not None and Q0STAR is not None:
    ax.text(
        0.05,
        0.95,
        rf"$\alpha={ALPHA},\ q_0^*={Q0STAR}$",
        transform=ax.transAxes,
        ha="left",
        va="top",
        fontsize=9,
    )

plt.tight_layout()
plt.savefig(OUT_PNG)
logging.info(f"Figure enregistrée → {OUT_PNG}")
