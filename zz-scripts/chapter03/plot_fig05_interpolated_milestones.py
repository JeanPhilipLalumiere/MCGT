# === [HELP-SHIM v1] ===
try:
    import sys, os, argparse
    if any(a in ('-h','--help') for a in sys.argv[1:]):
        os.environ.setdefault('MPLBACKEND','Agg')
        parser = argparse.ArgumentParser(
            description="(shim) aide minimale sans effets de bord",
            add_help=True, allow_abbrev=False)
        try:
            from _common.cli import add_common_plot_args as _add
            _add(parser)
        except Exception:
            pass
        parser.add_argument('--out', help='fichier de sortie', default=None)
        parser.add_argument('--dpi', type=int, default=150)
        parser.add_argument('--log-level', choices=['DEBUG','INFO','WARNING','ERROR'], default='INFO')
        parser.print_help()
        sys.exit(0)
except SystemExit:
    raise
except Exception:
    pass
# === [/HELP-SHIM v1] ===

from _common import cli as C
#!/usr/bin/env python3
# fichier : zz-scripts/chapter03/plot_fig05_interpolated_milestones.py
# répertoire : zz-scripts/chapter03
# === [PASS5B-SHIM] ===
# Shim minimal pour rendre --help et --out sûrs sans effets de bord.
import os
import sys
import atexit

if any(x in sys.argv for x in ("-h", "--help")):
    try:
        import argparse

        p = argparse.ArgumentParser(
# [autofix] disabled top-level parse: args = p.parse_args()



        # add_common_plot_args(p)
add_help=True, allow_abbrev=False)
        add_common_plot_args(p)
        p.print_help()
    except Exception:
        print("usage: <script> [options]")
    sys.exit(0)

if any(arg.startswith("--out") for arg in sys.argv):
    os.environ.setdefault("MPLBACKEND", "Agg")
    try:
        import matplotlib.pyplot as plt

        def _no_show(*a, **k):
            pass

        if hasattr(plt, "show"):
            plt.show = _no_show

        # sauvegarde automatique si l'utilisateur a oublié de savefig
        def _auto_save():
            out = None
            for i, a in enumerate(sys.argv):
                if a == "--out" and i + 1 < len(sys.argv):
                    out = sys.argv[i + 1]
                    break
                if a.startswith("--out="):
                    out = a.split("=", 1)[1]
                    break
            if out:
                try:
                    fig = plt.gcf()
                    if fig:
                        # marges raisonnables par défaut
                        try:
                            fig.subplots_adjust(
                                left=0.07, right=0.98, top=0.95, bottom=0.12
                            )
                        except Exception:
                            pass
                        fig.savefig(out, dpi=120)
                except Exception:
                    pass

        atexit.register(_auto_save)
    except Exception:
        pass
# === [/PASS5B-SHIM] ===
# tracer_fig05_interpolation_jalons.py

"""
Visualisation de l’interpolation PCHIP vs points de jalons — Chapitre 3
=======================================================================

Entrées :
    zz-data/chapter03/03_ricci_fR_milestones.csv
    zz-data/chapter03/03_fR_stability_data.csv

Colonnes jalons :
    R_over_R0, f_R, f_RR

Sortie :
    zz-figures/chapter03/03_fig_05_interpolated_milestones.png
"""

import logging
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from scipy.interpolate import PchipInterpolator

# ----------------------------------------------------------------------
# Configuration logging
# ----------------------------------------------------------------------
logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")
log = logging.getLogger(__name__)

# ----------------------------------------------------------------------
# Chemins
# ----------------------------------------------------------------------
DATA_DIR = Path("zz-data") / "chapter03"
RAW_FILE = DATA_DIR / "03_ricci_fR_milestones.csv"
GRID_FILE = DATA_DIR / "03_fR_stability_data.csv"
FIG_DIR = Path("zz-figures") / "chapter03"
FIG_PATH = FIG_DIR / "fig_05_interpolated_milestones.png"


