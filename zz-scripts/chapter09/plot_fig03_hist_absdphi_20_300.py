#!/usr/bin/env python3
# ch09 fig03 — producteur propre (prefer --diff, fallback --csv), fenêtre 20–300 Hz, X log.

from __future__ import annotations
import argparse, warnings
from pathlib import Path
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
p.add_argument('--out', type=str, default=None, help='Chemin de sortie (optionnel).')
p.add_argument('--dpi', type=float, default=150.0, help='DPI figure.')
p.add_argument('--format', default='png', choices=['png','pdf','svg'], help='Format de sortie.')
p.add_argument('--transparent', action='store_true', help='Fond transparent.')
p.add_argument('--style', default=None, help='Style Matplotlib (ex.: seaborn-v0_8).')
p.add_argument('--verbose', action='store_true', help='Verbosity (INFO).')

        description="Histogramme |Δφ| — bande 20–300 Hz (prefer --diff, fallback --csv)."
    )
    p.add_argument("--diff", type=Path, default=None,
                   help="CSV avec colonnes {f_Hz, abs_dphi}")
    p.add_argument("--csv", type=Path, default=None,
                   help="CSV avec colonnes {f_Hz, phi_ref, phi_mcgt} (fallback)")
    p.add_argument("--out", type=Path, default=Path("zz-figures/chapter09/09_fig_03_hist_absdphi_20_300.png"))
    p.add_argument("--dpi", type=int, default=150)
    p.add_argument("--bins", type=int, default=80)
    p.add_argument("--window", type=float, nargs=2, default=(20.0, 300.0), metavar=("FMIN","FMAX"))
    return p.parse_args()

def load_data(args: argparse.Namespace) -> tuple[np.ndarray, np.ndarray]:
    # Try --diff first
    if args.diff and args.diff.exists():
        df = pd.read_csv(args.diff)
        need = {"f_Hz", "abs_dphi"}
        if not need.issubset(df.columns):
            warnings.warn(f"--diff présent mais colonnes manquantes: {need - set(df.columns)} → fallback --csv")
        else:
            f = df["f_Hz"].astype(float).to_numpy()
            abs_dphi = df["abs_dphi"].astype(float).to_numpy()
            return f, abs_dphi
    # Fallback --csv
    if not (args.csv and args.csv.exists()):
        raise SystemExit("Aucun input valide: fournir --diff (f_Hz,abs_dphi) ou --csv (f_Hz,phi_ref,phi_mcgt).")
    mc = pd.read_csv(args.csv)
    need = {"f_Hz", "phi_ref", "phi_mcgt"}
    if not need.issubset(mc.columns):
        raise SystemExit(f"--csv incomplet: colonnes manquantes: {need - set(mc.columns)}")
    f = mc["f_Hz"].astype(float).to_numpy()
    abs_dphi = np.abs(mc["phi_mcgt"].astype(float).to_numpy() - mc["phi_ref"].astype(float).to_numpy())
    return f, abs_dphi

def main() -> None:
    args = parse_args()
    f, abs_dphi = load_data(args)

    # Fenêtre & filtrage
    fmin, fmax = sorted(map(float, args.window))
    sel = np.isfinite(abs_dphi) & np.isfinite(f) & (f >= fmin) & (f <= fmax)
    if not np.any(sel):
        raise SystemExit(f"Aucun point dans la fenêtre {fmin}-{fmax} Hz.")
    x = abs_dphi[sel]

    # Plot
    fig = plt.figure()
    plt.hist(x, bins=int(args.bins))
    plt.xscale("log")
    plt.xlabel("|Δφ| (rad)")
    plt.ylabel("Counts")
    plt.title("Histogramme |Δφ| — bande 20–300 Hz")

    # Écriture
    args.out.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(args.out, dpi=int(args.dpi), bbox_inches="tight")
    print(f"Wrote: {args.out}")

if __name__ == "__main__":
    main()
