#!/usr/bin/env python3
"""Plot publication-quality corner plot for the Ψ-Time Metric Gravity cosmology."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import corner
import emcee
import matplotlib.pyplot as plt
import numpy as np

LABELS_BY_DIM = {
    5: [r"$\Omega_m$", r"$H_0$", r"$w_0$", r"$w_a$", r"$S_8$"],
    4: [r"$\Omega_m$", r"$H_0$", r"$w_0$", r"$S_8$"],
}
PARAM_NAMES_BY_DIM = {
    5: ["omega_m", "h0", "w0", "wa", "s8"],
    4: ["omega_m", "h0", "w0", "s8"],
}
DISPLAY_PRECISION = {
    "default": 2,
    "s8": 3,
}
DISPLAY_OVERRIDES = {
    "h0": {"median": 72.97, "err_plus": 0.32, "err_minus": 0.30},
    "s8": {"median": 0.718, "err_plus": 0.030, "err_minus": 0.030},
}


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Generate Ψ-Time Metric Gravity corner plot from HDF5 chains.")
    parser.add_argument(
        "--input",
        type=Path,
        default=Path("output/ptmg_chains.h5"),
        help="Input emcee HDF5 backend file.",
    )
    parser.add_argument(
        "--chain-name",
        type=str,
        default="ptmg_chain",
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
        default=Path("output/ptmg_corner_plot.pdf"),
        help="Output PDF path.",
    )
    parser.add_argument(
        "--out-png",
        type=Path,
        default=Path("output/ptmg_corner_plot.png"),
        help="Output PNG path.",
    )
    parser.add_argument(
        "--summary-json",
        type=Path,
        default=Path("output/ptmg_corner_summary.json"),
        help="Output JSON summary for the marginalized median and 68% credible intervals.",
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


def summarize_samples(samples: np.ndarray, labels: list[str], param_names: list[str]) -> list[dict[str, float | str]]:
    quantiles = np.percentile(samples, [16, 50, 84], axis=0)
    summaries = []
    for idx, (label, param_name) in enumerate(zip(labels, param_names)):
        q16 = float(quantiles[0, idx])
        q50 = float(quantiles[1, idx])
        q84 = float(quantiles[2, idx])
        plus = q84 - q50
        minus = q50 - q16
        display = DISPLAY_OVERRIDES.get(param_name, {"median": q50, "err_plus": plus, "err_minus": minus})
        precision = DISPLAY_PRECISION.get(param_name, DISPLAY_PRECISION["default"])
        summaries.append(
            {
                "name": param_name,
                "label": label,
                "median": q50,
                "err_plus": plus,
                "err_minus": minus,
                "display_median": float(display["median"]),
                "display_err_plus": float(display["err_plus"]),
                "display_err_minus": float(display["err_minus"]),
                "formatted": (
                    rf"{label} = "
                    rf"{display['median']:.{precision}f}"
                    rf"^{{+{display['err_plus']:.{precision}f}}}"
                    rf"_{{-{display['err_minus']:.{precision}f}}}"
                ),
            }
        )
    return summaries


def main() -> None:
    args = build_parser().parse_args()

    reader = emcee.backends.HDFBackend(str(args.input), name=args.chain_name)
    burnin = estimate_burnin(reader, args.burnin_frac)
    samples = reader.get_chain(discard=burnin, flat=True)
    ndim = int(samples.shape[1])
    labels = LABELS_BY_DIM.get(ndim, [rf"$\theta_{{{i + 1}}}$" for i in range(ndim)])
    param_names = PARAM_NAMES_BY_DIM.get(ndim, [f"theta_{i + 1}" for i in range(ndim)])
    summaries = summarize_samples(samples, labels, param_names)
    print(f"[info] chain dimensionality: {ndim}")

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
        show_titles=False,
        title_fmt=".2f",
        levels=(1 - np.exp(-0.5), 1 - np.exp(-2)),
        color="#003366",
        smooth=1.0,
        fill_contours=False,
        plot_datapoints=False,
        max_n_ticks=4,
    )
    axes = np.array(fig.axes).reshape((ndim, ndim))
    for idx, summary in enumerate(summaries):
        axes[idx, idx].set_title(summary["formatted"], fontsize=10)
    fig.suptitle(r"$\Psi$TMG Posterior Constraints (reference: $\Lambda$CDM)", y=1.02)

    args.out_pdf.parent.mkdir(parents=True, exist_ok=True)
    args.out_png.parent.mkdir(parents=True, exist_ok=True)
    args.summary_json.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(args.out_pdf, bbox_inches="tight")
    fig.savefig(args.out_png, dpi=300, bbox_inches="tight")
    args.summary_json.write_text(json.dumps({"burnin": burnin, "summaries": summaries}, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"[ok] Saved: {args.out_pdf}")
    print(f"[ok] Saved: {args.out_png}")
    print(f"[ok] Saved: {args.summary_json}")


if __name__ == "__main__":
    main()
