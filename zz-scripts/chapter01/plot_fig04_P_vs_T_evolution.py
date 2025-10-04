#!/usr/bin/env python3
"""Fig. 04 – Évolution de P(T) : initial vs optimisé"""

from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd

# Configuration des chemins
base = Path(__file__).resolve().parents[2]
init_csv = base / "zz-data" / "chapter01" / "01_initial_grid_data.dat"
opt_csv = base / "zz-data" / "chapter01" / "01_optimized_data_and_derivatives.csv"
output_file = base / "zz-figures" / "chapter01" / "fig_04_P_vs_T_evolution.png"

# Lecture des données
df_init = pd.read_csv(init_csv)
df_opt = pd.read_csv(opt_csv)
T_init = df_init["T"]
P_init = df_init["P"]
T_opt = df_opt["T"]
P_opt = df_opt["P"]

# Tracé de la figure
plt.figure(dpi=300)
plt.plot(T_init, P_init, "--", color="grey", label=r"$P_{\rm init}(T)$")
plt.plot(T_opt, P_opt, "-", color="orange", label=r"$P_{\rm opt}(T)$")
plt.xscale("log")
plt.yscale("linear")
plt.xlabel("T (Gyr)")
plt.ylabel("P(T)")
plt.title("Fig. 04 – Évolution de P(T) : initial vs optimisé")
plt.grid(True, which="both", linestyle=":", linewidth=0.5)
plt.legend()
plt.tight_layout()
plt.savefig(output_file)
