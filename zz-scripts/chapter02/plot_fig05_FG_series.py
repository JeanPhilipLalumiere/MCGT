#!/usr/bin/env python3
"""
Tracer les séries brutes F(α)−1 et G(α) pour le Chapitre 2 (MCGT)

Produit :
- zz-figures/chapter02/02_fig_05_fg_series.png

Données sources :
- zz-data/chapter02/02_As_ns_vs_alpha.csv
"""

from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd

# Constantes Planck 2018
A_S0 = 2.10e-9
NS0 = 0.9649

# Chemins
ROOT = Path(__file__).resolve().parents[2]
DATA_IN = ROOT / "zz-data" / "chapter02" / "02_As_ns_vs_alpha.csv"
OUT_PLOT = ROOT / "zz-figures" / "chapter02" / "fig_05_FG_series.png"


def main():
    # Lecture des données
    df = pd.read_csv(DATA_IN)
    alpha = df["alpha"].values
    As = df["A_s"].values
    ns = df["n_s"].values

    # Calcul des séries
    Fm1 = As / A_S0 - 1.0
    Gm = ns - NS0

    # Tracé
    plt.figure()
    plt.plot(alpha, Fm1, marker="o", linestyle="-", label=r"$F(\alpha)-1$")
    plt.plot(alpha, Gm, marker="s", linestyle="--", label=r"$G(\alpha)$")
    plt.xlabel(r"$\alpha$")
    plt.ylabel("Valeur")
    plt.title("Séries $F(\\alpha)-1$ et $G(\\alpha)$")
    plt.grid(True, which="both", ls=":")
    plt.legend()
    plt.tight_layout()
    plt.savefig(OUT_PLOT, dpi=300)
    plt.close()
    print(f"Figure enregistrée → {OUT_PLOT}")


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
