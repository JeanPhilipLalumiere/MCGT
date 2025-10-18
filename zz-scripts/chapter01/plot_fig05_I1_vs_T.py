#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Fig. 05 — Invariant adimensionnel I1(T)
"""

from pathlib import Path
import argparse
import os

import matplotlib.pyplot as plt
import pandas as pd


ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "zz-data" / "chapter01" / "01_dimensionless_invariants.csv"


def main():
    parser = argparse.ArgumentParser(
        description="Fig. 05 — Invariant adimensionnel I1(T) (log–log)."
    )
    parser.add_argument("--outdir", default=os.environ.get("MCGT_OUTDIR", "zz-figures/_smoke/chapter01"))
    parser.add_argument("--dpi", type=int, default=300)
    parser.add_argument("--format", "--fmt", dest="fmt", choices=["png", "pdf", "svg"], default="png")
    parser.add_argument("--transparent", action="store_true")
    args = parser.parse_args()

    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)
    outpath = outdir / f"fig_05_I1_vs_T.{args.fmt}"

    # Charge données
    df = pd.read_csv(DATA)
    T = pd.to_numeric(df["T"], errors="coerce").to_numpy()
    I1 = pd.to_numeric(df["I1"], errors="coerce").to_numpy()

    # Figure
    fig, ax = plt.subplots(figsize=(8, 5), dpi=args.dpi)
    ax.plot(T, I1, label=r"$I_1 = P(T)/T$")
    ax.set_xscale("log")
    ax.set_yscale("log")
    ax.set_xlabel("T (Gyr)")
    ax.set_ylabel(r"$I_1$")
    ax.set_title(r"Fig. 05 — Invariant adimensionnel $I_1$ en fonction de $T$")
    ax.grid(True, which="both", ls=":", lw=0.6, alpha=0.7)
    ax.legend()
    fig.subplots_adjust(left=0.06, right=0.98, bottom=0.10, top=0.92)

    fig.savefig(outpath, transparent=args.transparent)
    print(f"[OK] Figure enregistrée → {outpath}")


if __name__ == "__main__":
    main()
