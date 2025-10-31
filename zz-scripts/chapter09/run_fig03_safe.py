#!/usr/bin/env python3
import argparse
from pathlib import Path
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

def parse_args():
    p = argparse.ArgumentParser(
        description="Runner sûr ch09/fig03 — histogramme |Δφ| (20–300 Hz), x-log"
    )
    p.add_argument("--diff", type=Path, default=None,
                   help="CSV avec colonnes {f_Hz, abs_dphi}")
    p.add_argument("--csv", type=Path, default=None,
                   help="CSV fallback avec colonnes {f_Hz, phi_ref, phi_mcgt}")
    p.add_argument("--out", type=Path,
                   default=Path("zz-figures/chapter09/09_fig_03_hist_absdphi_20_300.png"))
    p.add_argument("--dpi", type=int, default=150)
    p.add_argument("--bins", type=int, default=80)
    p.add_argument("--fmin", type=float, default=20.0)
    p.add_argument("--fmax", type=float, default=300.0)
    return p.parse_args()

def main():
    a = parse_args()
    if not a.diff and not a.csv:
        raise SystemExit("Aucun input: fournir --diff ou --csv")

    f = None
    abs_dphi = None
    if a.diff and a.diff.exists():
        df = pd.read_csv(a.diff)
        need = {"f_Hz","abs_dphi"}
        if need.issubset(df.columns):
            f = df["f_Hz"].astype(float).to_numpy()
            abs_dphi = df["abs_dphi"].astype(float).to_numpy()
        else:
            print(f"[WARN] {a.diff} sans colonnes {need} → fallback --csv")
    if abs_dphi is None:
        if not (a.csv and a.csv.exists()):
            raise SystemExit("Fallback --csv manquant ou introuvable")
        mc = pd.read_csv(a.csv)
        need = {"f_Hz","phi_ref","phi_mcgt"}
        if not need.issubset(mc.columns):
            missing = need - set(mc.columns)
            raise SystemExit(f"Colonnes manquantes dans --csv: {missing}")
        f = mc["f_Hz"].astype(float).to_numpy()
        abs_dphi = (mc["phi_mcgt"].astype(float) - mc["phi_ref"].astype(float)).abs().to_numpy()

    fmin, fmax = sorted((a.fmin, a.fmax))
    sel = (f >= fmin) & (f <= fmax) & np.isfinite(abs_dphi)
    if not np.any(sel):
        raise SystemExit(f"Aucun point dans la fenêtre {fmin}-{fmax} Hz")

    vals = abs_dphi[sel]
    a.out.parent.mkdir(parents=True, exist_ok=True)
    fig = plt.figure()
    plt.hist(vals, bins=a.bins)
    plt.xscale("log")
    plt.xlabel("|Δφ| (rad)")
    plt.ylabel("Counts")
    plt.title(f"Histogramme |Δφ| — bande {fmin:.0f}–{fmax:.0f} Hz")
    fig.savefig(a.out, dpi=a.dpi, bbox_inches="tight")
    print(f"Wrote: {a.out}")

if __name__ == "__main__":
    main()
