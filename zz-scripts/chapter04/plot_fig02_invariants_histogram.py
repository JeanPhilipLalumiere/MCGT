#!/usr/bin/env python3
"""
plot_fig02_invariants_histogram.py

Script corrigé de tracé de l'histogramme des invariants I2 et I3
– Lit 04_dimensionless_invariants.csv
– Exclut les valeurs nulles de I3 pour le log
– Trace histogramme de log10(I2) et log10(|I3|)
– Sauvegarde la figure 800×500 px DPI 300
"""

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd


def main():
    # ----------------------------------------------------------------------
    # 1. Chargement des données
    # ----------------------------------------------------------------------
    data_file = "zz-data/chapter04/04_dimensionless_invariants.csv"
    df = pd.read_csv(data_file)
    logI2 = np.log10(df["I2"].values)
    # Exclure I3 = 0 pour log10
    I3_vals = df["I3"].values
    I3_nonzero = I3_vals[I3_vals != 0]
    logI3 = np.log10(np.abs(I3_nonzero))

    # ----------------------------------------------------------------------
    # 2. Création de la figure
    # ----------------------------------------------------------------------
    fig, ax = plt.subplots(figsize=(8, 5), dpi=300)

    # Définir les bins plus fins
    bins = np.linspace(min(logI2.min(), logI3.min()),
                       max(logI2.max(), logI3.max()), 40)

    ax.hist(
        logI2,
        bins=bins,
        density=True,
        alpha=0.7,
        label=r"$\log_{10}I_2$",
        color="C1" )
    ax.hist(
        logI3,
        bins=bins,
        density=True,
        alpha=0.7,
        label=r"$\log_{10}\lvert I_3\rvert$",
        color="C2",
    )

    # ----------------------------------------------------------------------
    # 3. Labels, légende et grille
    # ----------------------------------------------------------------------
    ax.set_xlabel(r"$\log_{10}\bigl(\mathrm{valeur\ de\ l’invariant}\bigr)$")
    ax.set_ylabel("Densité normalisée")
    ax.set_title("Fig. 02 – Histogramme des invariants adimensionnels")
    ax.legend(fontsize="small")
    ax.grid(True, which="both", linestyle=":", linewidth=0.5)

    # ----------------------------------------------------------------------
    # 4. Sauvegarde de la figure
    # ----------------------------------------------------------------------
    output_fig = "zz-figures/chapter04/04_fig_02_invariants_histogram.png"
    plt.tight_layout()
    plt.savefig(output_fig)
    print(f"Fig. sauvegardée : {output_fig}")


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
