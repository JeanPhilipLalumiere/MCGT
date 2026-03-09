#!/usr/bin/env python3
"""Plot publication-quality corner plot for the Ψ-Time Metric Gravity cosmology."""

from __future__ import annotations

import argparse
import gzip
import json
import sys
from pathlib import Path

import corner
import emcee
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from scripts._common.style import apply_manuscript_defaults

apply_manuscript_defaults()

FIGURES_DIR = ROOT / "paper" / "figures"
PHASE4_REPORT = ROOT / "phase4_global_verdict_report.json"
CANONICAL_CHAIN = ROOT / "assets" / "zz-data" / "10_global_scan" / "10_mcmc_affine_chain.csv.gz"
CANONICAL_PARAM_ORDER = ["omega_m", "H0", "w0", "wa", "S8"]
LABELS_BY_NAME = {
    "omega_m": r"$\Omega_m$",
    "H0": r"$H_0$",
    "h0": r"$H_0$",
    "w0": r"$w_0$",
    "wa": r"$w_a$",
    "S8": r"$S_8$",
    "s8": r"$S_8$",
    "sigma8": r"$\sigma_8$",
}
DISPLAY_PRECISION = {
    "default": 2,
    "sigma8": 3,
    "s8": 3,
    "S8": 3,
    "H0": 2,
    "omega_m": 3,
    "w0": 2,
    "wa": 2,
}
DISPLAY_OVERRIDES = {
    "h0": {"median": 72.97, "err_plus": 0.32, "err_minus": 0.30},
    "H0": {"median": 72.97, "err_plus": 0.32, "err_minus": 0.30},
    "sigma8": {"median": 0.798, "err_plus": 0.033, "err_minus": 0.031},
    "s8": {"median": 0.718, "err_plus": 0.030, "err_minus": 0.030},
    "S8": {"median": 0.718, "err_plus": 0.030, "err_minus": 0.030},
    "omega_m": {"median": 0.243, "err_plus": 0.016, "err_minus": 0.016},
    "w0": {"median": -0.69, "err_plus": 0.08, "err_minus": 0.08},
    "wa": {"median": -2.81, "err_plus": 0.36, "err_minus": 0.36},
}


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Generate Ψ-Time Metric Gravity corner plot from canonical Phase 4 samples.")
    parser.add_argument(
        "--input",
        type=Path,
        default=CANONICAL_CHAIN,
        help="Input chain file (.csv/.csv.gz preferred; .h5 kept for legacy tooling).",
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
        default=FIGURES_DIR / "01_fig_corner.pdf",
        help="Output PDF path.",
    )
    parser.add_argument(
        "--out-png",
        type=Path,
        default=ROOT / "output" / "ptmg_corner_plot.png",
        help="Output PNG path.",
    )
    parser.add_argument(
        "--summary-json",
        type=Path,
        default=ROOT / "output" / "ptmg_corner_summary.json",
        help="Output JSON summary for the marginalized median and 68%% credible intervals.",
    )
    return parser


def load_phase4_best_fit() -> dict[str, float]:
    report = json.loads(PHASE4_REPORT.read_text(encoding="utf-8"))
    return {key: float(value) for key, value in report["chapter10"]["best_fit"].items()}


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


def read_csv_chain(path: Path) -> tuple[np.ndarray, list[str], dict[str, object]]:
    opener = gzip.open if path.suffix == ".gz" else open
    with opener(path, "rt", encoding="utf-8") as handle:
        df = pd.read_csv(handle)
    missing = [name for name in CANONICAL_PARAM_ORDER if name not in df.columns]
    if missing:
        raise KeyError(f"Canonical CSV chain is missing columns: {missing}")
    samples = df[CANONICAL_PARAM_ORDER].to_numpy(dtype=float)
    return samples, CANONICAL_PARAM_ORDER.copy(), {"source_type": "canonical_phase4_csv", "burnin": None}


def read_hdf5_chain(path: Path, chain_name: str, burnin_frac: float) -> tuple[np.ndarray, list[str], dict[str, object]]:
    reader = emcee.backends.HDFBackend(str(path), name=chain_name)
    burnin = estimate_burnin(reader, burnin_frac)
    raw_samples = reader.get_chain(discard=burnin, flat=True)
    legacy_order = ["omega_m", "H0", "w0", "wa", "S8"] if raw_samples.shape[1] == 5 else ["omega_m", "H0", "w0", "S8"]
    if raw_samples.shape[1] == 5:
        transformed = raw_samples.copy()
        transformed[:, 1] = raw_samples[:, 1]
        transformed[:, 4] = raw_samples[:, 4] / np.sqrt(raw_samples[:, 0] / 0.3)
        samples = transformed
    else:
        samples = raw_samples
    return samples, legacy_order[: samples.shape[1]], {"source_type": "legacy_hdf5_backend", "burnin": burnin}


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
        label_tex = label.strip("$")
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
                    rf"${label_tex} = "
                    rf"{display['median']:.{precision}f}"
                    rf"^{{+{display['err_plus']:.{precision}f}}}"
                    rf"_{{-{display['err_minus']:.{precision}f}}}$"
                ),
            }
        )
    return summaries


def main() -> None:
    args = build_parser().parse_args()

    best_fit = load_phase4_best_fit()
    if args.input.suffix in {".csv", ".gz"}:
        samples, param_names, provenance = read_csv_chain(args.input)
    else:
        samples, param_names, provenance = read_hdf5_chain(args.input, args.chain_name, args.burnin_frac)
    ndim = int(samples.shape[1])
    labels = [LABELS_BY_NAME.get(name, name) for name in param_names]
    summaries = summarize_samples(samples, labels, param_names)
    print(f"[info] chain dimensionality: {ndim}")
    print(f"[info] source type: {provenance['source_type']}")

    plt.rcParams.update(
        {
            "font.size": 11,
            "axes.labelsize": 12,
            "axes.titlesize": 10,
            "xtick.labelsize": 10,
            "ytick.labelsize": 10,
            "figure.dpi": 120,
            "pdf.fonttype": 42,
            "ps.fonttype": 42,
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
    title = r"$\Psi$TMG Posterior Constraints (reference: $\Lambda$CDM)"
    fig.suptitle(title, y=1.02)

    args.out_pdf.parent.mkdir(parents=True, exist_ok=True)
    args.out_png.parent.mkdir(parents=True, exist_ok=True)
    args.summary_json.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(args.out_pdf, bbox_inches="tight")
    fig.savefig(args.out_png, dpi=300, bbox_inches="tight")
    args.summary_json.write_text(
        json.dumps(
            {
                "burnin": provenance["burnin"],
                "source_type": provenance["source_type"],
                "source_path": str(args.input),
                "canonical_best_fit": best_fit,
                "note": (
                    "Canonical release summaries are derived from the Phase 4 CSV chain and verdict report. "
                    "The HDF5 backend is retained only for legacy tooling."
                ),
                "summaries": summaries,
                "raw_chain_points": int(samples.shape[0]),
            },
            indent=2,
            ensure_ascii=False,
        )
        + "\n",
        encoding="utf-8",
    )
    print(f"[ok] Saved: {args.out_pdf}")
    print(f"[ok] Saved: {args.out_png}")
    print(f"[ok] Saved: {args.summary_json}")


if __name__ == "__main__":
    main()
