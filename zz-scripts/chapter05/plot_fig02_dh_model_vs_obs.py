import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import json
from scipy.interpolate import PchipInterpolator
from pathlib import Path

# Répertoires
ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = ROOT / "zz-data" / "chapitre5"
FIG_DIR = ROOT / "zz-figures" / "chapitre5"
FIG_DIR.mkdir(parents=True, exist_ok=True)

# Chargement des données
jalons = pd.read_csv(DATA_DIR / "05_jalons_nucleosynthese.csv")
donnees = pd.read_csv(DATA_DIR / "05_donnees_nucleosynthese.csv")

# Chargement des métriques
params_path = DATA_DIR / "05_parametres_nucleosynthese.json"
if params_path.exists():
    params = json.load(open(params_path))
    max_ep_primary = params.get("max_epsilon_primary", None)
    max_ep_order2 = params.get("max_epsilon_order2", None)
else:
    max_ep_primary = None
    max_ep_order2 = None

# Interpolation PCHIP pour DH_calc aux temps des jalons
interp = PchipInterpolator(
    np.log10(donnees["T_Gyr"].values),
    np.log10(donnees["DH_calc"].values),
    extrapolate=False,
)
jalons["DH_calc"] = 10 ** interp(np.log10(jalons["T_Gyr"].values))

# Préparation du tracé
fig, ax = plt.subplots(figsize=(8, 5))
ax.set_xscale("log")
ax.set_yscale("log")

# Barres d'erreur et points de calibration
ax.errorbar(
    jalons["DH_obs"],
    jalons["DH_calc"],
    yerr=jalons["sigma_DH"],
    fmt="o",
    label="Points de calibration",
)

# Droite d'identité y = x
lims = [
    min(jalons["DH_obs"].min(), jalons["DH_calc"].min()),
    max(jalons["DH_obs"].max(), jalons["DH_calc"].max()),
]
ax.plot(lims, lims, ls="--", color="black", label="Identité")

# Annotation des métriques de calibration repositionnée
txt_lines = []
if max_ep_primary is not None:
    txt_lines.append(f"max ε_primary = {max_ep_primary:.2e}")
if max_ep_order2 is not None:
    txt_lines.append(f"max ε_order2 = {max_ep_order2:.2e}")
if txt_lines:
    ax.text(
        0.05,
        0.5,
        "\n".join(txt_lines),
        transform=ax.transAxes,
        va="center",
        ha="left",
        bbox=dict(boxstyle="round", facecolor="white", alpha=0.5),
    )

# Légendes et annotations
ax.set_xlabel("D/H observé")
ax.set_ylabel("D/H calculé")
ax.set_title("Diagramme D/H : modèle vs observations")
ax.legend(framealpha=0.3, loc="upper left")

# Enregistrement
plt.tight_layout()
plt.savefig(FIG_DIR / "fig_02_dh_modele_contre_obs.png", dpi=300)
plt.close()
