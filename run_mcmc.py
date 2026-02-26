#!/usr/bin/env python3
"""Run ΨTMG MCMC with emcee and save chains for later corner-plot usage."""

from __future__ import annotations

import argparse
import importlib.util
import math
from pathlib import Path

import emcee
import numpy as np

MODEL_CHOICES = ("cpl", "wcdm")
PARAM_NAMES_CPL = ("Omega_m", "H_0", "w_0", "w_a", "S_8")
PARAM_NAMES_WCDM = ("Omega_m", "H_0", "w_0", "S_8")

# Sampling configuration
N_WALKERS = 100
N_STEPS_DEFAULT = 5000
N_STEPS_TEST = 500
SEED = 42

# Expected best-fit center for initialization
THETA_BESTFIT_CPL = np.array([0.243, 72.97, -0.69, -2.81, 0.718], dtype=float)
THETA_BESTFIT_WCDM = np.array([0.243, 72.97, -0.69, 0.718], dtype=float)
INIT_SIGMA_CPL = np.array([0.008, 0.25, 0.03, 0.20, 0.015], dtype=float)
INIT_SIGMA_WCDM = np.array([0.008, 0.25, 0.03, 0.015], dtype=float)

# Uniform prior bounds: (min, max)
PRIOR_BOUNDS = {
    "Omega_m": (0.10, 0.50),
    "H_0": (60.0, 80.0),
    "w_0": (-2.5, -0.3),
    "w_a": (-3.0, 3.0),
    "S_8": (0.60, 1.00),
}

TRI_PROBE_CONFIG = Path("config/mcgt-global-config.ini")
TRI_PROBE_SIGMA_SYS = 0.1
TRI_PROBE_N_STEPS_INT = 2500
_TRI_PROBE_RUNTIME: dict[str, object] | None = None
_RSD_RUNTIME: dict[str, object] | None = None


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Run emcee MCMC for ΨTMG and save chains to disk."
    )
    parser.add_argument(
        "--n-steps",
        type=int,
        default=N_STEPS_DEFAULT,
        help=f"Number of steps per walker (default: {N_STEPS_DEFAULT}).",
    )
    parser.add_argument(
        "--quick-test",
        action="store_true",
        help=f"Use {N_STEPS_TEST} steps for quick checks.",
    )
    parser.add_argument("--n-walkers", type=int, default=N_WALKERS)
    parser.add_argument("--seed", type=int, default=SEED)
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("output/ptmg_chains.h5"),
        help="Output chain file (.h5 preferred).",
    )
    parser.add_argument(
        "--chain-name",
        type=str,
        default="ptmg_chain",
        help="Dataset group name in HDF5 backend.",
    )
    parser.add_argument(
        "--model",
        type=str,
        choices=MODEL_CHOICES,
        default="cpl",
        help="Cosmological model: 'cpl' (free w_a) or 'wcdm' (w_a fixed to 0).",
    )
    return parser


def get_model_spec(model: str) -> dict[str, object]:
    """Return parameterization details for selected model."""
    if model == "cpl":
        param_names = PARAM_NAMES_CPL
        theta_bestfit = THETA_BESTFIT_CPL
        init_sigma = INIT_SIGMA_CPL
    elif model == "wcdm":
        param_names = PARAM_NAMES_WCDM
        theta_bestfit = THETA_BESTFIT_WCDM
        init_sigma = INIT_SIGMA_WCDM
    else:  # pragma: no cover
        raise ValueError(f"Unknown model '{model}'.")

    prior_bounds = {name: PRIOR_BOUNDS[name] for name in param_names}
    return {
        "param_names": param_names,
        "theta_bestfit": theta_bestfit,
        "init_sigma": init_sigma,
        "prior_bounds": prior_bounds,
        "ndim": len(param_names),
    }


