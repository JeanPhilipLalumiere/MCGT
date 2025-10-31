#!/usr/bin/env python3
"""
Figure 07 – Invariant scalaire I₂ = k·(δφ/φ)
Chapitre 7 – Perturbations scalaires (MCGT).
"""
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
                        fig.savefig(out, dpi=120)
                except Exception:
                    pass
        atexit.register(_auto_save)
    except Exception:
        pass
# === [/PASS5B-SHIM] ===

import json
import logging
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd


def main():
    # --- chemins ---
    ROOT = Path(__file__).resolve().parents[2]
    DATA_DIR = ROOT / "zz-data" / "chapter07"
    CSV_DATA = DATA_DIR / "07_scalar_perturbations_results.csv"
    JSON_META = DATA_DIR / "07_meta_perturbations.json"
    FIG_DIR = ROOT / "zz-figures" / "chapter07"
    FIG_OUT = FIG_DIR / "fig_07_invariant_I2.png"
    FIG_DIR.mkdir(parents=True, exist_ok=True)

    # --- logging ---
    logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")
    logging.info("→ génération de la figure 07 – Invariant I₂")

    # --- chargement des données ---
    df = pd.read_csv(CSV_DATA)
    if df.empty:
        raise RuntimeError(f"Aucune donnée dans {CSV_DATA}")
    if "delta_phi_interp" not in df.columns:
        raise KeyError("La colonne 'delta_phi_interp' est introuvable dans le CSV")

    k = df["k"].to_numpy()
    delta_phi = df["delta_phi_interp"].to_numpy()

    # --- calcul de I₂ ---
    I2 = k * delta_phi

    # --- lecture de k_split ---
    if JSON_META.exists():
        meta = json.loads(JSON_META.read_text("utf-8"))
        k_split = float(meta.get("x_split", 0.02))
    else:
        logging.warning("Méta-paramètres non trouvés → k_split=0.02")
        k_split = 0.02
    logging.info("k_split = %.2e h/Mpc", k_split)

    # --- préparation du tracé ---
    fig, ax = plt.subplots(figsize=(8, 5))
    ax.loglog(
        k, I2, color="C3", linewidth=2, label=r"$I_2(k)=k\,\frac{\delta\phi}{\phi}$"
    )

    # --- bornes Y centrées sur le plateau (k < k_split) ---
    mask_plateau = k < k_split
    if not np.any(mask_plateau):
        raise RuntimeError(
            "Aucune valeur de k < k_split pour définir le plateau.")
    bottom = I2[mask_plateau].min() * 0.5
    top = I2[mask_plateau].max() * 1.2
    ax.set_ylim(bottom, top)

    # --- ligne verticale k_split ---
    ax.axvline(k_split, color="k", ls="--", lw=1)
    ax.text(
        k_split,
        bottom * 1.2,
        r"$k_{\rm split}$",
        ha="center",
        va="bottom",
        fontsize=10,
        backgroundcolor="white",
    )

    # --- annotation Plateau ---
    x_plt = k[mask_plateau][len(k[mask_plateau]) // 2]
    y_plt = I2[mask_plateau].mean()
    ax.text(
        x_plt,
        y_plt,
        "Plateau",
        fontsize=9,
        bbox=dict(boxstyle="round,pad=0.3", fc="white", ec="gray", alpha=0.7),
    )

    # --- axes, titre, labels ---
    ax.set_xlabel(r"$k\;[h/\mathrm{Mpc}]$", fontsize=12)
    ax.set_ylabel(r"$I_2(k)$", fontsize=12)
    ax.set_title("Invariant scalaire $I_2(k)$", fontsize=14)

    # --- ticks Y explicites ---
    dmin = int(np.floor(np.log10(bottom)))
    dmax = int(np.ceil(np.log10(top)))
    decades = np.arange(dmin, dmax + 1)
    y_ticks = 10.0**decades
    ax.set_yticks(y_ticks)
    ax.set_yticklabels([f"$10^{{{d}}}$" for d in decades])

    # --- grille et légende ---
    ax.grid(which="both", ls=":", lw=0.5, color="gray", alpha=0.7)
    ax.legend(loc="upper right", frameon=True)

    # --- sauvegarde ---
    fig.subplots_adjust(left=0.04, right=0.98, bottom=0.06, top=0.96)
    fig.savefig(FIG_OUT, dpi=300)
    logging.info("Figure enregistrée → %s", FIG_OUT)


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



# === MCGT:CLI-SHIM-BEGIN ===
# Idempotent. Expose: --out/--dpi/--format/--transparent/--style/--verbose
# Ne modifie pas la logique existante : parse_known_args() au module-scope.

def _mcgt_cli_shim_parse_known():
    import argparse, sys
    p = argparse.ArgumentParser(add_help=False)
    p.add_argument("--out", type=str, default=None, help="Chemin de sortie (optionnel).")
    p.add_argument("--dpi", type=int, default=None, help="DPI de sortie (optionnel).")
    p.add_argument("--format", type=str, default=None, choices=["png","pdf","svg"], help="Format de sortie.")
    p.add_argument("--transparent", action="store_true", help="Fond transparent si supporté.")
    p.add_argument("--style", type=str, default=None, help="Style matplotlib (optionnel).")
    p.add_argument("--verbose", action="store_true", help="Verbosité accrue.")
    args, _ = p.parse_known_args(sys.argv[1:])
    try:
        import matplotlib as _mpl
        if args.style:
            import matplotlib.pyplot as _plt  # force init si besoin
            _mpl.style.use(args.style)
        if args.dpi and hasattr(_mpl, "rcParams"):
            _mpl.rcParams["figure.dpi"] = int(args.dpi)
    except Exception:
        # Ne jamais casser le producteur si style/DPI échoue.
        pass
    return args

try:
    MCGT_CLI = _mcgt_cli_shim_parse_known()
except Exception:
    MCGT_CLI = None
# === MCGT:CLI-SHIM-END ===

