#!/usr/bin/env python3
"""Compute Bayesian evidence ln(Z) for PsiTMG with dynesty (SN+BAO+CMB)."""

from __future__ import annotations

import argparse
import importlib.util
import math
import multiprocessing as mp
import pickle
from pathlib import Path
from typing import Any

import dynesty
import numpy as np

# Parameterization for the full 4D CPL run.
PARAM_NAMES = ("Omega_m", "H_0", "w_0", "w_a")
PRIOR_BOUNDS: dict[str, tuple[float, float]] = {
    "Omega_m": (0.10, 0.50),
    "H_0": (60.0, 80.0),
    "w_0": (-2.5, -0.3),
    "w_a": (-3.0, 3.0),
}

RUNTIME: dict[str, Any] | None = None


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Nested Sampling evidence run for PsiTMG (SN+BAO+CMB)."
    )
    parser.add_argument("--nlive", type=int, default=800, help="Number of live points.")
    parser.add_argument("--dlogz", type=float, default=0.01, help="Stopping criterion on evidence.")
    parser.add_argument(
        "--maxiter",
        type=int,
        default=None,
        help="Maximum number of nested iterations (default: no explicit cap).",
    )
    parser.add_argument("--seed", type=int, default=20260305, help="Random seed.")
    parser.add_argument(
        "--n-steps-int",
        type=int,
        default=2500,
        help="Integration grid size for SN/BAO/CMB likelihood helper.",
    )
    parser.add_argument(
        "--sigma-sys",
        type=float,
        default=0.1,
        help="Systematic sigma used in SN chi2 (same convention as MCMC pipeline).",
    )
    parser.add_argument(
        "--processes",
        type=int,
        default=max(1, mp.cpu_count()),
        help="Worker processes for multiprocessing pool.",
    )
    parser.add_argument(
        "--queue-size",
        type=int,
        default=None,
        help="dynesty queue_size (default: equal to --processes).",
    )
    return parser


def _load_module(module_path: Path, module_name: str):
    spec = importlib.util.spec_from_file_location(module_name, module_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Cannot load module at {module_path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def init_runtime(root: Path, sigma_sys: float, n_steps_int: int) -> None:
    global RUNTIME
    tri_probe_path = root / "scripts" / "09_dark_energy_cpl" / "09_mcmc_sampler.py"
    tri_probe = _load_module(tri_probe_path, "psitmg_tri_probe")

    params_template = tri_probe.load_config(root / "config" / "mcgt-global-config.ini")
    sn_raw = np.loadtxt(
        root / "assets" / "zz-data" / "08_sound_horizon" / "08_pantheon_data.csv",
        delimiter=",",
        skiprows=1,
    )
    bao_raw = np.loadtxt(
        root / "assets" / "zz-data" / "08_sound_horizon" / "08_bao_data.csv",
        delimiter=",",
        skiprows=1,
    )

    RUNTIME = {
        "tri_probe": tri_probe,
        "params_template": params_template,
        "sn_data": (sn_raw[:, 0], sn_raw[:, 1], sn_raw[:, 2]),
        "bao_data": (bao_raw[:, 0], bao_raw[:, 1], bao_raw[:, 2]),
        "sigma_sys": float(sigma_sys),
        "n_steps_int": int(n_steps_int),
    }


def prior_transform(u: np.ndarray) -> np.ndarray:
    """Map unit-cube coordinates u in [0,1]^ndim to physical parameter space."""
    theta = np.asarray(u, dtype=float).copy()
    for i, name in enumerate(PARAM_NAMES):
        lo, hi = PRIOR_BOUNDS[name]
        theta[i] = lo + (hi - lo) * theta[i]
    return theta


def log_likelihood(theta: np.ndarray) -> float:
    """Return log-likelihood = -0.5 * chi2 from existing PsiTMG tri-probe engine."""
    global RUNTIME
    if RUNTIME is None:
        raise RuntimeError("Runtime not initialized. Call init_runtime() before sampling.")

    omega_m, h_0, w_0, w_a = map(float, theta)
    params = dict(RUNTIME["params_template"])
    params["H0"] = h_0
    params["h"] = h_0 / 100.0
    params["omega_b"] = params["ombh2"] / (params["h"] * params["h"])

    tri_probe = RUNTIME["tri_probe"]
    logp, chi2_total, _, _ = tri_probe.log_posterior(
        params,
        omega_m,
        w_0,
        w_a,
        RUNTIME["sn_data"],
        RUNTIME["bao_data"],
        RUNTIME["sigma_sys"],
        RUNTIME["n_steps_int"],
        "CPL",
    )

    if not np.isfinite(logp) or not np.isfinite(chi2_total):
        return -math.inf
    return -0.5 * float(chi2_total)


def main() -> int:
    args = build_parser().parse_args()

    script_path = Path(__file__).resolve()
    root = script_path.parents[3]
    test_root = script_path.parents[1]
    scripts_dir = test_root / "scripts"
    out_dir = test_root / "outputs"
    scripts_dir.mkdir(parents=True, exist_ok=True)
    out_dir.mkdir(parents=True, exist_ok=True)

    init_runtime(root=root, sigma_sys=args.sigma_sys, n_steps_int=args.n_steps_int)

    ndim = len(PARAM_NAMES)
    queue_size = args.queue_size if args.queue_size is not None else max(1, args.processes)
    rstate = np.random.default_rng(args.seed)

    with mp.Pool(processes=max(1, args.processes)) as pool:
        sampler = dynesty.NestedSampler(
            loglikelihood=log_likelihood,
            prior_transform=prior_transform,
            ndim=ndim,
            nlive=args.nlive,
            pool=pool,
            queue_size=queue_size,
            rstate=rstate,
        )
        sampler.run_nested(dlogz=args.dlogz, maxiter=args.maxiter, print_progress=True)
        results = sampler.results

    out_pkl = out_dir / "psitmg_nested_res.pkl"
    with out_pkl.open("wb") as f:
        pickle.dump(results, f, protocol=pickle.HIGHEST_PROTOCOL)

    lnz = float(results.logz[-1])
    lnz_err = float(results.logzerr[-1])
    ncall = int(np.sum(results.ncall))
    niter = int(results.niter)

    report_path = out_dir / "nested_evidence_report.txt"
    report_lines = [
        "PsiTMG Nested Sampling Evidence Report (SN+BAO+CMB)",
        f"lnZ = {lnz:.6f}",
        f"lnZ_err = +/- {lnz_err:.6f}",
        f"niter = {niter}",
        f"ncall_total = {ncall}",
        f"nlive = {args.nlive}",
        f"dlogz_stop = {args.dlogz}",
        f"processes = {max(1, args.processes)}",
        "",
        "Parameter priors:",
    ]
    for name in PARAM_NAMES:
        lo, hi = PRIOR_BOUNDS[name]
        report_lines.append(f"- {name}: [{lo}, {hi}]")
    report_lines.append(f"\nresults_pickle = {out_pkl}")
    report_path.write_text("\n".join(report_lines) + "\n", encoding="utf-8")

    print(f"Saved nested results pickle: {out_pkl}")
    print(f"Saved evidence report: {report_path}")
    print(f"lnZ = {lnz:.6f} +/- {lnz_err:.6f}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
