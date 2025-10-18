#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Fig. 04 — Dérivée lissée ∂c_s²/∂k (chapitre 7)
"""

from __future__ import annotations

import argparse
import json
import logging
import os
import sys
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.ticker import FuncFormatter, LogLocator


ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = ROOT / "zz-data" / "chapter07"
FIG_DIR = ROOT / "zz-figures" / "chapter07"
META_JSON = DATA_DIR / "07_meta_perturbations.json"
CSV_DCS2 = DATA_DIR / "07_dcs2_dk.csv"


def pow_fmt(x, pos):
    if x <= 0 or not np.isfinite(x):
        return ""
    e = int(np.log10(x))
    return rf"$10^{{{e}}}$" if np.isclose(x, 10 ** e) else ""


def build_figure(k_vals: np.ndarray, dcs2: np.ndarray, k_split: float):
    fig, ax = plt.subplots(figsize=(8, 5))
    ax.loglog(k_vals, np.abs(dcs2), color="C1", lw=2, label=r"$|\partial_k\,c_s^2|$")
    ax.axvline(k_split, color="k", ls="--", lw=1)
    ax.text(k_split, 0.85, r"$k_{\rm split}$", transform=ax.get_xaxis_transform(),
            rotation=90, va="bottom", ha="right", fontsize=9)

    ax.set_xlabel(r"$k\,[h/\mathrm{Mpc}]$")
    ax.set_ylabel(r"$|\partial_k\,c_s^2|$")
    ax.set_title(r"Dérivée lissée $\partial_k\,c_s^2(k)$")
    ax.grid(which="major", ls=":", lw=0.6)
    ax.grid(which="minor", ls=":", lw=0.3, alpha=0.7)
    ax.xaxis.set_major_locator(LogLocator(base=10))
    ax.xaxis.set_minor_locator(LogLocator(base=10, subs=(2, 5)))
    ax.yaxis.set_major_locator(LogLocator(base=10))
    ax.yaxis.set_minor_locator(LogLocator(base=10, subs=(2, 5)))
    ax.xaxis.set_major_formatter(FuncFormatter(pow_fmt))
    ax.yaxis.set_major_formatter(FuncFormatter(pow_fmt))
    ax.set_ylim(1e-8, None)
    ax.legend(loc="upper right", frameon=False)
    fig.subplots_adjust(left=0.12, right=0.98, top=0.90, bottom=0.12)
    return fig, ax


def load_inputs() -> tuple[np.ndarray, np.ndarray, float]:
    if not META_JSON.exists():
        raise FileNotFoundError(f"Meta JSON introuvable: {META_JSON}")
    if not CSV_DCS2.exists():
        raise FileNotFoundError(f"CSV introuvable: {CSV_DCS2}")

    meta = json.loads(META_JSON.read_text(encoding="utf-8"))
    k_split = float(meta.get("x_split", 0.02))
    df = pd.read_csv(CSV_DCS2, comment="#")
    if "k" not in df.columns or df.shape[1] < 2:
        raise ValueError(f"CSV {CSV_DCS2} doit contenir une colonne 'k' et au moins une colonne de valeur")

    k_vals = pd.to_numeric(df["k"], errors="coerce").to_numpy()
    dcs2 = pd.to_numeric(df.iloc[:, 1], errors="coerce").to_numpy()
    return k_vals, dcs2, k_split


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Fig. 04 — dérivée lissée ∂c_s²/∂k (chapitre 7, MCGT).",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument("--outdir", default=os.environ.get("MCGT_OUTDIR", str(FIG_DIR)))
    parser.add_argument("--dpi", type=int, default=300)
    parser.add_argument("--format", "--fmt", dest="fmt", choices=["png", "pdf", "svg"], default="png")
    parser.add_argument("--transparent", action="store_true")
    parser.add_argument("-v", "--verbose", action="count", default=0, help="Verbosité cumulable")
    args = parser.parse_args(argv)

    # logging
    level = logging.WARNING
    if args.verbose >= 2:
        level = logging.DEBUG
    elif args.verbose == 1:
        level = logging.INFO
    logging.basicConfig(level=level, format="[%(levelname)s] %(message)s")

    k_vals, dcs2, k_split = load_inputs()
    fig, _ = build_figure(k_vals, dcs2, k_split)

    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)
    outpath = outdir / f"fig_04_dcs2_vs_k.{args.fmt}"

    fig.savefig(outpath, dpi=args.dpi, transparent=args.transparent)
    plt.close(fig)
    print(f"[INFO] Figure saved → {outpath}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
