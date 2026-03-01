#!/usr/bin/env python3
"""Run the v3.2.1 TIDE benchmark against the v3.2.0 CPL baseline."""

from __future__ import annotations

import argparse
import json
import math
from pathlib import Path
import sys

import emcee
import matplotlib.pyplot as plt
import numpy as np
from scipy.optimize import minimize
from scipy.stats import gaussian_kde

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

import run_mcmc

RESULTS_DIR = Path("results/v3.2.1_TIDE")
TIDE_CHAIN = RESULTS_DIR / "tide_chains.h5"
TIDE_CHAIN_NAME = "tide_chain"
TIDE_REPORT_JSON = RESULTS_DIR / "tide_benchmark_report.json"
TIDE_REPORT_MD = RESULTS_DIR / "tide_benchmark_report.md"
TIDE_FIGURE = RESULTS_DIR / "tide_vs_v320_common_contours.png"
BASELINE_CHAIN = Path("output/ptmg_chains.h5")
BASELINE_CHAIN_NAME = "ptmg_chain"
COMMON_LABELS = (r"$\Omega_m$", r"$H_0$", r"$S_8$")
SIGMA_LEVELS = (0.68, 0.95)
MAX_PLOT_SAMPLES = 15000


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Benchmark Alejandro Rey's TIDE EoS against ΨTMG v3.2.0.")
    parser.add_argument("--n-walkers", type=int, default=24, help="Number of walkers for the exploratory TIDE MCMC.")
    parser.add_argument("--n-steps", type=int, default=120, help="Number of steps per walker for the exploratory TIDE MCMC.")
    parser.add_argument("--seed", type=int, default=42, help="Random seed.")
    parser.add_argument("--skip-mcmc", action="store_true", help="Only run the local optimization and report generation.")
    return parser


def objective_tide(theta: np.ndarray) -> float:
    try:
        chi2 = run_mcmc.evaluate_chi2_components(np.asarray(theta, dtype=float), eos_model="tide")["chi2_total"]
    except Exception:
        return math.inf
    return float(chi2) if np.isfinite(chi2) else math.inf


def objective_lcdm(theta3: np.ndarray) -> float:
    theta = np.array([theta3[0], theta3[1], -1.0, theta3[2]], dtype=float)
    try:
        chi2 = run_mcmc.evaluate_chi2_components(theta, eos_model="wcdm")["chi2_total"]
    except Exception:
        return math.inf
    return float(chi2) if np.isfinite(chi2) else math.inf


def optimize_tide() -> dict[str, object]:
    bounds = [
        run_mcmc.PRIOR_BOUNDS["Omega_m"],
        run_mcmc.PRIOR_BOUNDS["H_0"],
        run_mcmc.PRIOR_BOUNDS["kappa"],
        run_mcmc.PRIOR_BOUNDS["S_8"],
    ]
    seeds = [
        np.array([0.243, 72.97, 0.0, 0.718], dtype=float),
        np.array([0.243, 76.35, 8.0, 0.718], dtype=float),
        np.array([0.260, 76.35, 25.0, 0.730], dtype=float),
        np.array([0.230, 75.00, 60.0, 0.700], dtype=float),
    ]
    best = None
    for seed in seeds:
        result = minimize(
            objective_tide,
            seed,
            method="Powell",
            bounds=bounds,
            options={"maxiter": 180, "xtol": 1e-4, "ftol": 1e-4},
        )
        if best is None or float(result.fun) < float(best.fun):
            best = result
    if best is None:
        raise RuntimeError("TIDE optimization failed to produce a result.")
    theta = np.asarray(best.x, dtype=float)
    chi2 = run_mcmc.evaluate_chi2_components(theta, eos_model="tide")
    return {
        "success": bool(best.success),
        "message": best.message,
        "theta": {
            "Omega_m": float(theta[0]),
            "H_0": float(theta[1]),
            "kappa": float(theta[2]),
            "S_8": float(theta[3]),
        },
        "chi2": chi2,
        "nfev": int(best.nfev),
    }


def optimize_lcdm_reference() -> dict[str, object]:
    bounds = [
        run_mcmc.PRIOR_BOUNDS["Omega_m"],
        run_mcmc.PRIOR_BOUNDS["H_0"],
        run_mcmc.PRIOR_BOUNDS["S_8"],
    ]
    seeds = [
        np.array([0.315, 67.4, 0.83], dtype=float),
        np.array([0.280, 72.0, 0.80], dtype=float),
        np.array([0.260, 74.0, 0.76], dtype=float),
    ]
    best = None
    for seed in seeds:
        result = minimize(
            objective_lcdm,
            seed,
            method="Powell",
            bounds=bounds,
            options={"maxiter": 180, "xtol": 1e-4, "ftol": 1e-4},
        )
        if best is None or float(result.fun) < float(best.fun):
            best = result
    if best is None:
        raise RuntimeError("LCDM optimization failed to produce a result.")
    theta = np.asarray(best.x, dtype=float)
    chi2 = run_mcmc.evaluate_chi2_components(np.array([theta[0], theta[1], -1.0, theta[2]], dtype=float), eos_model="wcdm")
    return {
        "success": bool(best.success),
        "message": best.message,
        "theta": {"Omega_m": float(theta[0]), "H_0": float(theta[1]), "S_8": float(theta[2])},
        "chi2": chi2,
        "nfev": int(best.nfev),
    }


