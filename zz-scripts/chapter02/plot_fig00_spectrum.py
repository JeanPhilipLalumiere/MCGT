# ruff: noqa: E402
import sys
from pathlib import Path

import numpy as np
import matplotlib.pyplot as plt

# Ajouter le module primordial_spectrum au PYTHONPATH
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "zz-scripts" / "chapter02"))

from primordial_spectrum import P_R

# Grille de k et valeurs de alpha
k = np.logspace(-4, 2, 100)
alphas = [0.0, 0.05, 0.1]

# Création de la figure
fig, ax = plt.subplots(figsize=(6, 4))

for alpha in alphas:
    ax.loglog(k, P_R(k, alpha), label=f"α = {alpha}")

ax.set_xlabel("k [h·Mpc⁻¹]")
ax.set_ylabel("P_R(k; α)", labelpad=12)  # labelpad pour décaler plus à droite
ax.set_title("Spectre primordial MCGT")
ax.legend(loc="upper right")
ax.grid(True, which="both", linestyle="--", linewidth=0.5)

# Ajuster les marges pour que tout soit visible
plt.tight_layout()

# Sauvegarde
OUT = ROOT / "zz-figures" / "chapter02" / "fig_00_spectrum.png"
OUT.parent.mkdir(parents=True, exist_ok=True)
plt.savefig(OUT, dpi=300)
print(f"Figure enregistrée → {OUT}")
