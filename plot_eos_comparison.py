#!/usr/bin/env python3
"""Compare EoS MCMC chains and generate robustness statistics/figure."""

from __future__ import annotations

import argparse
import importlib.util
import json
import math
from pathlib import Path

import emcee
import matplotlib.pyplot as plt
import numpy as np
from scipy.optimize import minimize
from scipy.stats import gaussian_kde

N_DATA = 1718
SIGMA_LEVELS = (0.68, 0.95)
MAX_PLOT_SAMPLES = 20000
MODEL_SPECS = {
    "cpl": {
        "path": Path("output/ptmg_chains.h5"),
        "chain_name": "ptmg_chain",
        "label": "CPL",
        "color": "#1f77b4",
        "k": 5,
        "ndim": 5,
    },
    "jbp": {
        "path": Path("chains_jbp.h5"),
        "chain_name": "jbp_chain",
        "label": "JBP",
        "color": "#2ca02c",
        "k": 5,
        "ndim": 5,
    },
    "wcdm": {
        "path": Path("chains_wcdm.h5"),
        "chain_name": "wcdm_chain",
        "label": "wCDM",
        "color": "#7f3c8d",
        "k": 4,
        "ndim": 4,
    },
}


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Generate EoS robustness comparison plot and statistics.")
    parser.add_argument(
        "--output-figure",
        type=Path,
        default=Path("manuscript/19_fig_eos_comparison.png"),
        help="Output PNG path for Figure 19.",
    )
    parser.add_argument(
        "--output-json",
        type=Path,
        default=Path("output/eos_robustness_stats.json"),
        help="Output JSON path for chi2/BIC statistics.",
    )
    parser.add_argument(
        "--burnin-frac",
        type=float,
        default=0.30,
        help="Fallback burn-in fraction when autocorrelation time is unavailable.",
    )
    return parser


