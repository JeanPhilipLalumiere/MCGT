#!/usr/bin/env python3
"""Generate an overlaid corner plot comparing ΨTMG v3.2.0 and TIDE v3.2.1."""

from __future__ import annotations

import argparse
from pathlib import Path

import corner
import emcee
import matplotlib.lines as mlines
import matplotlib.pyplot as plt
import numpy as np

BASELINE_INPUT = Path("output/ptmg_chains.h5")
BASELINE_CHAIN_NAME = "ptmg_chain"
TIDE_INPUT = Path("results/v3.2.1_TIDE/tide_production_chains.h5")
TIDE_CHAIN_NAMES = ("tide_chain", "ptmg_chain")
OUTPUT_PATH = Path("results/v3.2.1_TIDE/corner_competition_v320_vs_v321.png")

COMMON_LABELS = [r"$\Omega_m$", r"$H_0$", r"$S_8$"]
BASELINE_COMMON_COLS = (0, 1, 4)
TIDE_COMMON_COLS = (0, 1, 3)
CONFIDENCE_LEVELS = (1 - np.exp(-0.5), 1 - np.exp(-2.0))

BLUE = "#0B5FA5"
RED = "#C0392B"
TRUTH = "#E67E22"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Overlay ΨTMG and TIDE posterior contours.")
    parser.add_argument("--baseline-input", type=Path, default=BASELINE_INPUT)
    parser.add_argument("--baseline-chain-name", type=str, default=BASELINE_CHAIN_NAME)
    parser.add_argument("--tide-input", type=Path, default=TIDE_INPUT)
    parser.add_argument("--tide-chain-name", type=str, default=TIDE_CHAIN_NAMES[0])
    parser.add_argument("--tide-burnin", type=int, default=1500)
    parser.add_argument("--output", type=Path, default=OUTPUT_PATH)
    return parser


def open_backend(path: Path, preferred_name: str, fallback_names: tuple[str, ...]) -> tuple[emcee.backends.HDFBackend, str]:
    candidate_names = (preferred_name, *fallback_names)
    last_error: Exception | None = None
    for name in dict.fromkeys(candidate_names):
        try:
            backend = emcee.backends.HDFBackend(str(path), name=name, read_only=True)
            backend.get_chain()  # force validation of group existence
            return backend, name
        except Exception as exc:  # pragma: no cover - defensive for HDF backend variants
            last_error = exc
    raise RuntimeError(f"Unable to open chain in {path} using names {candidate_names}") from last_error


def summarize(samples: np.ndarray) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    q16, q50, q84 = np.percentile(samples, [16, 50, 84], axis=0)
    return q16, q50, q84


def format_h0_s8_legend(title: str, color: str, medians: np.ndarray, q16: np.ndarray, q84: np.ndarray) -> mlines.Line2D:
    h0_minus = medians[1] - q16[1]
    h0_plus = q84[1] - medians[1]
    s8_minus = medians[2] - q16[2]
    s8_plus = q84[2] - medians[2]
    label = (
        f"{title}: "
        f"H0 = {medians[1]:.2f} (-{h0_minus:.2f}/+{h0_plus:.2f}), "
        f"S8 = {medians[2]:.3f} (-{s8_minus:.3f}/+{s8_plus:.3f})"
    )
    return mlines.Line2D([], [], color=color, lw=2.4, label=label)


