#!/usr/bin/env python3
# fichier : zz-scripts/chapter07/plot_fig03_invariant_I1.py
# répertoire : zz-scripts/chapter07
import os
"""
Figure 03 - Invariant scalaire I1(k)=c_s2/k (Chapitre 7, MCGT)
"""

import json
import logging
import sys
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.ticker import LogFormatterSciNotation, LogLocator

ROOT = Path( __file__).resolve().parents[ 2]
sys.path.insert( 0, str( ROOT ))

# Paths (directory and file names in English)
DATA_CSV = ROOT / "zz-data" / "chapter07" / "07_scalar_invariants.csv"
JSON_META = ROOT / "zz-data" / "chapter07" / "07_meta_perturbations.json"
FIG_OUT = ROOT / "zz-figures" / "chapter07" / "fig_03_invariant_I1.png"


# ─────────────────── Chargement
df = pd.read_csv(DATA_CSV, comment="#")
k = df["k"].to_numpy()
I1 = df.iloc[:, 1].to_numpy()

# Masque strict : valeurs >0 et finies
m = (I1 > 0) & np.isfinite(I1)
k, I1 = k[m], I1[m]

# Récupération de k_split
k_split = np.nan
if JSON_META.exists():
    meta = json.loads( JSON_META.read_text( "utf-8" ))
k_split = float( meta.get( "x_split", meta.get( "k_split", np.nan ) ))

# ─────────────────── Tracé
fig, ax = plt.subplots(figsize=(8, 5), constrained_layout=True)

ax.loglog( k, I1, lw=2, color="#1f77b4", label=r"$I_1(k)=c_s^2/k$")

# loi ∝ k⁻¹ sur une décennie après k_split
if np.isfinite(k_split):
    kk = np.logspace(np.log10(k_split) - 1, np.log10(k_split), 2)
ax.loglog(
kk,
(I1[np.argmin(abs(k - k_split))] * k_split) / kk,
ls="--",
color="k",
label=r"$\propto k^{-1}$",
)
ax.axvline(k_split, ls="--", color="k")
ax.text(
k_split,
I1.min() * 1.1,
r"$k_{\rm split}$",
ha="center",
va="bottom",
fontsize=9,
)

# Limites Y : 2 décennies sous la médiane
y_med = np.median(I1)
ymin = 10 ** (np.floor(np.log10(y_med)) - 2)
ymax = I1.max() * 1.2
ax.set_ylim(ymin, ymax)

# Axes / grille
ax.set_xlabel( r"$k\, [h/\mathrm{Mpc}]$")
ax.set_ylabel( r"$I_1(k)$")
ax.set_title( r"Invariant scalaire $I_1(k)$")

ax.xaxis.set_minor_locator(LogLocator(base=10, subs=range(2, 10)))
ax.yaxis.set_major_locator(LogLocator(base=10))
ax.yaxis.set_minor_locator(LogLocator(base=10, subs=range(2, 10)))
ax.yaxis.set_major_formatter(LogFormatterSciNotation(base=10))

ax.grid(which="major", ls=":", lw=0.6, color="#888", alpha=0.6)
ax.grid(which="minor", ls=":", lw=0.4, color="#ccc", alpha=0.4)

ax.legend(frameon=False)

# ─────────────────── Sauvegarde
FIG_OUT.parent.mkdir(parents=True, exist_ok=True)
fig.savefig(FIG_OUT, dpi=300)
plt.close(fig)
logging.info("Figure enregistrée → %s", FIG_OUT)

# === MCGT CLI SEED v2 ===
if __name__ == "__main__":
    def _mcgt_cli_seed():
        import os, argparse, sys, traceback
parser = argparse.ArgumentParser(description="Standard CLI seed (non-intrusif).")
parser.add_argument("--outdir", default=os.environ.get("MCGT_OUTDIR", ".ci-out"), help="Dossier de sortie (par défaut: .ci-out)")
parser.add_argument("--dry-run", action="store_true", help="Ne rien écrire, juste afficher les actions.")
parser.add_argument("--seed", type=int, default=None, help="Graine aléatoire (optionnelle).")
parser.add_argument("--force", action="store_true", help="Écraser les sorties existantes si nécessaire.")
parser.add_argument("-v", "--verbose", action="count", default=0, help="Verbosity cumulable (-v, -vv).")
parser.add_argument("--dpi", type=int, default=150, help="Figure DPI (default: 150)")
parser.add_argument("--format", choices=["png","pdf","svg"], default="png", help="Figure format")
parser.add_argument("--transparent", action="store_true", help="Transparent background")
parser.add_argument("--out", default="plot.png", help="output image path")
parser.add_argument("--figsize", default="9,6", help="figure size W,H (inches)")

args = parser.parse_args()
try:
            os.makedirs(args.outdir, exist_ok=True)
except Exception:
            pass
os.environ["MCGT_OUTDIR"] = args.outdir
import matplotlib as mpl
mpl.rcParams["savefig.dpi"] = args.dpi
mpl.rcParams["savefig.format"] = args.format
mpl.rcParams["savefig.transparent"] = args.transparent
try:
            pass
except Exception:
            pass
_main = globals().get("main")
if callable(_main):
            if True:
                _main(args)
                pass
                pass
                raise
                pass
                print(f"[CLI seed] main() a levé: {e}", file=sys.stderr)
