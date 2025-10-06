#!/usr/bin/env python3
# tracer_fig01_stabilite_fR_domaine.py
"""
Trace le domaine de stabilité de f(R) — Chapitre 3
===================================================

Affiche la zone où γ ∈ [0, γ_max(β)] en fonction de β = R/R₀.

Entrée :
    zz-data/chapter03/03_fR_stability_domain.csv
Colonnes requises :
    beta, gamma_min, gamma_max

Sortie :
    zz-figures/chapter03/03_fig_01_fr_stability_domain.png
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
DATA_FILE = Path("zz-data") / "chapter03" / "03_fR_stability_domain.csv"
FIG_DIR = Path("zz-figures") / "chapter03"
FIG_PATH = FIG_DIR / "fig_01_fR_stability_domain.png"


def main() -> None:
    # 1. Lecture des données
    if not DATA_FILE.exists():
        log.error("Fichier manquant : %s", DATA_FILE)
        return
    df = pd.read_csv(DATA_FILE)
    required = {"beta", "gamma_min", "gamma_max"}
    missing = required - set(df.columns)
    if missing:
        log.error("Colonnes manquantes dans %s : %s", DATA_FILE, missing)
        return

    # 2. Création du dossier de sortie
    FIG_DIR.mkdir(parents=True, exist_ok=True)

    # 3. Tracé principal
    fig, ax = plt.subplots(dpi=300, figsize=(6, 4))

    # Zone de stabilité
    ax.fill_between(
        df["beta"],
        df["gamma_min"],
        df["gamma_max"],
        color="lightgray",
        alpha=0.5,
        label="Domaine de stabilité",
    )

    # Repère β = 1
    ax.axvline(
        1.0,
        color="gray",
        linestyle="--",
        linewidth=1.0,
        label=r"$\beta = 1$")

    # Échelles log-log
    ax.set_xscale("log")
    ax.set_yscale("log")
    ax.set_xlabel(r"$\beta = R / R_0$")
    ax.set_ylabel(r"$\gamma$ (sans dimension)")
    ax.set_title("Domaine de stabilité de $f(R)$ (Chapitre 3)")

    ax.grid(True, which="both", ls=":", alpha=0.2)

    legend = ax.legend(loc="upper right", framealpha=0.8)
    legend.get_frame().set_edgecolor("black")

    # ------------------------------------------------------------------
    # 4. Inset : zoom β ∈ [0.5, 2] (X linéaire, Y log)
    # ------------------------------------------------------------------
    mask = (df["beta"] >= 0.5) & (df["beta"] <= 2.0)
    if mask.any():
        ax_in = fig.add_axes([0.60, 0.30, 0.35, 0.35])

        # Tracé γ_max (et γ_min si ≠0)
        ax_in.plot( df.loc[mask, "beta"], df.loc[mask,
                                                 "gamma_max"], color="black", lw=1.2 )
        if (df.loc[mask, "gamma_min"] > 0).any():
            ax_in.plot( df.loc[mask, "beta"], df.loc[mask,
                                                     "gamma_min"], color="black", lw=1.2 )

        # Échelles : X linéaire, Y log
        from matplotlib.ticker import (
            FixedLocator,
            FuncFormatter,
            LogLocator,
            NullFormatter,
            ScalarFormatter,
        )

        ax_in.set_xscale("linear")
        ax_in.set_xlim(0.5, 2.0)
        ax_in.xaxis.set_major_locator(FixedLocator([0.5, 1.0, 1.5, 2.0]))
        ax_in.xaxis.set_major_formatter(FuncFormatter(lambda x, _: f"{x:.1f}"))
        ax_in.xaxis.set_minor_formatter(NullFormatter())

        ax_in.set_yscale("log")
        ax_in.yaxis.set_major_locator(LogLocator(numticks=4))
        yfmt = ScalarFormatter()
        yfmt.set_scientific(False)
        yfmt.set_useOffset(False)
        ax_in.yaxis.set_major_formatter(yfmt)

        # Nettoyage des graduations superflues
        ax_in.tick_params(axis="both", which="both", length=3)
        ax_in.grid(True, which="both", ls=":", alpha=0.3)
        ax_in.set_title(r"Zoom $\beta\in[0.5,2]$", fontsize=8, pad=2)

    # 5. Finalisation et sauvegarde
    fig.tight_layout()
    fig.savefig(FIG_PATH)
    plt.close(fig)
    log.info("Figure enregistrée → %s", FIG_PATH)


if __name__ == "__main__":
    main()

# [MCGT POSTPARSE EPILOGUE v1]
try:
    # On n agit que si un objet args existe au global
    if "args" in globals():
        import os
        import atexit
        # 1) Fallback via MCGT_OUTDIR si outdir est vide/None
        env_out = os.environ.get("MCGT_OUTDIR")
        if getattr(args, "outdir", None) in (None, "", False) and env_out:
            args.outdir = env_out
        # 2) Création sûre du répertoire s il est défini
        if getattr(args, "outdir", None):
            try:
                os.makedirs(args.outdir, exist_ok=True)
            except Exception:
                pass
        # 3) rcParams savefig si des attributs existent
        try:
            import matplotlib
            _rc = {}
            if hasattr(args, "dpi") and args.dpi:
                _rc["savefig.dpi"] = args.dpi
            if hasattr(args, "fmt") and args.fmt:
                _rc["savefig.format"] = args.fmt
            if hasattr(args, "transparent"):
                _rc["savefig.transparent"] = bool(args.transparent)
            if _rc:
                matplotlib.rcParams.update(_rc)
        except Exception:
            pass
        # 4) Copier automatiquement le dernier PNG vers outdir à la fin

        def _smoke_copy_latest():
            try:
                if not getattr(args, "outdir", None):
                    return
                import glob
                import os
                import shutil
                _ch = os.path.basename(os.path.dirname(__file__))
                _repo = os.path.abspath(
                    os.path.join(
                        os.path.dirname(__file__),
                        "..",
                        ".."))
                _default_dir = os.path.join(_repo, "zz-figures", _ch)
                pngs = sorted(
                    glob.glob(os.path.join(_default_dir, "*.png")),
                    key=os.path.getmtime,
                    reverse=True,
                )
                for _p in pngs:
                    if os.path.exists(_p):
                        _dst = os.path.join(args.outdir, os.path.basename(_p))
                        if not os.path.exists(_dst):
                            shutil.copy2(_p, _dst)
                        break
            except Exception:
                pass
        atexit.register(_smoke_copy_latest)
except Exception:
    # épilogue best-effort — ne doit jamais casser le script principal
    pass
