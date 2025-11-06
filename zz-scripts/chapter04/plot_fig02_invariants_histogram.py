#!/usr/bin/env python3
# fichier : zz-scripts/chapter04/plot_fig02_invariants_histogram.py
# répertoire : zz-scripts/chapter04
# === [PASS5-AUTOFIX-SHIM] ===
import sys
_argv = sys.argv[1:]
# 1) Shim --help universel
if any(a in ("-h","--help") for a in _argv):
    import argparse
    _p = argparse.ArgumentParser(description="MCGT (shim auto-injecté Pass5)", add_help=True, allow_abbrev=False)
    _p.add_argument("--out", help="Chemin de sortie pour fig.savefig (optionnel)")
    _p.add_argument("--dpi", type=int, default=120, help="DPI (par défaut: 120)")
    _p.add_argument("--figsize", default="9,6", help="figure size W,H (inches)")
    _p.parse_args(_argv)
    raise SystemExit(0)
# === [/PASS5-AUTOFIX-SHIM] ===
"""
plot_fig02_invariants_histogram.py

Script corrigé de tracé de l'histogramme des invariants I2 et I3
– Lit 04_dimensionless_invariants.csv
– Exclut les valeurs nulles de I3 pour le log
– Trace histogramme de log10(I2) et log10(|I3|)
– Sauvegarde la figure 800×500 px DPI 300
"""

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd


def main():
    # ----------------------------------------------------------------------
    # 1. Chargement des données
    # ----------------------------------------------------------------------
    data_file = "zz-data/chapter04/04_dimensionless_invariants.csv"
    df = pd.read_csv(data_file)
    logI2 = np.log10(df["I2"].values)
    # Exclure I3 = 0 pour log10
    I3_vals = df["I3"].values
    I3_nonzero = I3_vals[I3_vals != 0]
    logI3 = np.log10(np.abs(I3_nonzero))

    # ----------------------------------------------------------------------
    # 2. Création de la figure
    # ----------------------------------------------------------------------
    fig, ax = plt.subplots(figsize=(8, 5), dpi=300)

    # Définir les bins plus fins
    bins = np.linspace(min(logI2.min(), logI3.min()), max(logI2.max(), logI3.max()), 40)

ax.hist(
logI2, bins=bins, density=True, alpha=0.7, label=r"$\log_{10}I_2$", color="C1"
)
ax.hist(
logI3,
bins=bins,
density=True,
alpha=0.7,
label=r"$\log_{10}\lvert I_3\rvert$",
color="C2",
)

    # ----------------------------------------------------------------------
    # 3. Labels, légende et grille
    # ----------------------------------------------------------------------
ax.set_xlabel(r"$\log_{10}\bigl(\mathrm{valeur\ de\ l’invariant}\bigr)$")
ax.set_ylabel("Densité normalisée")
ax.set_title("Fig. 02 – Histogramme des invariants adimensionnels")
ax.legend(fontsize="small")
ax.grid(True, which="both", linestyle=":", linewidth=0.5)

    # ----------------------------------------------------------------------
    # 4. Sauvegarde de la figure
    # ----------------------------------------------------------------------
output_fig = "zz-figures/chapter04/04_fig_02_invariants_histogram.png"
fig.subplots_adjust(left=0.04, right=0.98, bottom=0.06, top=0.96)
plt.savefig(output_fig)
print(f"Fig. sauvegardée : {output_fig}")


if __name__ == "__main__":
    main()

# [MCGT POSTPARSE EPILOGUE v2]
# (compact) delegate to common helper; best-effort wrapper
try:
    import os, sys
    _here = os.path.abspath(os.path.dirname(__file__))
    _zz = os.path.abspath(os.path.join(_here, ".."))
    if _zz not in sys.path:
        sys.path.insert(0, _zz)
    from _common.postparse import apply as _mcgt_postparse_apply
    _mcgt_postparse_apply()
except Exception:
    pass
