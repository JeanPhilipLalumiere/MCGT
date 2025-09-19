#!/usr/bin/env python3
# tracer_fig03_mu_vs_z.py
# ---------------------------------------------------------------
# Trace μ_obs(z) vs μ_th(z) pour Chapitre 8 (Couplage sombre) du projet MCGT
# ---------------------------------------------------------------

import json
from pathlib import Path

import pandas as pd
import matplotlib.pyplot as plt

# -- Paths
ROOT     = Path(__file__).resolve().parents[2]
DATA_DIR = ROOT / "zz-data"   / "chapitre8"
FIG_DIR  = ROOT / "zz-figures"   / "chapitre8"
FIG_DIR.mkdir(parents=True, exist_ok=True)

# -- Load data
pantheon = pd.read_csv(DATA_DIR / "08_donnees_pantheon.csv", encoding="utf-8")
theory   = pd.read_csv(DATA_DIR / "08_mu_theorie_z.csv",    encoding="utf-8")
params   = json.loads((DATA_DIR / "08_params_couplage.json").read_text(encoding="utf-8"))
q0star   = params.get("q0star_optimal", None)  # ou autre clé selon ton JSON

# -- Sort by redshift
pantheon = pantheon.sort_values("z")
theory   = theory.sort_values("z")

# -- Plot settings
plt.rcParams.update({"font.size": 11})
fig, ax = plt.subplots(figsize=(6.5, 4.5))

# -- Observations with error bars
ax.errorbar(
    pantheon["z"],
    pantheon["mu_obs"],
    yerr=pantheon["sigma_mu"],
    fmt="o", markersize=5, capsize=3, label="Pantheon + obs"
)

# -- Theory curve
label_th = r"$\mu^{\rm th}(z; q_0^*={:.3f})$".format(q0star) \
    if q0star is not None else r"$\mu^{\rm th}(z)$"
ax.semilogx(
    theory["z"],
    theory["mu_calc"],
    "-", lw=2,
    label=label_th
)

# -- Axes labels & title
ax.set_xlabel("Redshift $z$")
ax.set_ylabel(r"Distance modulaire $\mu$\;[mag]")
ax.set_title(r"Comparaison $\mu^{\rm obs}$ vs $\mu^{\rm th}$")

# -- Grid & legend
ax.grid(which="both", ls=":", lw=0.5, alpha=0.6)
ax.legend(loc="lower right")

# -- Layout & save
fig.tight_layout()
fig.savefig(FIG_DIR / "fig_03_mu_vs_z.png", dpi=300)
print("✅ fig_03_mu_vs_z.png générée dans", FIG_DIR)
