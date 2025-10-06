#!/usr/bin/env python3
# tracer_fig08_ricci_fR_contre_T.py

"""
Trace f_R et f_RR aux points jalons en fonction de l’âge de l’Univers (Gyr) — Chapitre 3
=======================================================================================

Entrée :
    zz-data/chapter03/03_ricci_fR_vs_T.csv
Colonnes requises :
    R_over_R0, f_R, f_RR, T_Gyr

Sortie :
    zz-figures/chapter03/03_fig_08_ricci_fr_vs_t.png
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
DATA_FILE = Path("zz-data") / "chapter03" / "03_ricci_fR_vs_T.csv"
FIG_DIR = Path("zz-figures") / "chapter03"
FIG_PATH = FIG_DIR / "fig_08_ricci_fR_vs_T.png"


def main() -> None:
    # 1. Lecture des données
    if not DATA_FILE.exists():
        log.error("Fichier introuvable : %s", DATA_FILE)
        return

    df = pd.read_csv(DATA_FILE)
    required = {"R_over_R0", "f_R", "f_RR", "T_Gyr"}
    missing = required - set(df.columns)
    if missing:
        log.error("Colonnes manquantes dans %s : %s", DATA_FILE, missing)
        return

    # 2. Filtrer T>0 et trier
    df = df[df["T_Gyr"] > 0].sort_values("T_Gyr")
    if df.empty:
        log.error("Aucune donnée positive pour T_Gyr dans %s", DATA_FILE)
        return

    # 3. Préparation du dossier figure
    FIG_DIR.mkdir(parents=True, exist_ok=True)

    # 4. Tracé principal avec double axe Y
    fig, ax1 = plt.subplots(dpi=300, figsize=(6, 4))

    # Axe de gauche : f_R
    color1 = "tab:blue"
    ax1.scatter(
        df["T_Gyr"],
        df["f_R"],
        c=color1,
        marker="o",
        s=40,
        label=r"$f_R$")
    ax1.plot(df["T_Gyr"], df["f_R"], c=color1, lw=1, alpha=0.6)
    ax1.set_xscale("log")
    ax1.set_yscale("log")
    ax1.set_xlabel("Âge de l’Univers $T$ (Gyr)")
    ax1.set_ylabel(r"$f_R$", color=color1)
    ax1.tick_params(axis="y", labelcolor=color1)
    ax1.grid(True, which="both", ls=":", alpha=0.3)

    # Axe de droite : f_RR
    ax2 = ax1.twinx()
    color2 = "tab:orange"
    ax2.scatter(
        df["T_Gyr"],
        df["f_RR"],
        c=color2,
        marker="s",
        s=50,
        label=r"$f_{RR}$")
    ax2.plot(
        df["T_Gyr"],
        df["f_RR"],
        c=color2,
        lw=1,
        alpha=0.6,
        linestyle="--")
    ax2.set_yscale("log")
    ax2.set_ylabel(r"$f_{RR}$", color=color2)
    ax2.tick_params(axis="y", labelcolor=color2)

    # 5. Légende commune
    handles1, labels1 = ax1.get_legend_handles_labels()
    handles2, labels2 = ax2.get_legend_handles_labels()
    ax1.legend(
        handles1 + handles2,
        labels1 + labels2,
        loc="best",
        framealpha=0.8,
        edgecolor="black",
    )

    # 6. Titre
    Tmin, Tmax = df["T_Gyr"].min(), df["T_Gyr"].max()
    ax1.set_title(
        rf"Jalons $f_R$ et $f_{ RR} $ vs âge $T\in[{
            Tmin:.2f},{
            Tmax:.2f}]\,$Gyr" )

    # 7. Finalisation
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
