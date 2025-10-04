import pathlib

import matplotlib.pyplot as plt
import pandas as pd

# Lire la grille complète
data_path = (
    pathlib.Path(__file__).resolve().parents[2]
    / "zz-data"
    / "chapter01"
    / "01_optimized_data.csv"
)
df = pd.read_csv(data_path)

# Ne conserver que le plateau précoce T <= Tp
Tp = 0.087
df_plateau = df[df["T"] <= Tp]

T = df_plateau["T"]
P = df_plateau["P_calc"]

# Tracé continu de P(T) sur le plateau
plt.figure(figsize=(8, 4.5))
plt.plot(T, P, color="orange", linewidth=1.5, label="P(T) optimisé")

# Ligne verticale renforcée à Tp
plt.axvline(
    Tp, linestyle="--", color="black", linewidth=1.2, label=r"$T_p=0.087\,\mathrm{Gyr}$"
)

# Mise en forme
plt.xscale("log")
plt.xlabel("T (Gyr)")
plt.ylabel("P(T)")
plt.title("Plateau précoce de P(T)")
plt.ylim(0.98, 1.002)
plt.xlim(df_plateau["T"].min(), Tp * 1.05)
plt.grid(True, which="both", linestyle=":", linewidth=0.5)
plt.legend(loc="lower right")
plt.tight_layout()

# Sauvegarde
output_path = (
    pathlib.Path(__file__).resolve().parents[2]
    / "zz-figures"
    / "chapter01"
    / "fig_01_early_plateau.png"
)
plt.savefig(output_path, dpi=300)
