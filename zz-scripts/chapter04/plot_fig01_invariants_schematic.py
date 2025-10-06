#!/usr/bin/env python3
"""
plot_fig01_invariants_schematic.py

Script corrigé de tracé du schéma conceptuel des invariants adimensionnels
– Lit 04_dimensionless_invariants.csv
– Trace I1, I2, I3 vs log10(T) avec symlog pour I3
– Marque les phases et les repères pour I2 et I3
– Sauvegarde la figure 800x500 px DPI 300
"""

import matplotlib.pyplot as plt
import pandas as pd


def main():
    # ----------------------------------------------------------------------
    # 1. Chargement des données
    # ----------------------------------------------------------------------
    data_file = "zz-data/chapter04/04_dimensionless_invariants.csv"
    df = pd.read_csv(data_file)
    T = df["T_Gyr"].values
    I1 = df["I1"].values
    I2 = df["I2"].values
    I3 = df["I3"].values

    # Valeurs clés
    Tp = 0.087  # Gyr
    I2_ref = 1e-35
    I3_ref = 1e-6

    # ----------------------------------------------------------------------
    # 2. Création de la figure
    # ----------------------------------------------------------------------
    fig, ax = plt.subplots(figsize=(8, 5), dpi=300)

    # Axe X en log
    ax.set_xscale("log")

    # Axe Y en symlog pour gérer I3 autour de zéro
    ax.set_yscale("symlog", linthresh=1e-7, linscale=1)

    # Tracés des invariants
    ax.plot(T, I1, label=r"$I_1 = P/T$", color="C0", linewidth=1.5)
    ax.plot(T, I2, label=r"$I_2 = \kappa\,T^2$", color="C1", linewidth=1.5)
    ax.plot(T, I3, label=r"$I_3 = f_R - 1$", color="C2", linewidth=1.5)

    # ----------------------------------------------------------------------
    # 3. Repères horizontaux
    # ----------------------------------------------------------------------
    ax.axhline(
        I2_ref,
        color="C1",
        linestyle="--",
        label=r"$I_2 \approx 10^{-35}$")
    ax.axhline(
        I3_ref,
        color="C2",
        linestyle="--",
        label=r"$I_3 \approx 10^{-6}$")

    # ----------------------------------------------------------------------
    # 4. Repère vertical de transition T_p
    # ----------------------------------------------------------------------
    ax.axvline(Tp, color="orange", linestyle=":",
               label=r"$T_p=0.087\ \mathrm{Gyr}$")

    # ----------------------------------------------------------------------
    # 5. Légendes, labels et grille
    # ----------------------------------------------------------------------
    ax.set_xlabel(r"$T\ (\mathrm{Gyr})$")
    ax.set_ylabel("Valeurs adimensionnelles")
    ax.set_title("Fig. 01 – Schéma conceptuel des invariants adimensionnels")
    ax.legend(loc="best", fontsize="small")
    ax.grid(True, which="both", linestyle=":", linewidth=0.5)

    # ----------------------------------------------------------------------
    # 6. Sauvegarde de la figure
    # ----------------------------------------------------------------------
    output_fig = "zz-figures/chapter04/04_fig_01_invariants_schematic.png"
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
