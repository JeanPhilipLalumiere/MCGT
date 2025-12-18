import hashlib
import shutil
import tempfile
from pathlib import Path as _SafePath

import matplotlib.pyplot as plt

plt.rcParams.update(
    {
        "figure.autolayout": True,
        "figure.figsize": (10, 6),
        "axes.titlepad": 25,
        "axes.labelpad": 15,
        "savefig.bbox": "tight",
        "savefig.pad_inches": 0.3,
        "font.family": "serif",
    }
)

def _sha256(path: _SafePath) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()

def safe_save(filepath, fig=None, **savefig_kwargs):
    path = _SafePath(filepath)
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        with tempfile.NamedTemporaryFile(delete=False, suffix=path.suffix) as tmp:
            tmp_path = _SafePath(tmp.name)
        try:
            if fig is not None:
                fig.savefig(tmp_path, **savefig_kwargs)
            else:
                plt.savefig(tmp_path, **savefig_kwargs)
            if _sha256(tmp_path) == _sha256(path):
                tmp_path.unlink()
                return False
            shutil.move(tmp_path, path)
            return True
        finally:
            if tmp_path.exists():
                tmp_path.unlink()
    if fig is not None:
        fig.savefig(path, **savefig_kwargs)
    else:
        plt.savefig(path, **savefig_kwargs)
    return True

#!/usr/bin/env python3
# === [PASS5B-SHIM] ===
# Shim minimal pour rendre --help et --out sûrs sans effets de bord.
import os, sys, atexit
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
                        safe_save(out, dpi=120)
                except Exception:
                    pass
        atexit.register(_auto_save)
    except Exception:
        pass
# === [/PASS5B-SHIM] ===
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
FIG_PATH = FIG_DIR / "03_fig_01_fr_stability_domain.png"


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
        label="Stability Domain",
    )

    # Repère β = 1
    ax.axvline(1.0, color="gray", linestyle="--", linewidth=1.0, label=r"$\beta = 1$")

    # Échelles log-log
    ax.set_xscale("log")
    ax.set_yscale("log")
    ax.set_xlabel(r"$\beta = R / R_0$")
    ax.set_ylabel(r"$\gamma$ [dimensionless]")
    ax.set_title("Stability Domain of f(R) - Chapter 3")

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
        ax_in.plot(
            df.loc[mask, "beta"], df.loc[mask, "gamma_max"], color="black", lw=1.2
        )
        if (df.loc[mask, "gamma_min"] > 0).any():
            ax_in.plot(
                df.loc[mask, "beta"], df.loc[mask, "gamma_min"], color="black", lw=1.2
            )

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
    fig.subplots_adjust(left=0.04, right=0.98, bottom=0.06, top=0.96)
    safe_save(FIG_PATH)
    plt.close(fig)
    log.info("Figure enregistrée → %s", FIG_PATH)


if __name__ == "__main__":
    main()

# [MCGT POSTPARSE EPILOGUE v2]
# (compact) delegate to common helper; best-effort wrapper
try:
    import os
    import sys
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
