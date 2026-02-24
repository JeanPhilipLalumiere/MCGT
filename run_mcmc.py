#!/usr/bin/env python3
"""Run MCGT MCMC with emcee and save chains for later corner-plot usage."""

from __future__ import annotations

import argparse
import importlib.util
import math
from pathlib import Path

import emcee
import numpy as np

PARAM_NAMES = ("Omega_m", "H_0", "w_0", "w_a", "S_8")
NDIM = len(PARAM_NAMES)

# Sampling configuration
N_WALKERS = 32
N_STEPS_DEFAULT = 5000
N_STEPS_TEST = 500
SEED = 42

# Expected best-fit center for initialization
THETA_BESTFIT = np.array([0.30, 70.0, -1.0, 0.0, 0.80], dtype=float)
INIT_SIGMA = np.array([0.01, 0.5, 0.05, 0.10, 0.02], dtype=float)

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


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Run emcee MCMC for MCGT and save chains to disk."
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
        default=Path("output/mcgt_chains.h5"),
        help="Output chain file (.h5 preferred).",
    )
    parser.add_argument(
        "--chain-name",
        type=str,
        default="mcgt_chain",
        help="Dataset group name in HDF5 backend.",
    )
    return parser


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
        "params_template": params_template,
        "sn_data": sn_data,
        "bao_data": bao_data,
    }
    return _TRI_PROBE_RUNTIME


def log_prior(theta: np.ndarray) -> float:
    """Uniform priors on physically viable ranges."""
    omega_m, h_0, w_0, w_a, s_8 = theta
    if not (PRIOR_BOUNDS["Omega_m"][0] < omega_m < PRIOR_BOUNDS["Omega_m"][1]):
        return -math.inf
    if not (PRIOR_BOUNDS["H_0"][0] < h_0 < PRIOR_BOUNDS["H_0"][1]):
        return -math.inf
    if not (PRIOR_BOUNDS["w_0"][0] < w_0 < PRIOR_BOUNDS["w_0"][1]):
        return -math.inf
    if not (PRIOR_BOUNDS["w_a"][0] < w_a < PRIOR_BOUNDS["w_a"][1]):
        return -math.inf
    if not (PRIOR_BOUNDS["S_8"][0] < s_8 < PRIOR_BOUNDS["S_8"][1]):
        return -math.inf
    return 0.0


def pipeline_loglike_from_theta(theta: np.ndarray) -> float:
    """
    Real MCGT tri-probe likelihood (SN+BAO+CMB) from chapter 09 pipeline.

    Source:
      scripts/09_dark_energy_cpl/09_mcmc_sampler.py::log_posterior
    """
    omega_m, h_0, w_0, w_a, s_8 = theta

    runtime = _load_tri_probe_runtime()
    params = dict(runtime["params_template"])
    params["H0"] = float(h_0)
    params["h"] = float(h_0) / 100.0
    params["omega_b"] = params["ombh2"] / (params["h"] * params["h"])

    # S_8 is kept explicit in theta but not constrained by this tri-probe likelihood.
    _ = s_8

    logp, chi2_total, _, _ = runtime["log_posterior"](
        params,
        float(omega_m),
        float(w_0),
        float(w_a),
        runtime["sn_data"],
        runtime["bao_data"],
        TRI_PROBE_SIGMA_SYS,
        TRI_PROBE_N_STEPS_INT,
    )
    if not np.isfinite(logp):
        return -math.inf
    return -0.5 * float(chi2_total)


def log_likelihood(theta: np.ndarray) -> float:
    """Log-likelihood wrapper."""
    return pipeline_loglike_from_theta(theta)


def log_probability(theta: np.ndarray) -> float:
    lp = log_prior(theta)
    if not np.isfinite(lp):
        return -math.inf
    ll = log_likelihood(theta)
    if not np.isfinite(ll):
        return -math.inf
    return lp + ll


def init_walkers(
    n_walkers: int,
    rng: np.random.Generator,
    center: np.ndarray,
    sigma: np.ndarray,
) -> np.ndarray:
    """Initialize walkers in a small Gaussian ball around expected best-fit."""
    p0 = rng.normal(loc=center, scale=sigma, size=(n_walkers, NDIM))
    for j, name in enumerate(PARAM_NAMES):
        lo, hi = PRIOR_BOUNDS[name]
        eps = 1e-6 * (hi - lo)
        p0[:, j] = np.clip(p0[:, j], lo + eps, hi - eps)
    return p0


def make_backend(
    output_file: Path,
    n_walkers: int,
    chain_name: str,
) -> emcee.backends.Backend:
    output_file.parent.mkdir(parents=True, exist_ok=True)
    if output_file.suffix.lower() != ".h5":
        return emcee.backends.Backend()
    try:
        backend = emcee.backends.HDFBackend(str(output_file), name=chain_name)
        backend.reset(n_walkers, NDIM)
        return backend
    except Exception as exc:  # pragma: no cover
        print(f"[warn] HDF5 backend unavailable ({exc}). Falling back to memory backend.")
        return emcee.backends.Backend()


def save_csv_fallback(
    sampler: emcee.EnsembleSampler,
    output_h5: Path,
) -> Path:
    chain = sampler.get_chain(flat=True)
    logp = sampler.get_log_prob(flat=True)
    out_csv = output_h5.with_suffix(".csv")
    header = ",".join(PARAM_NAMES + ("log_prob",))
    data = np.column_stack([chain, logp])
    np.savetxt(out_csv, data, delimiter=",", header=header, comments="")
    return out_csv


def run_sampler(args: argparse.Namespace) -> None:
    n_steps = N_STEPS_TEST if args.quick_test else args.n_steps
    n_walkers = args.n_walkers
    if n_walkers < 2 * NDIM:
        raise ValueError(f"n_walkers doit etre >= {2 * NDIM} pour emcee (got {n_walkers}).")

    rng = np.random.default_rng(args.seed)
    p0 = init_walkers(n_walkers, rng, THETA_BESTFIT, INIT_SIGMA)
    backend = make_backend(args.output, n_walkers, args.chain_name)

    sampler = emcee.EnsembleSampler(
        nwalkers=n_walkers,
        ndim=NDIM,
        log_prob_fn=log_probability,
        backend=backend,
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
        out_csv = save_csv_fallback(sampler, args.output)
        print(f"Backend memoire utilise. Export CSV: {out_csv}")


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    run_sampler(args)


if __name__ == "__main__":
    main()
