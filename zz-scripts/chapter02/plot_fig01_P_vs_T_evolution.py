#!/usr/bin/env python3
"""Fig. 01 – Évolution de P(T) – Chapitre 2 (Validation chronologique)"""

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from pathlib import Path

# Paths
ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = ROOT / "zz-data" / "chapter02"
FIG_DIR = ROOT / "zz-figures" / "chapter02"
FIG_DIR.mkdir(parents=True, exist_ok=True)

# Load data
T_dense, P_dense = np.loadtxt(DATA_DIR / "02_P_vs_T_grid_data.dat", unpack=True)
results = pd.read_csv(DATA_DIR / "02_timeline_milestones.csv")
T_ref = results["T"]
P_ref = results["P_ref"]

# Plot
plt.figure(dpi=300)
plt.plot(T_dense, P_dense, "-", label=r"$P_{\rm calc}(T)$", color="orange")
plt.scatter(T_ref, P_ref, marker="o", label=r"$P_{\rm ref}(T_i)$", color="grey")
plt.xscale("log")
plt.yscale("log")
plt.xlabel("T (Gyr)")
plt.ylabel("P(T)")
plt.title("Fig. 01 – Évolution de P(T) – Chapitre 2")
plt.grid(True, which="both", linestyle=":", linewidth=0.5)
plt.legend()
plt.tight_layout()
plt.savefig(FIG_DIR / "fig_01_P_vs_T_evolution.png")
