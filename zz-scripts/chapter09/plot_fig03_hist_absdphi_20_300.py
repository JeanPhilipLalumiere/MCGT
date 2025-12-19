#!/usr/bin/env python3
from __future__ import annotations

"""
Figure 03 — Histogram of |Δφ| on the 20–300 Hz window.
Restored and anglicized for Chapter 09 pipeline.
"""

import argparse
import logging
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.ticker import LogLocator, NullFormatter, NullLocator

plt.rcParams.update(
    {
        "figure.autolayout": True,
        "figure.figsize": (10, 6),
        "axes.titlepad": 25,
        "axes.labelpad": 15,
        "savefig.bbox": "tight",
        "savefig.pad_inches": 0.3,
        "font.family": "serif",
    }
)

DEF_DIFF = Path("zz-data/chapter09/09_phase_diff.csv")
DEF_CSV = Path("zz-data/chapter09/09_phases_mcgt.csv")
DEF_OUT = Path("zz-figures/chapter09/09_fig_03_hist_absdphi_20_300.png")


def setup_logger(level: str) -> logging.Logger:
    lvl = getattr(logging, level.upper(), logging.INFO)
    logging.basicConfig(
        level=lvl,
        format="[%(asctime)s] [%(levelname)s] %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )
    return logging.getLogger("fig03_hist")


def principal_diff(a: np.ndarray, b: np.ndarray) -> np.ndarray:
    """Principal difference (−π, π]."""
    two_pi = 2.0 * np.pi
    return (np.asarray(a, float) - np.asarray(b, float) + np.pi) % (two_pi) - np.pi


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Histogram of |Δφ| on 20–300 Hz window (publication-ready)"
    )
    p.add_argument("--diff", type=Path, default=DEF_DIFF, help="09_phase_diff.csv")
    p.add_argument("--csv", type=Path, default=DEF_CSV, help="09_phases_mcgt.csv")
    p.add_argument("--out", type=Path, default=DEF_OUT, help="Output PNG")
    p.add_argument("--window", nargs=2, type=float, default=[20.0, 300.0])
    p.add_argument("--bins", type=int, default=40)
    p.add_argument("--xscale", choices=["linear", "log"], default="log")
    p.add_argument("--dpi", type=int, default=300)
    p.add_argument(
        "--log-level", choices=["DEBUG", "INFO", "WARNING", "ERROR"], default="INFO"
    )
    return p.parse_args()


def load_absdphi(args: argparse.Namespace, log: logging.Logger) -> tuple[np.ndarray, np.ndarray]:
    """Returns f_Hz, abs_dphi arrays."""
    if args.diff.exists():
        df = pd.read_csv(args.diff)
        if {"f_Hz", "abs_dphi"}.issubset(df.columns):
            log.info("Loaded %s", args.diff)
            return df["f_Hz"].to_numpy(float), df["abs_dphi"].to_numpy(float)
        log.warning("%s missing required columns, falling back to CSV", args.diff)

    if not args.csv.exists():
        raise SystemExit(f"No valid input files found ({args.diff}, {args.csv}).")
    mc = pd.read_csv(args.csv)
    need = {"f_Hz", "phi_ref"}
    if not need.issubset(mc.columns):
        raise SystemExit(f"{args.csv} must contain {need}")

    variant = None
    for c in ("phi_mcgt", "phi_mcgt_cal", "phi_mcgt_raw"):
        if c in mc.columns:
            variant = c
            break
    if variant is None:
        raise SystemExit("No phi_mcgt* column found to build Δφ.")

    f = mc["f_Hz"].to_numpy(float)
    ref = mc["phi_ref"].to_numpy(float)
    mcg = mc[variant].to_numpy(float)
    m = np.isfinite(f) & np.isfinite(ref) & np.isfinite(mcg)
    f, ref, mcg = f[m], ref[m], mcg[m]
    if f.size == 0:
        raise SystemExit("No finite rows available to compute Δφ.")

    # Principal residual with k computed on window
    fmin, fmax = sorted(map(float, args.window))
    m_band = (f >= fmin) & (f <= fmax)
    two_pi = 2.0 * np.pi
    if np.any(m_band):
        k = int(np.round(np.nanmedian((mcg[m_band] - ref[m_band]) / two_pi)))
    else:
        k = 0
    dphi = principal_diff(mcg - k * two_pi, ref)
    absd = np.abs(dphi)
    log.info("Built principal residuals from %s (variant=%s, k=%d)", args.csv, variant, k)
    return f, absd


def main() -> None:
    args = parse_args()
    log = setup_logger(args.log_level)

    f, absd = load_absdphi(args, log)
    fmin, fmax = sorted(map(float, args.window))
    mask = (f >= fmin) & (f <= fmax) & np.isfinite(absd)
    vals = absd[mask]
    if vals.size == 0:
        raise SystemExit(f"No points within {fmin}-{fmax} Hz window.")

    mean_v = float(np.nanmean(vals))
    med_v = float(np.nanmedian(vals))
    p95_v = float(np.nanpercentile(vals, 95.0))
    max_v = float(np.nanmax(vals))

    args.out.parent.mkdir(parents=True, exist_ok=True)
    fig, ax = plt.subplots(dpi=args.dpi)

    if args.xscale == "log":
        pos = vals[vals > 0]
        vmin = float(pos.min()) if pos.size else 1e-6
        vmax = float(pos.max()) if pos.size else 1.0
        bins = np.logspace(np.log10(vmin / 2.0), np.log10(vmax * 2.0), args.bins + 1)
    else:
        bins = args.bins

    ax.hist(vals, bins=bins, density=True, histtype="stepfilled", alpha=0.75, color="C0")
    if args.xscale == "log":
        ax.set_xscale("log")
    ax.set_xlabel(r"$|\Delta \phi_{\rm principal}|$  [rad]")
    ax.set_ylabel("Density")
    ax.set_title("Model Selection: Bayesian Evidence Comparison")
    ax.grid(True, which="both", ls=":", alpha=0.4)

    if args.xscale == "log":
        ax.xaxis.set_minor_formatter(NullFormatter())
        ax.xaxis.set_minor_locator(NullLocator())

    for val, style, lbl in [
        (mean_v, "-", "Mean"),
        (med_v, "--", "Median"),
        (p95_v, ":", "p95"),
    ]:
        ax.axvline(val, ls=style, lw=1.4, color="C1", label=lbl)

    ax.legend(loc="upper right")
    stats_txt = (
        f"window: {fmin:.0f}-{fmax:.0f} Hz\n"
        f"mean = {mean_v:.3f}\n"
        f"median = {med_v:.3f}\n"
        f"p95 = {p95_v:.3f}\n"
        f"max = {max_v:.3f}\n"
        f"N = {vals.size}"
    )
    ax.text(
        0.98,
        0.05,
        stats_txt,
        transform=ax.transAxes,
        ha="right",
        va="bottom",
        fontsize=10.5,
        bbox=dict(boxstyle="round,pad=0.3", facecolor="white", alpha=0.85),
    )

    fig.savefig(args.out, dpi=args.dpi)
    log.info("PNG saved → %s", args.out)


if __name__ == "__main__":
    main()
