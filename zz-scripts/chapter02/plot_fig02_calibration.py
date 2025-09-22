#!/usr/bin/env python3
"""Fig. 02 – Diagramme de calibration (P_calc vs P_ref) – Chapitre 2"""

import matplotlib.pyplot as plt
import pandas as pd
from pathlib import Path

# Paths
ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = ROOT / "zz-data" / "chapter02"
FIG_DIR = ROOT / "zz-figures" / "chapter02"
FIG_DIR.mkdir(parents=True, exist_ok=True)

# Load data
df = pd.read_csv(DATA_DIR / "02_timeline_milestones.csv")
P_ref = df["P_ref"]
P_calc = df["P_opt"]

# Plot
plt.figure(dpi=300)
plt.scatter(P_ref, P_calc, marker="o", color="grey", label="Jalons")
lim_min = min(P_ref.min(), P_calc.min())
lim_max = max(P_ref.max(), P_calc.max())
plt.plot([lim_min, lim_max], [lim_min, lim_max], "--", color="black", label="Identité")
plt.xscale("log")
plt.yscale("log")
plt.xlabel(r"$P_{\rm ref}$")
plt.ylabel(r"$P_{\rm calc}$")
plt.title("Fig. 02 – Diagramme de calibration – Chapitre 2")
plt.grid(True, which="both", linestyle=":", linewidth=0.5)
plt.legend()
plt.tight_layout()
plt.savefig(FIG_DIR / "fig_02_calibration.png")