def main() -> None:
    # 1. Lecture des données
    if not RAW_FILE.exists() or not GRID_FILE.exists():
        log.error("Fichiers introuvables : %s ou %s", RAW_FILE, GRID_FILE)
        return

    jalons = pd.read_csv(RAW_FILE)
    pd.read_csv(GRID_FILE)

    # On garde seulement R>0 pour log–log
    jalons = jalons[jalons["R_over_R0"] > 0].sort_values("R_over_R0")
    if jalons.empty:
        log.error("Aucun jalon valide dans %s", RAW_FILE)
        return

    # 2. Préparation du dossier figure
    FIG_DIR.mkdir(parents=True, exist_ok=True)

    # 3. Construire l’interpolateur PCHIP sur log10(R/R0)
    logR_j = np.log10(jalons["R_over_R0"].values)
    p_fR = PchipInterpolator(logR_j, np.log10(jalons["f_R"].values), extrapolate=True)
    p_fRR = PchipInterpolator(logR_j, np.log10(jalons["f_RR"].values), extrapolate=True)

    # 4. Grille dense en R/R0 pour tracer la courbe lisse
    logR_min, logR_max = logR_j.min(), logR_j.max()
    logR_dense = np.linspace(logR_min, logR_max, 400)
    R_dense = 10**logR_dense
    fR_dense = 10 ** p_fR(logR_dense)
    fRR_dense = 10 ** p_fRR(logR_dense)

    # 5. Tracé
    fig, ax1 = plt.subplots(dpi=300, figsize=(6, 4))

    #   5a. Courbe PCHIP fR
    color1 = "tab:blue"
    ax1.plot(R_dense, fR_dense, color=color1, lw=1.5, label=r"PCHIP $f_R$")
    #   5b. Points jalons fR
    ax1.scatter(
        jalons["R_over_R0"],
        jalons["f_R"],
        c=color1,
        marker="o",
        s=40,
        alpha=0.8,
        label=r"Jalons $f_R$",
    )

    ax1.set_xscale("log")
    ax1.set_yscale("log")
    ax1.set_xlabel(r"$R/R_0$")
    ax1.set_ylabel(r"$f_R$", color=color1)
    ax1.tick_params(axis="y", labelcolor=color1)
    ax1.grid(True, which="both", ls=":", alpha=0.3)

    #   5c. Courbe PCHIP fRR sur axe droit
    ax2 = ax1.twinx()
    color2 = "tab:orange"
    ax2.plot(
        R_dense,
        fRR_dense,
        color=color2,
        lw=1.5,
        linestyle="--",
        label=r"PCHIP $f_{RR}$",
    )
    #   5d. Points jalons fRR
    ax2.scatter(
        jalons["R_over_R0"],
        jalons["f_RR"],
        c=color2,
        marker="s",
        s=50,
        alpha=0.8,
        label=r"Jalons $f_{RR}$",
    )
    ax2.set_yscale("log")
    ax2.set_ylabel(r"$f_{RR}$", color=color2)
    ax2.tick_params(axis="y", labelcolor=color2)

    # 6. Légende commune
    h1, l1 = ax1.get_legend_handles_labels()
    h2, l2 = ax2.get_legend_handles_labels()
    ax1.legend(h1 + h2, l1 + l2, loc="best", framealpha=0.8, edgecolor="black")

    # 7. Titre
    ax1.set_title("Interpolation PCHIP vs points de jalons")

    # 8. Finalisation et sauvegarde
    fig.subplots_adjust(left=0.04, right=0.98, bottom=0.06, top=0.96)
    fig.savefig(FIG_PATH)
    plt.close(fig)
    log.info("Figure enregistrée → %s", FIG_PATH)


if __name__ == "__main__":
    main()

# [MCGT POSTPARSE EPILOGUE v2]
# (compact) delegate to common helper; best-effort wrapper
try:
    import os
    import sys

    from _common.cli import add_common_plot_args, finalize_plot_from_args, init_logging

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
def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="(autofix)",)
    C.add_common_plot_args(p)
    return p
