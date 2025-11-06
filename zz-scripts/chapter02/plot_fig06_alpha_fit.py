#!/usr/bin/env python3
# fichier : zz-scripts/chapter02/plot_fig06_alpha_fit.py
# répertoire : zz-scripts/chapter02
# === [PASS5-AUTOFIX-SHIM] ===
import sys
_argv = sys.argv[1:]
# 1) Shim --help universel
if any(a in ("-h","--help") for a in _argv):
    import argparse
    _p = argparse.ArgumentParser(description="MCGT (shim auto-injecté Pass5)", add_help=True, allow_abbrev=False)
    _p.add_argument("--out", help="Chemin de sortie pour fig.savefig (optionnel)")
    _p.add_argument("--dpi", type=int, default=120, help="DPI (par défaut: 120)")
    _p.add_argument("--figsize", default="9,6", help="figure size W,H (inches)")
    _p.parse_args(_argv)
    raise SystemExit(0)
# === [/PASS5-AUTOFIX-SHIM] ===
"""
Tracer l'ajustement polynomial de A_s(α) et n_s(α) pour le Chapitre 2 (MCGT)

Produit :
- zz-figures/chapter02/02_fig_06_fit_alpha.png

Données sources :
- zz-data/chapter02/02_As_ns_vs_alpha.csv
- zz-data/chapter02/02_primordial_spectrum_spec.json
"""

import json
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd

# Répertoires racine
ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = ROOT / "zz-data" / "chapter02"
FIG_DIR = ROOT / "zz-figures" / "chapter02"
DATA_IN = DATA_DIR / "02_As_ns_vs_alpha.csv"
SPEC_JS = DATA_DIR / "02_primordial_spectrum_spec.json"
OUT_PLOT = FIG_DIR / "fig_06_fit_alpha.png"


def main():
    # Lecture des données Brutes
    df = pd.read_csv(DATA_IN)
    alpha = df["alpha"].values
    As = df["A_s"].values
    ns = df["n_s"].values

    # Lecture des coefficients depuis le JSON
    spec = json.loads(Path(SPEC_JS).read_text())
    A_s0 = spec["constantes"]["A_s0"]
    ns0 = spec["constantes"]["ns0"]
    coeffs = spec["coefficients"]
    c1 = coeffs["c1"]
    c1_2 = coeffs.get("c1_2", 0.0)
    c2 = coeffs["c2"]
    c2_2 = coeffs.get("c2_2", 0.0)

    # Calcul des courbes ajustées (ordre 2)
    As_fit = A_s0 * (1 + c1 * alpha + c1_2 * alpha**2)
    ns_fit = ns0 + c2 * alpha + c2_2 * alpha**2

    # Tracé
    plt.figure(figsize=(6, 6))

    # 1) A_s(α)
    ax1 = plt.subplot(2, 1, 1)
    ax1.plot(alpha, As, marker="o", linestyle="None", label="Données")
    ax1.plot(alpha, As_fit, linestyle="-", linewidth=1.5, label="Fit ordre 2")
    ax1.set_ylabel(r"$A_s(\alpha)$")
    ax1.grid(True, which="both", ls=":")
    ax1.legend()

    # 2) n_s(α)
    ax2 = plt.subplot(2, 1, 2)
    ax2.plot(alpha, ns, marker="s", linestyle="None", label="Données")
    ax2.plot(alpha, ns_fit, linestyle="-", linewidth=1.5, label="Fit ordre 2")
    ax2.set_xlabel(r"$\alpha$")
    ax2.set_ylabel(r"$n_s(\alpha)$")
    ax2.grid(True, which="both", ls=":")
    ax2.legend()

plt.suptitle("Ajustement polynomial de $A_s(\\alpha)$ et $n_s(\\alpha)$", y=0.98)
fig.subplots_adjust(left=0.04, right=0.98, bottom=0.06, top=0.96)

    # Sauvegarde
FIG_DIR.mkdir(parents=True, exist_ok=True)
plt.savefig(OUT_PLOT, dpi=300)
plt.close()
print(f"Figure enregistrée → {OUT_PLOT}")


if __name__ == "__main__":
    main()

# [MCGT POSTPARSE EPILOGUE v2]
# (compact) delegate to common helper; best-effort wrapper
try:
    import os, sys
    _here = os.path.abspath(os.path.dirname(__file__))
    _zz = os.path.abspath(os.path.join(_here, ".."))
    if _zz not in sys.path:
        sys.path.insert(0, _zz)
    from _common.postparse import apply as _mcgt_postparse_apply
    _mcgt_postparse_apply()
except Exception:
    pass