def estimate_burnin(reader: emcee.backends.HDFBackend, burnin_frac: float = 0.30) -> int:
    chain = reader.get_chain()
    n_steps = int(chain.shape[0])
    burnin_fallback = max(1, int(burnin_frac * n_steps))
    try:
        tau = reader.get_autocorr_time(tol=0)
        return min(max(int(2.0 * np.max(tau)), burnin_fallback), max(1, n_steps - 1))
    except Exception:
        return burnin_fallback


def run_exploratory_mcmc(theta_best: np.ndarray, n_walkers: int, n_steps: int, seed: int) -> dict[str, object]:
    model_spec = run_mcmc.get_model_spec("tide")
    prior_bounds = model_spec["prior_bounds"]
    param_names = model_spec["param_names"]
    rng = np.random.default_rng(seed)
    p0 = run_mcmc.init_walkers(
        n_walkers=n_walkers,
        rng=rng,
        center=theta_best,
        sigma=np.array([0.006, 0.20, 3.0, 0.010], dtype=float),
        param_names=param_names,
        prior_bounds=prior_bounds,
    )
    backend = run_mcmc.make_backend(TIDE_CHAIN, n_walkers, TIDE_CHAIN_NAME, len(theta_best))
    sampler = emcee.EnsembleSampler(
        nwalkers=n_walkers,
        ndim=len(theta_best),
        log_prob_fn=run_mcmc.log_probability,
        backend=backend,
        args=("tide", prior_bounds, param_names),
    )
    sampler.run_mcmc(p0, n_steps, progress=False)
    theta_median, burnin = run_mcmc.summarize_bestfit_from_chain(sampler)
    return {
        "acceptance_fraction": float(np.mean(sampler.acceptance_fraction)),
        "burnin": int(burnin),
        "theta_median": {
            "Omega_m": float(theta_median[0]),
            "H_0": float(theta_median[1]),
            "kappa": float(theta_median[2]),
            "S_8": float(theta_median[3]),
        },
    }


def load_baseline_reference() -> dict[str, float]:
    reader = emcee.backends.HDFBackend(str(BASELINE_CHAIN), name=BASELINE_CHAIN_NAME)
    burnin = estimate_burnin(reader)
    samples = reader.get_chain(discard=burnin, flat=True)
    med = np.median(samples, axis=0)
    chi2 = run_mcmc.evaluate_chi2_components(med, eos_model="cpl")
    return {
        "Omega_m": float(med[0]),
        "H_0": float(med[1]),
        "w_0": float(med[2]),
        "w_a": float(med[3]),
        "S_8": float(med[4]),
        "chi2_total": float(chi2["chi2_total"]),
        "burnin": int(burnin),
    }


def _downsample(samples: np.ndarray, seed: int) -> np.ndarray:
    if samples.shape[0] <= MAX_PLOT_SAMPLES:
        return samples
    rng = np.random.default_rng(seed)
    idx = rng.choice(samples.shape[0], size=MAX_PLOT_SAMPLES, replace=False)
    return samples[idx]


def density_threshold_levels(z: np.ndarray, enclosed_probs: tuple[float, ...]) -> list[float]:
    flat = np.sort(z.ravel())[::-1]
    cdf = np.cumsum(flat)
    cdf /= cdf[-1]
    levels = []
    for prob in enclosed_probs:
        idx = int(np.searchsorted(cdf, prob, side="left"))
        idx = min(max(idx, 0), len(flat) - 1)
        levels.append(float(flat[idx]))
    return sorted(levels)


def plot_overlay_contours(baseline_samples: np.ndarray, tide_samples: np.ndarray, output: Path) -> None:
    fig, axes = plt.subplots(1, 3, figsize=(13.5, 4.2))
    pairs = ((0, 1), (0, 2), (1, 2))
    series = (
        ("v3.2.0 CPL", baseline_samples, "#1f77b4"),
        ("v3.2.1 TIDE", tide_samples, "#d62728"),
    )
    for ax, (i, j) in zip(axes, pairs):
        for label, samples, color in series:
            sample_view = _downsample(samples[:, [i, j]], seed=42)
            values = sample_view.T
            kde = gaussian_kde(values)
            x = values[0]
            y = values[1]
            x_pad = 0.10 * (np.max(x) - np.min(x) + 1e-6)
            y_pad = 0.10 * (np.max(y) - np.min(y) + 1e-6)
            xi = np.linspace(float(np.min(x) - x_pad), float(np.max(x) + x_pad), 180)
            yi = np.linspace(float(np.min(y) - y_pad), float(np.max(y) + y_pad), 180)
            xx, yy = np.meshgrid(xi, yi)
            zz = kde(np.vstack([xx.ravel(), yy.ravel()])).reshape(xx.shape)
            levels = density_threshold_levels(zz, SIGMA_LEVELS)
            ax.contour(xx, yy, zz, levels=levels, colors=[color, color], linewidths=(1.2, 2.0), alpha=0.95)
            ax.plot([], [], color=color, linewidth=2.0, label=label)
        ax.set_xlabel(COMMON_LABELS[i])
        ax.set_ylabel(COMMON_LABELS[j])
        ax.grid(alpha=0.15, linewidth=0.5)
    axes[0].legend(loc="upper right", frameon=False)
    fig.suptitle(r"v3.2.0 vs v3.2.1 TIDE Posterior Shift (common subspace)")
    fig.tight_layout()
    output.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(output, dpi=220, bbox_inches="tight")
    plt.close(fig)


