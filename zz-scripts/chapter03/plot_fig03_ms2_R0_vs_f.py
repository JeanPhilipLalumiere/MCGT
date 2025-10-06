#!/usr/bin/env python3
# tracer_fig03_ms2_R0_contre_R.py
"""
Trace m_s²/R₀ en fonction de R/R₀ — Chapitre 3
==============================================

Entrée  :
    zz-data/chapter03/03_fR_stability_data.csv
Colonnes requises :
    R_over_R0, m_s2_over_R0

Sortie  :
    zz-figures/chapter03/03_fig_03_ms2_r0_vs_r.png
"""

import logging
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd

# ----------------------------------------------------------------------
# Logging
# ----------------------------------------------------------------------
logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")
log = logging.getLogger(__name__)

# ----------------------------------------------------------------------
# Chemins
# ----------------------------------------------------------------------
DATA_FILE = Path("zz-data") / "chapter03" / "03_fR_stability_data.csv"
FIG_DIR = Path("zz-figures") / "chapter03"
FIG_PATH = FIG_DIR / "fig_03_ms2_R0_vs_R.png"


def main() -> None:
    # 1. Chargement
    if not DATA_FILE.exists():
        log.error("Fichier introuvable : %s", DATA_FILE)
        return
    df = pd.read_csv(DATA_FILE)
    if not {"R_over_R0", "m_s2_over_R0"}.issubset(df.columns):
        log.error("Colonnes manquantes dans %s", DATA_FILE)
        return

    # 2. Préparation du dossier de sortie
    FIG_DIR.mkdir(parents=True, exist_ok=True)

    # 3. Tracé principal (log-log)
    fig, ax = plt.subplots(dpi=300, figsize=(6, 4))
    ax.loglog(
        df["R_over_R0"],
        df["m_s2_over_R0"],
        color="tab:blue",
        lw=1.5,
        label=r"$m_s^2/R_0$",
    )
    ax.set_xlabel(r"$R/R_0$")
    ax.set_ylabel(r"$m_s^{2}/R_0$")
    ax.set_title(r"Évolution de $m_s^{2}/R_0$ en fonction de $R/R_0$")
    ax.grid(True, which="both", ls="--", alpha=0.2)
    ax.legend(loc="upper right", framealpha=0.8, edgecolor="black")

    # 4. Inset « haute courbure » : on cible la région critique [1e4, 1e6]
    df_zoom = df[(df["R_over_R0"] >= 1e4) & (df["R_over_R0"] <= 1e6)]
    if not df_zoom.empty:
        # déplacer légèrement le zoom plus bas
        ax_in = fig.add_axes([0.60, 0.25, 0.33, 0.33])

        # tracé
        ax_in.loglog(
            df_zoom["R_over_R0"],
            df_zoom["m_s2_over_R0"],
            color="tab:blue",
            lw=1.2 )

        # limites
        ax_in.set_xlim(1e4, 1e6)
        ax_in.set_ylim(
            df_zoom["m_s2_over_R0"].min() * 0.9,
            df_zoom["m_s2_over_R0"].max() * 1.1 )

        # Graduations X : 3 points fixes [1e4,1e5,1e6]
        from matplotlib.ticker import FixedLocator, FuncFormatter, NullLocator

        xticks = [1e4, 1e5, 1e6]
        ax_in.xaxis.set_major_locator(FixedLocator(xticks))
        ax_in.xaxis.set_minor_locator(NullLocator())
        ax_in.xaxis.set_major_formatter(
            FuncFormatter(lambda x, _: f"{int(x):.0e}"))
        ax_in.tick_params(axis="x", which="major", pad=3, rotation=0)

        # Graduations Y : 4 points log-uniformes
        from matplotlib.ticker import LogLocator, ScalarFormatter

        ax_in.yaxis.set_major_locator(LogLocator(base=10, numticks=4))
        ax_in.yaxis.set_minor_locator(NullLocator())
        sf = ScalarFormatter(useMathText=True)
        sf.set_scientific(False)  # supprime le ×10ⁿ
        ax_in.yaxis.set_major_formatter(sf)
        ax_in.tick_params(axis="y", which="major", pad=2)

        ax_in.set_title("Zoom haute courbure", fontsize=8)
        ax_in.grid(True, which="both", ls=":", alpha=0.3)

    # 5. Finalisation
    plt.tight_layout()
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