def main() -> None:
    args = build_parser().parse_args()

    plt.rcParams.update(
        {
            "text.usetex": False,
            "font.family": "DejaVu Serif",
            "font.size": 12,
            "axes.labelsize": 13,
            "axes.titlesize": 12,
            "xtick.labelsize": 10,
            "ytick.labelsize": 10,
            "pdf.fonttype": 42,
            "ps.fonttype": 42,
        }
    )

    baseline_backend, baseline_name = open_backend(
        args.baseline_input,
        args.baseline_chain_name,
        fallback_names=(),
    )
    tide_backend, tide_name = open_backend(
        args.tide_input,
        args.tide_chain_name,
        fallback_names=TIDE_CHAIN_NAMES[1:],
    )

    baseline_samples = baseline_backend.get_chain(flat=True)[:, BASELINE_COMMON_COLS]
    tide_samples = tide_backend.get_chain(discard=args.tide_burnin, flat=True)[:, TIDE_COMMON_COLS]

    baseline_q16, baseline_q50, baseline_q84 = summarize(baseline_samples)
    tide_q16, tide_q50, tide_q84 = summarize(tide_samples)

    mins = np.minimum(np.min(baseline_samples, axis=0), np.min(tide_samples, axis=0))
    maxs = np.maximum(np.max(baseline_samples, axis=0), np.max(tide_samples, axis=0))
    spans = maxs - mins
    ranges = [(lo - 0.08 * span, hi + 0.08 * span) for lo, hi, span in zip(mins, maxs, spans)]

    fig = corner.corner(
        baseline_samples,
        labels=COMMON_LABELS,
        range=ranges,
        levels=CONFIDENCE_LEVELS,
        smooth=1.0,
        fill_contours=True,
        plot_datapoints=False,
        no_fill_contours=False,
        color=BLUE,
        contourf_kwargs={"colors": [BLUE], "alpha": 0.18},
        contour_kwargs={"colors": [BLUE], "linewidths": 1.8},
        hist_kwargs={"density": True, "color": BLUE, "alpha": 0.35, "linewidth": 1.6},
        max_n_ticks=4,
    )
    corner.corner(
        tide_samples,
        fig=fig,
        labels=COMMON_LABELS,
        range=ranges,
        levels=CONFIDENCE_LEVELS,
        smooth=1.0,
        fill_contours=False,
        plot_datapoints=False,
        color=RED,
        contour_kwargs={"colors": [RED], "linewidths": 2.2},
        hist_kwargs={"density": True, "histtype": "step", "color": RED, "linewidth": 2.0},
        max_n_ticks=4,
    )

    ndim = len(COMMON_LABELS)
    axes = np.array(fig.axes).reshape((ndim, ndim))

    for row in range(ndim):
        for col in range(ndim):
            ax = axes[row, col]
            if row < col:
                continue
            if col == 1:
                ax.axvline(73.0, color=TRUTH, linestyle="--", linewidth=1.4, alpha=0.95)
            if row == 2:
                ax.axhline(0.83, color=TRUTH, linestyle=":", linewidth=1.4, alpha=0.95)
            if row == col == 2:
                ax.axvline(0.83, color=TRUTH, linestyle=":", linewidth=1.4, alpha=0.95)

    axes[2, 1].scatter([73.0], [0.83], marker="x", s=80, linewidths=2.0, color=TRUTH, zorder=5)

    baseline_handle = format_h0_s8_legend(r"$\Psi$TMG v3.2.0", BLUE, baseline_q50, baseline_q16, baseline_q84)
    tide_handle = format_h0_s8_legend("TIDE v3.2.1", RED, tide_q50, tide_q16, tide_q84)
    truth_handle = mlines.Line2D(
        [],
        [],
        color=TRUTH,
        linestyle="--",
        lw=1.6,
        label=r"Repères: $H_0=73.0$ (SH0ES), $S_8=0.83$ (Planck $\Lambda$CDM)",
    )

    fig.legend(
        handles=[baseline_handle, tide_handle, truth_handle],
        loc="upper center",
        bbox_to_anchor=(0.5, 1.02),
        ncol=1,
        frameon=False,
        fontsize=10,
    )
    fig.suptitle(r"Duel Cosmologique: $\Psi$TMG v3.2.0 vs TIDE v3.2.1", y=1.08, fontsize=16)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(args.output, dpi=300, bbox_inches="tight")

    print(f"[ok] Baseline chain group: {baseline_name}")
    print(f"[ok] TIDE chain group: {tide_name}")
    print(f"[ok] Saved: {args.output}")
    print(
        "[summary] "
        f"PsiTMG H0={baseline_q50[1]:.2f}, S8={baseline_q50[2]:.3f} | "
        f"TIDE H0={tide_q50[1]:.2f}, S8={tide_q50[2]:.3f}"
    )


if __name__ == "__main__":
    main()
