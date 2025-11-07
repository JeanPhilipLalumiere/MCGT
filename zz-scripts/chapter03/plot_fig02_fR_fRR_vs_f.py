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
# fichier : zz-scripts/chapter03/plot_fig02_fR_fRR_vs_f.py
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
# tracer_fig02_fR_fRR_contre_R.py
"""
Trace f_R et f_RR en fonction de R/R₀ — Chapitre 3
=================================================

Entrée :
    zz-data/chapter03/03_fR_stability_data.csv
Colonnes requises :
    R_over_R0, f_R, f_RR

Sortie :
    zz-figures/chapter03/03_fig_02_fr_frr_vs_r.png
"""

import logging
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd
from matplotlib.ticker import FixedLocator, FuncFormatter, NullLocator

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
FIG_PATH = FIG_DIR / "fig_02_fR_fRR_vs_R.png"


# ----------------------------------------------------------------------
# Main
# ----------------------------------------------------------------------
def main() -> None:
    # 1. Lecture des données
    if not DATA_FILE.exists():
        log.error("Fichier introuvable : %s", DATA_FILE)
        return

    df = pd.read_csv(DATA_FILE)
    required = {"R_over_R0", "f_R", "f_RR"}
    missing = required - set(df.columns)
    if missing:
        log.error("Colonnes manquantes dans %s : %s", DATA_FILE, missing)
        return

    # 2. Préparation du dossier de sortie
    FIG_DIR.mkdir(parents=True, exist_ok=True)

    # 3. Graphique principal
    fig, ax = plt.subplots(dpi=300, figsize=(6, 4))
    ax.loglog(df["R_over_R0"], df["f_R"], color="tab:blue", lw=1.5, label=r"$f_R(R)$")
    ax.loglog(
        df["R_over_R0"], df["f_RR"], color="tab:orange", lw=1.5, label=r"$f_{RR}(R)$"
    )

    ax.set_xlabel(r"$R/R_0$")
    ax.set_ylabel(r"$f_R,\;f_{RR}$")
    ax.set_title(r"$f_R$ et $f_{RR}$ en fonction de $R/R_0$")
    ax.grid(True, which="both", ls=":", alpha=0.3)

    # 4. Légende à mi-hauteur complètement à gauche
    ax.legend(
        loc="center left", bbox_to_anchor=(0.01, 0.5), framealpha=0.8, edgecolor="black"
    )

    # 5. Inset zoom sur f_RR (premiers 50 points)
    import numpy as np

    df_zoom = df.iloc[:50]
    ax_in = fig.add_axes([0.62, 0.30, 0.30, 0.30])
    ax_in.loglog(df_zoom["R_over_R0"], df_zoom["f_RR"], color="tab:orange", lw=1.5)

    ax_in.set_xscale("log")
    ax_in.set_yscale("linear")
    ax_in.set_xlim(df_zoom["R_over_R0"].min(), df_zoom["R_over_R0"].max())

    # graduations x (4 points logarithmiques)
    lmin, lmax = (
        np.log10(df_zoom["R_over_R0"].min()),
        np.log10(df_zoom["R_over_R0"].max()),
    )
    xticks = 10 ** np.linspace(lmin, lmax, 4)
    ax_in.xaxis.set_major_locator(FixedLocator(xticks))
    ax_in.xaxis.set_major_formatter(FuncFormatter(lambda x, _: f"{x:.0f}"))
    ax_in.xaxis.set_minor_locator(NullLocator())

    # graduations y (4 points linéaires)
    ymin, ymax = df_zoom["f_RR"].min(), df_zoom["f_RR"].max()
    yticks = np.linspace(ymin, ymax, 4)
    ax_in.yaxis.set_major_locator(FixedLocator(yticks))
    ax_in.yaxis.set_major_formatter(FuncFormatter(lambda y, _: f"{y:.2e}"))
    ax_in.yaxis.set_minor_locator(NullLocator())

    ax_in.set_title(r"Zoom $f_{RR}$", fontsize=8)
    ax_in.grid(True, which="both", ls=":", alpha=0.3)

    # 6. Sauvegarde
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
