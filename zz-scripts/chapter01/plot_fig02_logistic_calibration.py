#!/usr/bin/env python3
"""Fig. 02 – Diagramme de calibration P_ref vs P_calc"""

import pandas as pd
import matplotlib.pyplot as plt
from scipy.interpolate import interp1d
from pathlib import Path

# Configuration des chemins
base = Path(__file__).resolve().parents[2]
data_ref = base / "zz-data" / "chapitre1" / "01_jalons_chronologie.csv"
data_opt = base / "zz-data" / "chapitre1" / "01_donnees_optimisees.csv"
output_file = base / "zz-figures" / "chapitre1" / "fig_02_calibration_logistique.png"

# Lecture des données
df_ref = pd.read_csv(data_ref)
df_opt = pd.read_csv(data_opt)
interp = interp1d(df_opt["T"], df_opt["P_calc"], fill_value="extrapolate")
P_calc_ref = interp(df_ref["T"])

# Tracé de la figure
plt.figure(dpi=300)
plt.loglog(df_ref["P_ref"], P_calc_ref, "o", label="Données calibration")
minv = min(df_ref["P_ref"].min(), P_calc_ref.min())
maxv = max(df_ref["P_ref"].max(), P_calc_ref.max())
plt.plot([minv, maxv], [minv, maxv], "--", label="Identité (y = x)")
plt.xlabel(r"$P_{\mathrm{ref}}$")
plt.ylabel(r"$P_{\mathrm{calc}}$")
plt.title("Fig. 02 – Calibration log–log")
plt.grid(True, which="both", ls=":", lw=0.5)
plt.legend()
plt.tight_layout()
plt.savefig(output_file)
