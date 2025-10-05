#!/usr/bin/env python3
"""
plot_fig04_dcs2_vs_k.py

Figure 04 – Dérivée lissée ∂c_s²/∂k
Chapitre 7 – Perturbations scalaires MCGT.
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
logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")
plt.style.use("classic")

# --- Définitions des chemins (noms en anglais) ---
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
DATA_DIR = ROOT / "zz-data" / "chapter07"
FIG_DIR = ROOT / "zz-figures" / "chapter07"
META_JSON = DATA_DIR / "07_meta_perturbations.json"
CSV_DCS2 = DATA_DIR / "07_dcs2_dk.csv"
FIG_OUT = FIG_DIR / "fig_04_dcs2_vs_k.png"

# --- Lecture de k_split ---
meta = json.loads(META_JSON.read_text("utf-8"))
k_split = float(meta.get("x_split", 0.02))
logging.info("k_split = %.2e h/Mpc", k_split)

# --- Chargement des données ---
df = pd.read_csv(CSV_DCS2, comment="#")
k_vals = df["k"].to_numpy()
dcs2 = df.iloc[:, 1].to_numpy()
logging.info("Loaded %d points from %s", len(df), CSV_DCS2.name)

# --- Création de la figure ---
FIG_DIR.mkdir(parents=True, exist_ok=True)
fig, ax = plt.subplots(figsize=(8, 5))

# Tracé de |∂ₖ c_s²|
ax.loglog(k_vals, np.abs(dcs2), color="C1", lw=2, label=r"$|\partial_k\,c_s^2|$")

# Ligne verticale k_split
ax.axvline(k_split, color="k", ls="--", lw=1)
ax.text(
    k_split,
    0.85,
    r"$k_{\rm split}$",
    transform=ax.get_xaxis_transform(),
    rotation=90,
    va="bottom",
    ha="right",
    fontsize=9,
)

# Labels et titre
ax.set_xlabel(r"$k\,[h/\mathrm{Mpc}]$")
ax.set_ylabel(r"$|\partial_k\,c_s^2|$")
ax.set_title(r"Dérivée lissée $\partial_k\,c_s^2(k)$")

# Grilles
ax.grid(which="major", ls=":", lw=0.6)
ax.grid(which="minor", ls=":", lw=0.3, alpha=0.7)

# Locators pour axes log
ax.xaxis.set_major_locator(LogLocator(base=10))
ax.xaxis.set_minor_locator(LogLocator(base=10, subs=(2, 5)))
ax.yaxis.set_major_locator(LogLocator(base=10))
ax.yaxis.set_minor_locator(LogLocator(base=10, subs=(2, 5)))


# Formatter pour n'afficher que les puissances de 10
def pow_fmt(x, pos):
    if x <= 0 or not np.isfinite(x):
        return ""
    return rf"$10^{{{int(np.log10(x))}}}$"


ax.xaxis.set_major_formatter(FuncFormatter(pow_fmt))
ax.yaxis.set_major_formatter(FuncFormatter(pow_fmt))

# --- ICI on fixe la limite inférieure de Y pour aérer l'échelle ---
ax.set_ylim(1e-8, None)

# Légende
ax.legend(loc="upper right", frameon=False)

# Ajustement des marges
fig.subplots_adjust(left=0.12, right=0.98, top=0.90, bottom=0.12)

# Sauvegarde
fig.savefig(FIG_OUT, dpi=300)
plt.close(fig)
logging.info("Figure saved → %s", FIG_OUT)

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
        args = parser.parse_args()
        try:
            os.makedirs(args.outdir, exist_ok=True)
        os.environ["MCGT_OUTDIR"] = args.outdir
        except Exception:
            pass
        _main = globals().get("main")
        if callable(_main):
            try:
                _main(args)
            except SystemExit:
                raise
            except Exception as e:
                print(f"[CLI seed] main() a levé: {e}", file=sys.stderr)
                traceback.print_exc()
                sys.exit(1)
    _mcgt_cli_seed()
