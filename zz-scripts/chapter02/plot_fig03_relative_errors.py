#!/usr/bin/env python3
"""Fig. 03 – Écarts relatifs $\varepsilon_i$ – Chapitre 2"""

import matplotlib.pyplot as plt
import pandas as pd
from pathlib import Path

# Paths
ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = ROOT / "zz-data" / "chapitre2"
FIG_DIR = ROOT / "zz-figures" / "chapitre2"
FIG_DIR.mkdir(parents=True, exist_ok=True)

# Load data
df = pd.read_csv(DATA_DIR / "02_jalons_chronologie.csv")
T = df["T"]
eps = df["epsilon_i"]
cls = df["classe"]

# Masks
primary = cls == "primaire"
order2 = cls != "primaire"

# Plot
plt.figure(dpi=300)
plt.scatter(
    T[primary], eps[primary], marker="o", label="Jalons primaires", color="black"
)
plt.scatter(T[order2], eps[order2], marker="s", label="Jalons ordre 2", color="grey")
plt.xscale("log")
plt.yscale("symlog", linthresh=1e-3)
# Threshold lines
plt.axhline(0.01, linestyle="--", linewidth=0.8, color="blue", label="Seuil 1%")
plt.axhline(-0.01, linestyle="--", linewidth=0.8, color="blue")
plt.axhline(0.10, linestyle=":", linewidth=0.8, color="red", label="Seuil 10%")
plt.axhline(-0.10, linestyle=":", linewidth=0.8, color="red")
plt.xlabel("T (Gyr)")
plt.ylabel(r"$\varepsilon_i$")
plt.title("Fig. 03 – Écarts relatifs $\varepsilon_i$ – Chapitre 2")
plt.grid(True, which="both", linestyle=":", linewidth=0.5)
plt.legend()
plt.tight_layout()
plt.savefig(FIG_DIR / "fig_03_ecarts_relatifs.png")
