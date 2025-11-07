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
# fichier : zz-scripts/chapter03/plot_fig04_fR_fRR_vs_f.py
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
# tracer_fig04_fR_fRR_contre_R.py
"""
Trace f_R et f_RR (double axe) en fonction de R/R₀ — Chapitre 3
===============================================================

Objectif : proposer une vue complémentaire à fig_02, avec deux axes Y pour
rendre lisible la différence d’échelle entre f_R (≈O(1)) et f_RR (≈O(10⁻⁶)),
et marquer le point pivot à R/R₀ = 1.

Entrée  :
    zz-data/chapter03/03_fR_stability_data.csv
Colonnes requises :
    R_over_R0, f_R, f_RR

Sortie  :
    zz-figures/chapter03/03_fig_04_fr_frr_vs_r.png
"""

import logging
from pathlib import Path

import matplotlib.pyplot as plt
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
FIG_PATH = FIG_DIR / "fig_04_fR_fRR_vs_R.png"


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

    # 3. Création de la figure
    fig, ax1 = plt.subplots(dpi=300, figsize=(6, 4))
    fig.suptitle(r"$f_R$ et $f_{RR}$ en fonction de $R/R_0$ (double axe)", y=0.98)

    # axe X en log
    ax1.set_xscale("log")
    ax1.set_xlabel(r"$R/R_0$")

    # 4. Tracé de f_R sur l'axe de gauche
    (ln1,) = ax1.loglog(
        df["R_over_R0"], df["f_R"], color="tab:blue", lw=1.5, label=r"$f_R(R)$"
    )
    ax1.set_ylabel(r"$f_R$", color="tab:blue")
    ax1.tick_params(axis="y", labelcolor="tab:blue")
    ax1.grid(True, which="both", ls="--", alpha=0.2)

    # 5. Tracé de f_RR sur l'axe de droite
    ax2 = ax1.twinx()
    ax2.set_yscale("log")
    (ln2,) = ax2.loglog(
        df["R_over_R0"], df["f_RR"], color="tab:orange", lw=1.5, label=r"$f_{RR}(R)$"
    )
    ax2.set_ylabel(r"$f_{RR}$", color="tab:orange")
    ax2.tick_params(axis="y", labelcolor="tab:orange")

    # 6. Marqueur vertical du pivot à R/R0 = 1
    ln3 = ax1.axvline(
        1.0, color="gray", linestyle="--", lw=1.0, label="Pivot : $R/R_0=1$"
    )

    # 7. Légende explicite
    handles = [ln1, ln2, ln3]
    labels = [h.get_label() for h in handles]
    ax1.legend(
        handles,
        labels,
        loc="upper left",
        bbox_to_anchor=(0.25, 0.50),
        framealpha=0.9,
        edgecolor="black",
    )

    # 8. Mise en forme finale et sauvegarde
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
