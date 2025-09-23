#!/usr/bin/env python3
"""Fig. 05 – Invariant adimensionnel I1(T)"""

import pandas as pd
import matplotlib.pyplot as plt
from pathlib import Path

base = Path(__file__).resolve().parents[2]
data_file = base / "zz-data" / "chapter01" / "01_dimensionless_invariants.csv"
output_file = base / "zz-figures" / "chapter01" / "fig_05_I1_vs_T.png"

df = pd.read_csv(data_file)
T = df["T"]
I1 = df["I1"]

plt.figure(dpi=300)
plt.plot(T, I1, color="orange", label=r"$I_1 = P(T)/T$")
plt.xscale("log")
plt.yscale("log")
plt.xlabel("T (Gyr)")
plt.ylabel(r"$I_1$")
plt.title("Fig. 05 – Invariant adimensionnel $I_1$ en fonction de $T$")
plt.grid(True, which="both", ls=":", lw=0.5)
plt.legend()
plt.tight_layout()
plt.savefig(output_file)
