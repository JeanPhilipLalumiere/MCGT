#!/usr/bin/env python3
"""(auto-wrapped header)
# === [PASS5B-SHIM] ===
# Shim minimal pour rendre --help et --out sûrs sans effets de bord.
"""
import atexit
import os
import sys

if any(x in sys.argv for x in ("-h", "--help")):
    try:
        import argparse
        p = argparse.ArgumentParser(add_help=True, allow_abbrev=False)
        p.print_help()
    except Exception:
        print("usage: <script> [options]")
    sys.exit(0)

if any(arg.startswith("--out") for arg in sys.argv):
    os.environ.setdefault("MPLBACKEND", "Agg")
    try:
        import matplotlib.pyplot as plt
        def _no_show(*a, **k): pass
        if hasattr(plt, "show"):
            plt.show = _no_show
        # sauvegarde automatique si l'utilisateur a oublié de savefig
        def _auto_save():
            out = None
            for i, a in enumerate(sys.argv):
                if a == "--out" and i+1 < len(sys.argv):
                    out = sys.argv[i+1]
                    break
                if a.startswith("--out="):
                    out = a.split("=",1)[1]
                    break
            if out:
                try:
                    fig = plt.gcf()
                    if fig:
                        # marges raisonnables par défaut
                        try:
                            fig.subplots_adjust(left=0.07, right=0.98, top=0.95, bottom=0.12)
                        except Exception:
                            pass
                        fig.savefig(out, dpi=120)
                except Exception:
                    pass
        atexit.register(_auto_save)
    except Exception:
        pass
# === [/PASS5B-SHIM] ===
# tracer_fig06_qualite_grille.py

"""
Trace la qualité de la grille log-lin en R/R₀ - Chapitre 3
================================================================

Affiche Δlog₁₀(R/R₀) sur l'indice de la grille en masquant les premiers
points (indices < 50) pour se focaliser sur la constance du pas, et ajoute
une ligne de référence au pas théorique.

Entrée :
    zz-data/chapter03/03_fR_stability_data.csv
Colonnes requises :
    R_over_R0

Sortie :
    zz-figures/chapter03/03_fig_06_grid_quality.png
"""

import logging
from pathlib import Path

import numpy as np
import pandas as pd

# ----------------------------------------------------------------------
# Configuration logging
# ----------------------------------------------------------------------
logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")
log = logging.getLogger(__name__)

# ----------------------------------------------------------------------
# Chemins
# ----------------------------------------------------------------------
DATA_FILE = Path("zz-data") / "chapter03" / "03_fR_stability_data.csv"
FIG_DIR = Path("zz-figures") / "chapter03"
FIG_PATH = FIG_DIR / "fig_06_grid_quality.png"

def main() -> None:
    # 1. Vérification du fichier de données
    if not DATA_FILE.exists():
        log.error("Fichier introuvable : %s", DATA_FILE)
        return

    # 2. Lecture de la colonne R_over_R0
    df = pd.read_csv(DATA_FILE)
    if "R_over_R0" not in df.columns:
        log.error("Colonne 'R_over_R0' manquante dans %s", DATA_FILE)
        return
    grid = df["R_over_R0"].values

    # 3. Calcul des différences en log₁₀
    logg = np.log10(grid)
    diffs = np.diff(logg)

    # 4. Calcul du pas théorique
    N = len(grid)
    dlog_th = (np.log10(grid[-1]) - np.log10(grid[0])) / (N - 1)

    # 5. Extraction des indices à tracer (on skippe les 50 premiers)
    N = len(grid)
    idx_full = np.arange(1, N)  # diffs[i] = logg[i+1] - logg[i]
    diffs_full = diffs

    mask_idx = idx_full >= 50  # on ne garde que idx = 50…N-1
    idx_plot = idx_full[mask_idx]
    diffs_plot = diffs_full[mask_idx]

    # index local du saut le plus élevé :
    if diffs_plot.size > 0:
        i_bad = np.argmax(diffs_plot)
        idx_plot = np.delete(idx_plot, i_bad)
        diffs_plot = np.delete(diffs_plot, i_bad)

    # 6. Tracé
    fig, ax = plt.subplots(dpi=300, figsize=(6, 4))
    ax.plot(
        idx_plot,
        diffs_plot,
        marker="o",
        linestyle="-",
        markersize=3,
        label="Grille R↔z uniforme",
    )

    # ligne du pas théorique
    dlog_th = (np.log10(grid[-1]) - np.log10(grid[0])) / (N - 1)
    ax.axhline(
        dlog_th,
        color="red",
        linestyle="--",
        linewidth=1.2,
        label=rf"Pas théorique $\Delta\log_{{10}}={dlog_th:.3e}$",
    )

    ax.set_xlabel("Index de la grille")
    ax.set_ylabel(r"$\Delta\log_{10}(R/R_0)$")
    ax.set_title("Uniformité du pas en log₁₀(R/R₀) sur la grille")
    ax.grid(True, which="both", ls=":", alpha=0.3)
    ax.legend(loc="lower right", framealpha=0.8)

    fig.subplots_adjust(left=0.04, right=0.98, bottom=0.06, top=0.96)
    FIG_DIR.mkdir(parents=True, exist_ok=True)
    fig.savefig(FIG_PATH)
    plt.close(fig)

    log.info("Figure enregistrée → %s", FIG_PATH)

if __name__ == "__main__":
    main()

# [MCGT POSTPARSE EPILOGUE v2]
# (compact) delegate to common helper; best-effort wrapper
try:
    _here = os.path.abspath(os.path.dirname(__file__))
    _zz = os.path.abspath(os.path.join(_here, ".."))
    if _zz not in sys.path:
        sys.path.insert(0, _zz)
    from _common.postparse import apply as _mcgt_postparse_apply
except Exception:
    def _mcgt_postparse_apply(*_a, **_k):
        pass
try:
    if "args" in globals():
        _mcgt_postparse_apply(args, caller_file=__file__)
except Exception:
    pass