def _load_tri_probe_runtime() -> dict[str, object]:
    """Load and cache tri-probe likelihood helpers from chapter 09."""
    global _TRI_PROBE_RUNTIME
    if _TRI_PROBE_RUNTIME is not None:
        return _TRI_PROBE_RUNTIME

    root = Path(__file__).resolve().parent
    module_path = root / "scripts/09_dark_energy_cpl/09_mcmc_sampler.py"
    spec = importlib.util.spec_from_file_location("mcgt_tri_probe", module_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Impossible de charger le module: {module_path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)

    params_template = module.load_config(root / TRI_PROBE_CONFIG)

    sn_raw = np.loadtxt(
        root / "assets/zz-data/08_sound_horizon/08_pantheon_data.csv",
        delimiter=",",
        skiprows=1,
    )
    bao_raw = np.loadtxt(
        root / "assets/zz-data/08_sound_horizon/08_bao_data.csv",
        delimiter=",",
        skiprows=1,
    )
    sn_data = (sn_raw[:, 0], sn_raw[:, 1], sn_raw[:, 2])
    bao_data = (bao_raw[:, 0], bao_raw[:, 1], bao_raw[:, 2])

    _TRI_PROBE_RUNTIME = {
        "log_posterior": module.log_posterior,
        "chi2_sn": module.chi2_sn,
        "chi2_bao": module.chi2_bao,
        "chi2_cmb": module.chi2_cmb,
        "params_template": params_template,
        "sn_data": sn_data,
        "bao_data": bao_data,
    }
    return _TRI_PROBE_RUNTIME


def _load_rsd_runtime() -> dict[str, object]:
    """Load and cache RSD likelihood helper from chapter 10."""
    global _RSD_RUNTIME
    if _RSD_RUNTIME is not None:
        return _RSD_RUNTIME

    root = Path(__file__).resolve().parent
    module_path = root / "scripts/10_structure_growth/10_rsd_likelihood.py"
    spec = importlib.util.spec_from_file_location("mcgt_rsd", module_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Impossible de charger le module RSD: {module_path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)

    _RSD_RUNTIME = {
        "get_chi2_rsd": module.get_chi2_rsd,
        "load_rsd_data": module.load_rsd_data,
    }
    return _RSD_RUNTIME


def _unpack_theta(theta: np.ndarray, model: str) -> tuple[float, float, float, float, float]:
    """Map theta to (Omega_m, H_0, w_0, w_a, S_8) according to model."""
    if model == "cpl":
        omega_m, h_0, w_0, w_a, s_8 = theta
    elif model == "wcdm":
        omega_m, h_0, w_0, s_8 = theta
        w_a = 0.0
    else:  # pragma: no cover
        raise ValueError(f"Unknown model '{model}'.")
    return float(omega_m), float(h_0), float(w_0), float(w_a), float(s_8)


def evaluate_chi2_components(theta: np.ndarray, model: str = "cpl") -> dict[str, float]:
    """Return chi2 contributions per probe and total for a given parameter vector."""
    omega_m, h_0, w_0, w_a, s_8 = _unpack_theta(theta, model)

    runtime = _load_tri_probe_runtime()
    rsd_runtime = _load_rsd_runtime()
    params = dict(runtime["params_template"])
    params["H0"] = float(h_0)
    params["h"] = float(h_0) / 100.0
    params["omega_b"] = params["ombh2"] / (params["h"] * params["h"])

    chi2_sn = float(
        runtime["chi2_sn"](
            *runtime["sn_data"],
            params,
            omega_m,
            w_0,
            w_a,
            TRI_PROBE_SIGMA_SYS,
            TRI_PROBE_N_STEPS_INT,
        )
    )
    chi2_bao = float(
        runtime["chi2_bao"](
            *runtime["bao_data"],
            params,
            omega_m,
            w_0,
            w_a,
            TRI_PROBE_N_STEPS_INT,
        )
    )
    chi2_cmb = float(
        runtime["chi2_cmb"](
            params,
            omega_m,
            w_0,
            w_a,
            TRI_PROBE_N_STEPS_INT,
        )
    )

    sigma_8_0 = s_8 / math.sqrt(omega_m / 0.3)
    chi2_rsd = float(
        rsd_runtime["get_chi2_rsd"](
            omega_m,
            w_0,
            w_a,
            sigma_8_0,
            h_0=h_0,
        )
    )

    chi2_total = chi2_sn + chi2_bao + chi2_cmb + chi2_rsd
    return {
        "chi2_sn": chi2_sn,
        "chi2_bao": chi2_bao,
        "chi2_cmb": chi2_cmb,
        "chi2_rsd": chi2_rsd,
        "chi2_total": chi2_total,
    }


def calculate_information_criteria(
    chi2_total: float,
    n_params: int,
    n_data_points: int,
) -> tuple[float, float]:
    """Compute AIC and BIC from total chi2."""
    aic = (2.0 * float(n_params)) + float(chi2_total)
    bic = (float(n_params) * math.log(float(n_data_points))) + float(chi2_total)
    return aic, bic


def count_data_points() -> dict[str, int]:
    """Count data points used in SN, BAO, CMB and RSD probes."""
    runtime = _load_tri_probe_runtime()
    rsd_runtime = _load_rsd_runtime()

    n_sn = int(len(runtime["sn_data"][0]))
    n_bao = int(len(runtime["bao_data"][0]))
    n_cmb = 1
    rsd_z, _, _ = rsd_runtime["load_rsd_data"]()
    n_rsd = int(len(rsd_z))
    n_total = n_sn + n_bao + n_cmb + n_rsd

    return {
        "n_sn": n_sn,
        "n_bao": n_bao,
        "n_cmb": n_cmb,
        "n_rsd": n_rsd,
        "n_total": n_total,
    }


def summarize_bestfit_from_chain(sampler: emcee.EnsembleSampler) -> tuple[np.ndarray, int]:
    """Return parameter medians from flattened post-burn-in chain."""
    chain = sampler.get_chain()
    n_steps = chain.shape[0]
    burnin = min(max(1, int(0.30 * n_steps)), max(1, n_steps - 1))

    samples = sampler.get_chain(discard=burnin, flat=True)
    if samples.size == 0:
        burnin = 0
        samples = sampler.get_chain(flat=True)

    theta_median = np.median(samples, axis=0)
    return theta_median, burnin


def _print_bestfit_report(
    theta: np.ndarray,
    burnin: int,
    param_names: tuple[str, ...],
    model: str,
) -> None:
    chi2 = evaluate_chi2_components(theta, model=model)
    counts = count_data_points()
    aic, bic = calculate_information_criteria(
        chi2_total=chi2["chi2_total"],
        n_params=len(param_names),
        n_data_points=counts["n_total"],
    )

    print("\n=== Best-Fit (medianes post-burn-in) ===")
    print(f"Modele: {model}")
    print(f"Burn-in utilise: {burnin} steps")
    for name, value in zip(param_names, theta):
        print(f"{name:<8} = {float(value):.6f}")

    print("\n=== Contributions chi2 ===")
    print(f"{'Sonde':<16} {'chi2':>12} {'N points':>12}")
    print(f"{'-' * 16} {'-' * 12} {'-' * 12}")
    print(f"{'SN':<16} {chi2['chi2_sn']:>12.6f} {counts['n_sn']:>12d}")
    print(f"{'BAO':<16} {chi2['chi2_bao']:>12.6f} {counts['n_bao']:>12d}")
    print(f"{'CMB':<16} {chi2['chi2_cmb']:>12.6f} {counts['n_cmb']:>12d}")
    print(f"{'RSD':<16} {chi2['chi2_rsd']:>12.6f} {counts['n_rsd']:>12d}")
    print(f"{'Total':<16} {chi2['chi2_total']:>12.6f} {counts['n_total']:>12d}")

    print("\n=== Information Criteria ===")
    print(f"{'k (params libres)':<24} {len(param_names)}")
    print(f"{'n (donnees totales)':<24} {counts['n_total']}")
    print(f"{'AIC':<24} {aic:.6f}")
    print(f"{'BIC':<24} {bic:.6f}")


def log_prior(
    theta: np.ndarray,
    prior_bounds: dict[str, tuple[float, float]],
    param_names: tuple[str, ...],
) -> float:
    """Uniform priors on physically viable ranges."""
    for idx, name in enumerate(param_names):
        lo, hi = prior_bounds[name]
        if not (lo < float(theta[idx]) < hi):
            return -math.inf
    return 0.0


def pipeline_loglike_from_theta(theta: np.ndarray, model: str = "cpl") -> float:
    """
    Real ΨTMG tri-probe likelihood (SN+BAO+CMB) from chapter 09 pipeline.

    Source:
      scripts/09_dark_energy_cpl/09_mcmc_sampler.py::log_posterior
    """
    omega_m, h_0, w_0, w_a, _s_8 = _unpack_theta(theta, model)

    runtime = _load_tri_probe_runtime()
    params = dict(runtime["params_template"])
    params["H0"] = float(h_0)
    params["h"] = float(h_0) / 100.0
    params["omega_b"] = params["ombh2"] / (params["h"] * params["h"])

    logp, _, _, _ = runtime["log_posterior"](
        params,
        omega_m,
        w_0,
        w_a,
        runtime["sn_data"],
        runtime["bao_data"],
        TRI_PROBE_SIGMA_SYS,
        TRI_PROBE_N_STEPS_INT,
    )
    if not np.isfinite(logp):
        return -math.inf

    chi2_total_combine = evaluate_chi2_components(theta, model=model)["chi2_total"]
    return -0.5 * chi2_total_combine


def log_likelihood(theta: np.ndarray, model: str = "cpl") -> float:
    """Log-likelihood wrapper."""
    return pipeline_loglike_from_theta(theta, model=model)


def log_probability(
    theta: np.ndarray,
    model: str,
    prior_bounds: dict[str, tuple[float, float]],
    param_names: tuple[str, ...],
) -> float:
    lp = log_prior(theta, prior_bounds, param_names)
    if not np.isfinite(lp):
        return -math.inf
    ll = log_likelihood(theta, model=model)
    if not np.isfinite(ll):
        return -math.inf
    return lp + ll


def init_walkers(
    n_walkers: int,
    rng: np.random.Generator,
    center: np.ndarray,
    sigma: np.ndarray,
    param_names: tuple[str, ...],
    prior_bounds: dict[str, tuple[float, float]],
) -> np.ndarray:
    """Initialize walkers in a small Gaussian ball around expected best-fit."""
    p0 = rng.normal(loc=center, scale=sigma, size=(n_walkers, len(param_names)))
    for j, name in enumerate(param_names):
        lo, hi = prior_bounds[name]
        eps = 1e-6 * (hi - lo)
        p0[:, j] = np.clip(p0[:, j], lo + eps, hi - eps)
    return p0


def make_backend(
    output_file: Path,
    n_walkers: int,
    chain_name: str,
    n_dim: int,
) -> emcee.backends.Backend:
    output_file.parent.mkdir(parents=True, exist_ok=True)
    if output_file.suffix.lower() != ".h5":
        return emcee.backends.Backend()
    try:
        backend = emcee.backends.HDFBackend(str(output_file), name=chain_name)
        backend.reset(n_walkers, n_dim)
        return backend
    except Exception as exc:  # pragma: no cover
        print(f"[warn] HDF5 backend unavailable ({exc}). Falling back to memory backend.")
        return emcee.backends.Backend()


def save_csv_fallback(
    sampler: emcee.EnsembleSampler,
    output_h5: Path,
    param_names: tuple[str, ...],
) -> Path:
    chain = sampler.get_chain(flat=True)
    logp = sampler.get_log_prob(flat=True)
    out_csv = output_h5.with_suffix(".csv")
    header = ",".join(param_names + ("log_prob",))
    data = np.column_stack([chain, logp])
    np.savetxt(out_csv, data, delimiter=",", header=header, comments="")
    return out_csv


def run_sampler(args: argparse.Namespace) -> None:
    model_spec = get_model_spec(args.model)
    param_names = model_spec["param_names"]
    theta_bestfit = model_spec["theta_bestfit"]
    init_sigma = model_spec["init_sigma"]
    prior_bounds = model_spec["prior_bounds"]
    n_dim = model_spec["ndim"]

    n_steps = N_STEPS_TEST if args.quick_test else args.n_steps
    n_walkers = args.n_walkers
    if n_walkers < 2 * n_dim:
        raise ValueError(f"n_walkers doit etre >= {2 * n_dim} pour emcee (got {n_walkers}).")

    rng = np.random.default_rng(args.seed)
    p0 = init_walkers(
        n_walkers=n_walkers,
        rng=rng,
        center=theta_bestfit,
        sigma=init_sigma,
        param_names=param_names,
        prior_bounds=prior_bounds,
    )
    backend = make_backend(args.output, n_walkers, args.chain_name, n_dim)

    sampler = emcee.EnsembleSampler(
        nwalkers=n_walkers,
        ndim=n_dim,
        log_prob_fn=log_probability,
        backend=backend,
        args=(args.model, prior_bounds, param_names),
    )

    try:
        from tqdm.auto import tqdm

        state = p0
        with tqdm(total=n_steps, desc="MCMC", unit="step") as pbar:
            for state in sampler.sample(state, iterations=n_steps, progress=False):
                pbar.update(1)
    except Exception:
        sampler.run_mcmc(p0, n_steps, progress=True)

    print("\nSampling termine.")
    print(f"Walkers: {n_walkers} | Steps par walker: {n_steps}")
    print(f"Taux d'acceptation moyen: {np.mean(sampler.acceptance_fraction):.3f}")

    if isinstance(backend, emcee.backends.HDFBackend):
        print(f"Chaines sauvegardees dans: {args.output}")
        print(f"Nom de la chaine HDF5: {args.chain_name}")
    else:
        out_csv = save_csv_fallback(sampler, args.output, param_names)
        print(f"Backend memoire utilise. Export CSV: {out_csv}")

    theta_median, burnin = summarize_bestfit_from_chain(sampler)
    _print_bestfit_report(theta_median, burnin, param_names, args.model)


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    run_sampler(args)


if __name__ == "__main__":
    main()
