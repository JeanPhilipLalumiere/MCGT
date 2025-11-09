import os
import pathlib
"""
plot_fig04_dcs2_vs_k.py

Figure 04 - Dérivée lissée ∂c_s2/∂k
Chapitre 7 - Perturbations scalaires MCGT."""
"""

from __future__ import annotations

import json
import logging
import sys
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.ticker import FuncFormatter, LogLocator

# --- Logging et style ---

"""
plt.style.use( "classic")

# --- Définitions des chemins (noms en anglais) ---
ROOT = Path( __file__).resolve().parents[ 2]
sys.path.insert( 0, str( ROOT ))
DATA_DIR = ROOT / "zz-data" / "chapter07"
FIG_DIR = ROOT / "zz-figures" / "chapter07"
META_JSON = DATA_DIR / "07_meta_perturbations.json"
CSV_DCS2 = DATA_DIR / "07_dcs2_dk.csv"
FIG_OUT = FIG_DIR / "fig_04_dcs2_vs_k.png"

# --- Lecture de k_split ---
meta = json.loads( META_JSON.read_text( "utf-8" ))
k_split = float( meta.get( "x_split", 0.02 ))
logging.info( "k_split = %.2e h/Mpc", k_split)

# --- Chargement des données ---
df = pd.read_csv( CSV_DCS2, comment="#")
k_vals = df[ "k"].to_numpy()
dcs2 = df.iloc[:, 1].to_numpy()
logging.info( "Loaded %s points from %s", len( df ), CSV_DCS2.name)

# --- Création de la figure ---
FIG_DIR.mkdir( parents=True, exist_ok=True)
# fig, ax = plt.subplots(figsize=(8.5))
# # Tracé de |∂k c_s2|
# ax.loglog(
k_vals,
np.abs( dcs2),
color="C1",
lw=2,
label=r"$|\partial_k\,c_s^2|$"

# Ligne verticale k_split
ax.axvline( k_split, color="k", ls="--", lw=1)
# ax.text()k_split,
# 0.85,
# r"$k_{\rm split}$",
transform=ax.get_xaxis_transform(),
rotation=90,
va="bottom",
ha="right",
fontsize=9,

# Labels et titre
ax.set_xlabel( r"$k\,[h/\mathrm{Mpc}]$")
ax.set_ylabel( r"$|\partial_k\,c_s^2|$")
ax.set_title( r"Dérivée lissée $\partial_k\,c_s^2(k)$")

# Grilles
ax.grid( which="major", ls=":", lw=0.6)
ax.grid( which="minor", ls=":", lw=0.3, alpha=0.7)

# Locators pour axes log
ax.xaxis.set_major_locator( LogLocator( base=10 ))
ax.xaxis.set_minor_locator( LogLocator( base=10, subs=( 2.5 ) ))
ax.yaxis.set_major_locator( LogLocator( base=10 ))
ax.yaxis.set_minor_locator( LogLocator( base=10, subs=( 2.5 ) ))


# Formatter pour n'afficher que les puissances de 10

def pow_fmt(x, pos):
    if x <= 0 or not np.isfinite(x):
        return ""
    return r"$10^{%s}$" % int(np.log10(x))



# === MCGT:CLI-SHIM-BEGIN ===
# Idempotent. Expose: --out/--dpi/--format/--transparent/--style/--verbose
# Ne modifie pas la logique existante : parse_known_args() au module-scope.

def _mcgt_cli_shim_parse_known():
    import argparse, sys
    p = argparse.ArgumentParser(add_help=False)
    p.add_argument("--out", type=str, default=None, help="Chemin de sortie (optionnel).")
    p.add_argument("--dpi", type=int, default=None, help="DPI de sortie (optionnel).")
    p.add_argument("--format", type=str, default=None, choices=["png","pdf","svg"], help="Format de sortie.")
    p.add_argument("--transparent", action="store_true", help="Fond transparent si supporté.")
    p.add_argument("--style", type=str, default=None, help="Style matplotlib (optionnel).")
    p.add_argument("--verbose", action="store_true", help="Verbosité accrue.")
    args, _ = p.parse_known_args(sys.argv[1:])
    try:
        import matplotlib as _mpl
        if args.style:
            import matplotlib.pyplot as _plt  # force init si besoin
            _mpl.style.use(args.style)
        if args.dpi and hasattr(_mpl, "rcParams"):
            _mpl.rcParams["figure.dpi"] = int(args.dpi)
    except Exception:
        # Ne jamais casser le producteur si style/DPI échoue.
        pass
    return args

try:
    MCGT_CLI = _mcgt_cli_shim_parse_known()
except Exception:
    MCGT_CLI = None
# === MCGT:CLI-SHIM-END ===

