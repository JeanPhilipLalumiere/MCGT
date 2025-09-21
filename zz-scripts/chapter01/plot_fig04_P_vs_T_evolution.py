#!/usr/bin/env python3
"""Fig. 04 – Évolution de P(T) : initial vs optimisé"""

import pandas as pd
import matplotlib.pyplot as plt
from pathlib import Path

# Configuration des chemins
base = Path(__file__).resolve().parents[2]
init_csv = base / "zz-data" / "chapitre1" / "01_donnees_initiales_grille.dat"
opt_csv = base / "zz-data" / "chapitre1" / "01_donnees_optimisees_et_derivees.csv"
output_file = (
    base / "zz-figures" / "chapitre1" / "fig_04_evolution_P_en_fonction_de_T.png"
)

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