def load_run_mcmc_module():
    module_path = Path("run_mcmc.py")
    spec = importlib.util.spec_from_file_location("mcgt_run_mcmc", module_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Unable to load module: {module_path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def estimate_burnin(reader: emcee.backends.HDFBackend, burnin_frac: float) -> int:
    chain = reader.get_chain()
    n_steps = int(chain.shape[0])
    burnin_fallback = max(1, int(burnin_frac * n_steps))
    try:
        tau = reader.get_autocorr_time(tol=0)
        burnin_tau = int(2.0 * np.max(tau))
        return min(max(burnin_tau, burnin_fallback), max(1, n_steps - 1))
    except Exception:
        return burnin_fallback


def read_chain(chain_path: Path, chain_name: str, burnin_frac: float) -> dict[str, object]:
    reader = emcee.backends.HDFBackend(str(chain_path), name=chain_name)
    burnin = estimate_burnin(reader, burnin_frac)
    samples = reader.get_chain(discard=burnin, flat=True)
    log_prob = reader.get_log_prob(flat=True)
    return {
        "samples": samples,
        "burnin": burnin,
        "chi2_min": float(-2.0 * np.max(log_prob)),
        "n_steps": int(reader.get_chain().shape[0]),
        "n_walkers": int(reader.get_chain().shape[1]),
    }


def bic(chi2_min: float, k: int, n_data: int = N_DATA) -> float:
    return float(chi2_min + (k * math.log(n_data)))


def compute_lcdm_reference(run_mcmc_mod) -> dict[str, object]:
    bounds = [(0.10, 0.50), (60.0, 80.0), (0.60, 1.00)]
    seeds = [
        np.array([0.30, 67.4, 0.83], dtype=float),
        np.array([0.26, 68.5, 0.80], dtype=float),
        np.array([0.24, 72.0, 0.72], dtype=float),
    ]

    def objective(theta3: np.ndarray) -> float:
        omega_m, h_0, s_8 = [float(x) for x in theta3]
        theta = np.array([omega_m, h_0, -1.0, s_8], dtype=float)
        try:
            chi2_total = run_mcmc_mod.evaluate_chi2_components(theta, eos_model="wcdm")["chi2_total"]
        except Exception:
            return 1.0e30
        if not np.isfinite(chi2_total):
            return 1.0e30
        return float(chi2_total)

    best_result = None
    for seed in seeds:
        result = minimize(objective, seed, method="Powell", bounds=bounds, options={"maxiter": 400, "xtol": 1e-4, "ftol": 1e-4})
        if best_result is None or float(result.fun) < float(best_result.fun):
            best_result = result

    if best_result is None or not best_result.success:
        raise RuntimeError("Unable to optimize LambdaCDM reference chi2.")

    theta_best = np.array(best_result.x, dtype=float)
    chi2_min = float(best_result.fun)
    return {
        "theta_best": {
            "omega_m": float(theta_best[0]),
            "h_0": float(theta_best[1]),
            "w_0": -1.0,
            "w_a": 0.0,
            "s_8": float(theta_best[2]),
        },
        "chi2_min": chi2_min,
        "bic": bic(chi2_min, k=3),
    }


def density_threshold_levels(z: np.ndarray, enclosed_probs: tuple[float, ...]) -> list[float]:
    flat = np.sort(z.ravel())[::-1]
    cdf = np.cumsum(flat)
    cdf /= cdf[-1]
    levels = []
    for prob in enclosed_probs:
        idx = int(np.searchsorted(cdf, prob, side="left"))
        idx = min(max(idx, 0), len(flat) - 1)
        levels.append(float(flat[idx]))
    return levels


def plot_contours(ax: plt.Axes, samples: np.ndarray, label: str, color: str) -> None:
    if samples.shape[0] > MAX_PLOT_SAMPLES:
        rng = np.random.default_rng(42)
        idx = rng.choice(samples.shape[0], size=MAX_PLOT_SAMPLES, replace=False)
        samples = samples[idx]
    x = samples[:, 0]
    y = samples[:, 2]
    values = np.vstack([x, y])
    kde = gaussian_kde(values)

    x_pad = 0.08 * max(np.ptp(x), 1e-3)
    y_pad = 0.08 * max(np.ptp(y), 1e-3)
    xi = np.linspace(float(np.min(x) - x_pad), float(np.max(x) + x_pad), 220)
    yi = np.linspace(float(np.min(y) - y_pad), float(np.max(y) + y_pad), 220)
    xx, yy = np.meshgrid(xi, yi)
    zz = kde(np.vstack([xx.ravel(), yy.ravel()])).reshape(xx.shape)
    levels = density_threshold_levels(zz, SIGMA_LEVELS)
    levels = sorted(levels)

    ax.contour(xx, yy, zz, levels=levels, colors=[color, color], linewidths=(1.4, 2.2), alpha=0.95)
    ax.plot([], [], color=color, linewidth=2.2, label=label)
    ax.scatter(np.median(x), np.median(y), color=color, s=16, alpha=0.85)


def generate_figure(chains: dict[str, dict[str, object]], output_figure: Path) -> None:
    plt.rcParams.update(
        {
            "font.family": "DejaVu Sans",
            "figure.dpi": 140,
            "axes.labelsize": 12,
            "axes.titlesize": 12,
            "xtick.labelsize": 10,
            "ytick.labelsize": 10,
        }
    )
    fig, ax = plt.subplots(figsize=(7.2, 5.6))

    for key in ("cpl", "jbp", "wcdm"):
        spec = MODEL_SPECS[key]
        plot_contours(ax, chains[key]["samples"], spec["label"], spec["color"])

    ax.scatter(0.315, -1.0, marker="x", color="black", s=70, linewidths=1.8, label=r"$\Lambda$CDM")
    ax.set_xlabel(r"$\Omega_m$")
    ax.set_ylabel(r"$w_0$")
    ax.set_title(r"EoS Robustness in the ($\Omega_m, w_0$) Plane")
    ax.grid(alpha=0.18, linewidth=0.5)
    ax.legend(frameon=False, loc="best")
    fig.tight_layout()

    output_figure.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(output_figure, bbox_inches="tight")
    plt.close(fig)


def main() -> int:
    args = build_parser().parse_args()
    run_mcmc_mod = load_run_mcmc_module()

    chains: dict[str, dict[str, object]] = {}
    stats: dict[str, dict[str, object]] = {}
    for key, spec in MODEL_SPECS.items():
        chain_info = read_chain(spec["path"], spec["chain_name"], args.burnin_frac)
        chains[key] = chain_info
        chi2_min = float(chain_info["chi2_min"])
        stats[key] = {
            "label": spec["label"],
            "chi2_min": chi2_min,
            "bic": bic(chi2_min, k=spec["k"]),
            "burnin": int(chain_info["burnin"]),
            "n_steps": int(chain_info["n_steps"]),
            "n_walkers": int(chain_info["n_walkers"]),
        }

    lcdm = compute_lcdm_reference(run_mcmc_mod)
    stats["lcdm"] = {
        "label": "LambdaCDM",
        "chi2_min": float(lcdm["chi2_min"]),
        "bic": float(lcdm["bic"]),
        "theta_best": lcdm["theta_best"],
    }

    for key in ("cpl", "jbp", "wcdm"):
        stats[key]["delta_chi2_vs_lcdm"] = float(stats[key]["chi2_min"] - stats["lcdm"]["chi2_min"])
        stats[key]["delta_bic_vs_lcdm"] = float(stats[key]["bic"] - stats["lcdm"]["bic"])

    generate_figure(chains, args.output_figure)

    args.output_json.parent.mkdir(parents=True, exist_ok=True)
    args.output_json.write_text(json.dumps(stats, indent=2), encoding="utf-8")

    print(json.dumps(stats, indent=2))
    print(f"[ok] Saved figure: {args.output_figure}")
    print(f"[ok] Saved stats: {args.output_json}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
