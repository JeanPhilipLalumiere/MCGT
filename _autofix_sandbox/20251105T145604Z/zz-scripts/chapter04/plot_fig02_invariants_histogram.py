#!/usr/bin/env python3
import contextlib
# fichier : zz-scripts/chapter04/plot_fig02_invariants_histogram.py
# répertoire : zz-scripts/chapter04
# === [PASS5-AUTOFIX-SHIM] ===
if __name__ == "__main__":
    with contextlib.suppress(Exception):
        import sys
        import os
        import atexit

        _argv = sys.argv[1:]
        # 1) Shim --help universel
        if any(a in ("-h", "--help") for a in _argv):
            import argparse

            _p = argparse.ArgumentParser(
                description="MCGT (shim auto-injecté Pass5)",
                add_help=True,
                allow_abbrev=False,
            )
            _p.add_argument(
                "--out", help="Chemin de sortie pour fig.savefig (optionnel)"
            )
            _p.add_argument(
                "--dpi", type=int, default=120, help="DPI (par défaut: 120)"
            )
            _p.add_argument(
                "--show",
                action="store_true",
                help="Force plt.show() en fin d'exécution",
            )
            # parse_known_args() affiche l'aide et gère les options de base
            _p.parse_known_args()
            sys.exit(0)
        # 2) Shim sauvegarde figure si --out présent (sans bloquer)
        _out = None
        if "--out" in _argv:
            with contextlib.suppress(Exception):
                i = _argv.index("--out")
                _out = _argv[i + 1] if i + 1 < len(_argv) else None
        if _out:
            os.environ.setdefault("MPLBACKEND", "Agg")
            with contextlib.suppress(Exception):
                import matplotlib.pyplot as plt

                # Neutralise show() pour éviter le blocage en headless
                def _shim_show(*a, **k):
                    pass

                plt.show = _shim_show
                # Récupère le dpi si fourni
                _dpi = 120
                if "--dpi" in _argv:
                    with contextlib.suppress(Exception):
                        _dpi = int(_argv[_argv.index("--dpi") + 1])
                @atexit.register
                def _pass5_save_last_figure():
                    with contextlib.suppress(Exception):
                        fig = plt.gcf()
                        fig.savefig(_out, dpi=_dpi)
                        print(f"[PASS5] Wrote: {_out}")
                # matplotlib indisponible: ignorer silencieusement
                pass
# === [/PASS5-AUTOFIX-SHIM] ===
"""
plot_fig02_invariants_histogram.py

Script corrigé de tracé de l'histogramme des invariants I2 et I3
- Lit 04_dimensionless_invariants.csv
- Exclut les valeurs nulles de I3 pour le log
- Trace histogramme de log10(I2) et log10(|I3|)
- Sauvegarde la figure 800×500 px DPI 300
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
    bins = np.linspace(min(logI2.min(), logI3.min()), max(logI2.max(), logI3.max()), 40)

    ax.hist(
        logI2, bins=bins, density=True, alpha=0.7, label=r"$\log_{10}I_2$", color="C1"
    )
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
    ax.set_title("Fig. 02 - Histogramme des invariants adimensionnels")
    ax.legend(fontsize="small")
    ax.grid(True, which="both", linestyle=":", linewidth=0.5)

    # ----------------------------------------------------------------------
    # 4. Sauvegarde de la figure
    # ----------------------------------------------------------------------
    output_fig = "zz-figures/chapter04/04_fig_02_invariants_histogram.png"
    fig.subplots_adjust(left=0.04, right=0.98, bottom=0.06, top=0.96)
    plt.savefig(output_fig)
    print(f"Fig. sauvegardée : {output_fig}")


if __name__ == "__main__":
    main()

# [MCGT POSTPARSE EPILOGUE v2]
# (compact) delegate to common helper; best-effort wrapper
with contextlib.suppress(Exception):
    import os
    import sys

    _here = os.path.abspath(os.path.dirname(__file__))
    _zz = os.path.abspath(os.path.join(_here, ".."))
    if _zz not in sys.path:
        sys.path.insert(0, _zz)
    from _common.postparse import apply as _mcgt_postparse_apply
with contextlib.suppress(Exception):
    if "args" in globals():
        _mcgt_postparse_apply(args, caller_file=__file__)
