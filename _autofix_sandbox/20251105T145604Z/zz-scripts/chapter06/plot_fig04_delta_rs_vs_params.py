#!/usr/bin/env python3
import contextlib
# fichier : zz-scripts/chapter06/plot_fig04_delta_rs_vs_params.py
# répertoire : zz-scripts/chapter06
import os
"""
Script de tracé fig_04_delta_rs_vs_params pour Chapitre 6 (Rayonnement CMB)
───────────────────────────────────────────────────────────────
Tracé de la variation relative Δr_s/r_s en fonction du paramètre q0star.
"""

# --- IMPORTS & CONFIGURATION ---
import json
import logging
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd

# Logging
logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")

# Paths
ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = ROOT / "zz-data" / "chapter06"
FIG_DIR = ROOT / "zz-figures" / "chapter06"
DATA_CSV = DATA_DIR / "06_delta_rs_scan.csv"
JSON_PARAMS = DATA_DIR / "06_params_cmb.json"
OUT_PNG = FIG_DIR / "fig_04_delta_rs_vs_params.png"
FIG_DIR.mkdir(parents=True, exist_ok=True)

# Load scan data
df = pd.read_csv(DATA_CSV)
x = df["q0star"].values
y = df["delta_rs_rel"].values

# Load injection parameters for annotation
with open(JSON_PARAMS, encoding="utf-8") as f:
    params = json.load(f)
ALPHA = params.get("alpha", None)
Q0STAR = params.get("q0star", None)
logging.info(f"Tracé fig_04 avec α={ALPHA}, q0*={Q0STAR}")

# Plot
fig, ax = plt.subplots(figsize=(10, 6), dpi=300)
ax.scatter(x, y, marker="o", s=20, alpha=0.8, label=r"$\Delta r_s / r_s$")

# Tolérances ±1%
ax.axhline(0.01, color="k", linestyle=":", linewidth=1)
ax.axhline(-0.01, color="k", linestyle=":", linewidth=1)

# Axes et légende
ax.set_xlabel(r"$q_0^\star$", fontsize=11)
ax.set_ylabel(r"$\Delta r_s / r_s$", fontsize=11)
ax.grid(which="both", linestyle=":", linewidth=0.5)
ax.legend(frameon=False, fontsize=9)

# Annotation des paramètres
if ALPHA is not None and Q0STAR is not None:
    ax.text(
        0.05,
        0.95,
        rf"$\alpha={ALPHA},\ q_0^*={Q0STAR}$",
        transform=ax.transAxes,
        ha="left",
        va="top",
        fontsize=9,
    )

fig.subplots_adjust(left=0.04, right=0.98, bottom=0.06, top=0.96)
plt.savefig(OUT_PNG)
logging.info(f"Figure enregistrée → {OUT_PNG}")

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

        args = parser.parse_args()
        with contextlib.suppress(Exception):
            os.makedirs(args.outdir, exist_ok=True)
        os.environ["MCGT_OUTDIR"] = args.outdir
        import matplotlib as mpl
        mpl.rcParams["savefig.dpi"] = args.dpi
        mpl.rcParams["savefig.format"] = args.format
        mpl.rcParams["savefig.transparent"] = args.transparent
        _main = globals().get("main")
        if callable(_main):
            with contextlib.suppress(Exception):
                _main(args)
    _mcgt_cli_seed()
