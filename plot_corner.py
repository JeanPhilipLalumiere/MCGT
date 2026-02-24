#!/usr/bin/env python3
"""Plot publication-quality corner plot from emcee HDF5 chains."""

from __future__ import annotations

import argparse
from pathlib import Path

import corner
import emcee
import matplotlib.pyplot as plt
import numpy as np


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Generate MCGT corner plot from HDF5 chains.")
    parser.add_argument(
        "--input",
        type=Path,
        default=Path("output/mcgt_chains.h5"),
        help="Input emcee HDF5 backend file.",
    )
    parser.add_argument(
        "--chain-name",
        type=str,
        default="mcgt_chain",
        help="Chain name in HDF5 backend.",
    )
    parser.add_argument(
        "--burnin-frac",
        type=float,
        default=0.30,
        help="Fallback burn-in fraction if autocorrelation estimate is unavailable.",
    )
    parser.add_argument(
        "--out-pdf",
        type=Path,
        default=Path("output/mcgt_corner_plot.pdf"),
        help="Output PDF path.",
    )
    parser.add_argument(
        "--out-png",
        type=Path,
        default=Path("output/mcgt_corner_plot.png"),
        help="Output PNG path.",
    )
    return parser


def estimate_burnin(reader: emcee.backends.HDFBackend, burnin_frac: float) -> int:
    chain = reader.get_chain()
    n_steps = chain.shape[0]
    burnin_fallback = max(1, int(burnin_frac * n_steps))

    try:
        tau = reader.get_autocorr_time(tol=0)
        burnin_tau = int(2.0 * np.max(tau))
        burnin = min(max(burnin_tau, burnin_fallback), n_steps - 1)
        print(f"[info] burn-in from autocorr time: {burnin} steps (tau_max={np.max(tau):.2f})")
        return burnin
    except Exception:
        print(f"[info] burn-in fallback ({burnin_frac:.0%}): {burnin_fallback} steps")
        return burnin_fallback


def main() -> None:
    args = build_parser().parse_args()

    reader = emcee.backends.HDFBackend(str(args.input), name=args.chain_name)
    burnin = estimate_burnin(reader, args.burnin_frac)
    samples = reader.get_chain(discard=burnin, flat=True)

    labels = [r"$\Omega_m$", r"$H_0$", r"$w_0$", r"$w_a$", r"$S_8$"]

    plt.rcParams.update(
        {
            "font.size": 11,
            "axes.labelsize": 12,
            "axes.titlesize": 10,
            "xtick.labelsize": 10,
            "ytick.labelsize": 10,
            "figure.dpi": 120,
        }
    )

    fig = corner.corner(
        samples,
        labels=labels,
        quantiles=[0.16, 0.5, 0.84],
        show_titles=True,
        title_fmt=".4f",
        levels=(1 - np.exp(-0.5), 1 - np.exp(-2)),
        color="#003366",
        smooth=1.0,
        fill_contours=False,
        plot_datapoints=False,
        max_n_ticks=4,
    )

    args.out_pdf.parent.mkdir(parents=True, exist_ok=True)
    args.out_png.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(args.out_pdf, bbox_inches="tight")
    fig.savefig(args.out_png, dpi=300, bbox_inches="tight")
    print(f"[ok] Saved: {args.out_pdf}")
    print(f"[ok] Saved: {args.out_png}")


if __name__ == "__main__":
    main()