def load_chain_samples(path: Path, chain_name: str) -> np.ndarray:
    reader = emcee.backends.HDFBackend(str(path), name=chain_name)
    burnin = estimate_burnin(reader)
    return reader.get_chain(discard=burnin, flat=True)


def build_report_payload(
    baseline: dict[str, float],
    tide_opt: dict[str, object],
    lcdm_ref: dict[str, object],
    mcmc_info: dict[str, object] | None,
) -> dict[str, object]:
    tide_theta = tide_opt["theta"]
    tide_chi2 = tide_opt["chi2"]["chi2_total"]
    lcdm_chi2 = lcdm_ref["chi2"]["chi2_total"]
    baseline_delta = baseline["chi2_total"] - lcdm_chi2
    tide_delta = tide_chi2 - lcdm_chi2
    return {
        "baseline_v3_2_0": baseline,
        "tide_local_optimization": tide_opt,
        "lcdm_reference": lcdm_ref,
        "exploratory_mcmc": mcmc_info,
        "comparison": {
            "delta_chi2_vs_lcdm": {
                "v3.2.0_cpl": float(baseline_delta),
                "v3.2.1_tide": float(tide_delta),
            },
            "H_0": {
                "v3.2.0_cpl": float(baseline["H_0"]),
                "v3.2.1_tide": float(tide_theta["H_0"]),
                "target_tide": 76.35,
            },
            "S_8": {
                "v3.2.0_cpl": float(baseline["S_8"]),
                "v3.2.1_tide": float(tide_theta["S_8"]),
                "target_tide": 0.718,
            },
        },
    }


def write_markdown_report(payload: dict[str, object], output: Path) -> None:
    cmp = payload["comparison"]
    tide = payload["tide_local_optimization"]
    lines = [
        "# TIDE Benchmark v3.2.1",
        "",
        f"- Branch target: `v3.2.1-tide-integration`",
        f"- Local optimization success: `{tide['success']}`",
        f"- Optimized kappa: `{tide['theta']['kappa']:.6f}`",
        "",
        "| Metric | v3.2.0 CPL | v3.2.1 TIDE | Target |",
        "| --- | ---: | ---: | ---: |",
        f"| Δχ² vs ΛCDM | {cmp['delta_chi2_vs_lcdm']['v3.2.0_cpl']:.3f} | {cmp['delta_chi2_vs_lcdm']['v3.2.1_tide']:.3f} | lower is better |",
        f"| H0 | {cmp['H_0']['v3.2.0_cpl']:.3f} | {cmp['H_0']['v3.2.1_tide']:.3f} | {cmp['H_0']['target_tide']:.3f} |",
        f"| S8 | {cmp['S_8']['v3.2.0_cpl']:.3f} | {cmp['S_8']['v3.2.1_tide']:.3f} | {cmp['S_8']['target_tide']:.3f} |",
        "",
    ]
    output.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    args = build_parser().parse_args()
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)

    baseline = load_baseline_reference()
    tide_opt = optimize_tide()
    lcdm_ref = optimize_lcdm_reference()
    mcmc_info = None

    if not args.skip_mcmc:
        theta_best = np.array(
            [
                tide_opt["theta"]["Omega_m"],
                tide_opt["theta"]["H_0"],
                tide_opt["theta"]["kappa"],
                tide_opt["theta"]["S_8"],
            ],
            dtype=float,
        )
        mcmc_info = run_exploratory_mcmc(theta_best, args.n_walkers, args.n_steps, args.seed)
        baseline_samples = load_chain_samples(BASELINE_CHAIN, BASELINE_CHAIN_NAME)[:, [0, 1, 4]]
        tide_samples = load_chain_samples(TIDE_CHAIN, TIDE_CHAIN_NAME)[:, [0, 1, 3]]
        plot_overlay_contours(baseline_samples, tide_samples, TIDE_FIGURE)

    payload = build_report_payload(baseline, tide_opt, lcdm_ref, mcmc_info)
    TIDE_REPORT_JSON.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    write_markdown_report(payload, TIDE_REPORT_MD)
    print(json.dumps(payload["comparison"], indent=2))
    if mcmc_info is not None:
        print(f"[ok] Saved chain: {TIDE_CHAIN}")
        print(f"[ok] Saved figure: {TIDE_FIGURE}")
    print(f"[ok] Saved report: {TIDE_REPORT_JSON}")
    print(f"[ok] Saved report: {TIDE_REPORT_MD}")


if __name__ == "__main__":
    main()
