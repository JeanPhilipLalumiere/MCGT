#!/usr/bin/env python3
# === [PASS5-AUTOFIX-SHIM] ===
if __name__ == "__main__":
    try:
        import sys, os, atexit
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
                "--out",
                help="Chemin de sortie pour fig.savefig (optionnel)",
            )
            _p.add_argument(
                "--dpi",
                type=int,
                default=120,
                help="DPI (par défaut: 120)",
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
            try:
                i = _argv.index("--out")
                _out = _argv[i + 1] if i + 1 < len(_argv) else None
            except Exception:
                _out = None
        if _out:
            os.environ.setdefault("MPLBACKEND", "Agg")
            try:
                import matplotlib.pyplot as plt

                # Neutralise show() pour éviter le blocage en headless
                def _shim_show(*a, **k):
                    pass

                plt.show = _shim_show
                # Récupère le dpi si fourni
                _dpi = 120
                if "--dpi" in _argv:
                    try:
                        _dpi = int(_argv[_argv.index("--dpi") + 1])
                    except Exception:
                        _dpi = 120

                @atexit.register
                def _pass5_save_last_figure():
                    try:
                        fig = plt.gcf()
                        fig.savefig(_out, dpi=_dpi)
                        print(f"[PASS5] Wrote: {_out}")
                    except Exception as _e:
                        print(f"[PASS5] savefig failed: {_e}")
            except Exception:
                # matplotlib indisponible: ignorer silencieusement
                pass
    except Exception:
        # N'empêche jamais le script original d'exécuter
        pass
# === [/PASS5-AUTOFIX-SHIM] ===
"""
Tracer l'ajustement polynomial de A_s(α) et n_s(α) pour le Chapitre 2 (MCGT)

Produit :
- zz-figures/chapter02/02_fig_06_alpha_fit.png

Données sources :
- zz-data/chapter02/02_As_ns_vs_alpha.csv
- zz-data/chapter02/02_primordial_spectrum_spec.json
"""

import json
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd

# Répertoires / chemins
ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = ROOT / "zz-data" / "chapter02"
FIG_DIR = ROOT / "zz-figures" / "chapter02"
DATA_IN = DATA_DIR / "02_As_ns_vs_alpha.csv"
SPEC_JS = DATA_DIR / "02_primordial_spectrum_spec.json"
OUT_PLOT = FIG_DIR / "02_fig_06_alpha_fit.png"


def main():
    # ------------------------------------------------------------------
    # 1. Lecture des données brutes
    # ------------------------------------------------------------------
    df = pd.read_csv(DATA_IN)
    alpha = df["alpha"].values
    As = df["A_s"].values
    ns = df["n_s"].values

    # ------------------------------------------------------------------
    # 2. Lecture des coefficients depuis le JSON
    # ------------------------------------------------------------------
    spec = json.loads(Path(SPEC_JS).read_text(encoding="utf-8"))
    constantes = spec.get("constantes") or spec.get("constants") or {}

    # Paramètres de référence (avec valeurs de repli prudentes)
    A_s0 = float(constantes.get("A_s0", 2.1e-9))
    ns0 = float(constantes.get("ns0", 0.965))

    coeffs = spec.get("coefficients", {})
    c1 = float(coeffs.get("c1", 0.0))
    c1_2 = float(coeffs.get("c1_2", 0.0))
    c2 = float(coeffs.get("c2", 0.0))
    c2_2 = float(coeffs.get("c2_2", 0.0))

    # ------------------------------------------------------------------
    # 3. Calcul des courbes ajustées (ordre 2)
    # ------------------------------------------------------------------
    As_fit = A_s0 * (1.0 + c1 * alpha + c1_2 * alpha**2)
    ns_fit = ns0 + c2 * alpha + c2_2 * alpha**2

    # ------------------------------------------------------------------
    # 4. Tracé
    # ------------------------------------------------------------------
    FIG_DIR.mkdir(parents=True, exist_ok=True)
    fig, (ax1, ax2) = plt.subplots(
        nrows=2,
        ncols=1,
        figsize=(6.0, 6.0),
        dpi=300,
    )

    # 4.1 A_s(α)
    ax1.plot(alpha, As, marker="o", linestyle="None", label="Données")
    ax1.plot(alpha, As_fit, linestyle="-", linewidth=1.5, label="Fit ordre 2")
    ax1.set_ylabel(r"$A_s(\alpha)$")
    ax1.grid(True, which="both", ls=":")
    ax1.legend()

    # 4.2 n_s(α)
    ax2.plot(alpha, ns, marker="s", linestyle="None", label="Données")
    ax2.plot(alpha, ns_fit, linestyle="-", linewidth=1.5, label="Fit ordre 2")
    ax2.set_xlabel(r"$\alpha$")
    ax2.set_ylabel(r"$n_s(\alpha)$")
    ax2.grid(True, which="both", ls=":")
    ax2.legend()

    fig.suptitle(
        r"Ajustement polynomial de $A_s(\alpha)$ et $n_s(\alpha)$",
        y=0.98,
    )
    fig.subplots_adjust(
        left=0.10,
        right=0.97,
        bottom=0.08,
        top=0.94,
        hspace=0.30,
    )

    # ------------------------------------------------------------------
    # 5. Sauvegarde
    # ------------------------------------------------------------------
    fig.savefig(OUT_PLOT, dpi=300)
    plt.close(fig)
    print(f"Figure enregistrée → {OUT_PLOT}")


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
