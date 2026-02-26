#!/usr/bin/env python3
"""Export falsifiable Psi-CDM predictions on z in [0, 20]."""

from __future__ import annotations

import argparse
import importlib.util
import math
from pathlib import Path

import emcee
import numpy as np

DEFAULT_CHAIN = Path("output/mcgt_chains.h5")
DEFAULT_CHAIN_NAME = "mcgt_chain"
DEFAULT_OUTPUT = Path("output/psicdm_predictions_z0_to_z20.csv")
DEFAULT_POINTS = 200

# Fallback (v3.0.0-like) if chain is unavailable.
FALLBACK_BESTFIT = {
    "omega_m": 0.30,
    "h_0": 70.0,
    "w_0": -1.0,
    "w_a": 0.0,
    "s_8": 0.80,
}


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Export Psi-CDM predictions from z=0 to z=20.")
    parser.add_argument("--chain", type=Path, default=DEFAULT_CHAIN, help="Input MCMC chain HDF5.")
    parser.add_argument(
        "--chain-name",
        type=str,
        default=DEFAULT_CHAIN_NAME,
        help="Dataset name in HDF5 backend.",
    )
    parser.add_argument(
        "--n-points",
        type=int,
        default=DEFAULT_POINTS,
        help=f"Number of redshift samples (default: {DEFAULT_POINTS}).",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT,
        help="Output CSV path.",
    )
    return parser


def _estimate_burnin(reader: emcee.backends.HDFBackend, burnin_frac: float = 0.30) -> int:
    chain = reader.get_chain()
    n_steps = int(chain.shape[0])
    burnin_fallback = max(1, int(burnin_frac * n_steps))
    try:
        tau = reader.get_autocorr_time(tol=0)
        burnin_tau = int(2.0 * np.max(tau))
        return min(max(burnin_tau, burnin_fallback), max(1, n_steps - 1))
    except Exception:
        return burnin_fallback


def load_bestfit_params(chain_path: Path, chain_name: str) -> tuple[dict[str, float], str]:
    """Load best-fit medians from chain; fallback to fixed values if unavailable."""
    if not chain_path.exists():
        return dict(FALLBACK_BESTFIT), "fallback_constants"

    try:
        reader = emcee.backends.HDFBackend(str(chain_path), name=chain_name)
        burnin = _estimate_burnin(reader)
        samples = reader.get_chain(discard=burnin, flat=True)
        if samples.size == 0:
            samples = reader.get_chain(flat=True)
        med = np.median(samples, axis=0)
        ndim = int(med.shape[0])

        if ndim == 5:
            params = {
                "omega_m": float(med[0]),
                "h_0": float(med[1]),
                "w_0": float(med[2]),
                "w_a": float(med[3]),
                "s_8": float(med[4]),
            }
            return params, f"chain:{chain_path} (ndim=5)"

        if ndim == 4:
            params = {
                "omega_m": float(med[0]),
                "h_0": float(med[1]),
                "w_0": float(med[2]),
                "w_a": 0.0,
                "s_8": float(med[3]),
            }
            return params, f"chain:{chain_path} (ndim=4, w_a fixed to 0)"
    except Exception:
        pass

    return dict(FALLBACK_BESTFIT), "fallback_constants"


def load_growth_module():
    root = Path(__file__).resolve().parent.parent
    module_path = root / "scripts/10_structure_growth/10_rsd_likelihood.py"
    spec = importlib.util.spec_from_file_location("mcgt_rsd_likelihood", module_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Unable to load growth module: {module_path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def compute_hubble(z: np.ndarray, h_0: float, omega_m: float, w_0: float, w_a: float, growth_mod) -> np.ndarray:
    a = 1.0 / (1.0 + z)
    e2 = growth_mod.e2_cpl(a, omega_m, w_0, w_a)
    return h_0 * np.sqrt(e2)


def compute_growth_outputs(
    z: np.ndarray,
    omega_m: float,
    h_0: float,
    w_0: float,
    w_a: float,
    s_8: float,
    growth_mod,
) -> tuple[np.ndarray, np.ndarray]:
    a_grid, delta, ddelta_da = growth_mod.solve_growth_delta(
        omega_m=omega_m,
        h_0=h_0,
        w_0=w_0,
        w_a=w_a,
    )
    f_grid = growth_mod.growth_rate_f(a_grid, delta, ddelta_da)

    a_target = 1.0 / (1.0 + z)
    f_vals = np.interp(a_target, a_grid, f_grid)

    sigma8_0 = s_8 / math.sqrt(omega_m / 0.3)
    sigma8_z = np.interp(a_target, a_grid, sigma8_0 * delta)
    s8_z = sigma8_z * math.sqrt(omega_m / 0.3)
    return f_vals, s8_z


def main() -> int:
    args = build_parser().parse_args()
    if args.n_points < 2:
        raise ValueError("--n-points must be >= 2")

    params_psicdm, source = load_bestfit_params(args.chain, args.chain_name)
    growth_mod = load_growth_module()

    params_lcdm = dict(params_psicdm)
    params_lcdm["w_0"] = -1.0
    params_lcdm["w_a"] = 0.0

    z = np.linspace(0.0, 20.0, int(args.n_points))

    h_psicdm = compute_hubble(
        z,
        params_psicdm["h_0"],
        params_psicdm["omega_m"],
        params_psicdm["w_0"],
        params_psicdm["w_a"],
        growth_mod,
    )
    h_lcdm = compute_hubble(
        z,
        params_lcdm["h_0"],
        params_lcdm["omega_m"],
        params_lcdm["w_0"],
        params_lcdm["w_a"],
        growth_mod,
    )
    f_psicdm, s8_psicdm_z = compute_growth_outputs(
        z,
        params_psicdm["omega_m"],
        params_psicdm["h_0"],
        params_psicdm["w_0"],
        params_psicdm["w_a"],
        params_psicdm["s_8"],
        growth_mod,
    )
    f_lcdm, _ = compute_growth_outputs(
        z,
        params_lcdm["omega_m"],
        params_lcdm["h_0"],
        params_lcdm["w_0"],
        params_lcdm["w_a"],
        params_lcdm["s_8"],
        growth_mod,
    )

    table = np.column_stack([z, h_psicdm, h_lcdm, f_psicdm, f_lcdm, s8_psicdm_z])
    header = "z,H_psicdm,H_lcdm,f_psicdm,f_lcdm,S8_psicdm(z)"

    args.output.parent.mkdir(parents=True, exist_ok=True)
    np.savetxt(args.output, table, delimiter=",", header=header, comments="")

    print(f"[ok] Predictions exported to: {args.output}")
    print(f"[info] Best-fit source: {source}")
    print("[info] First 3 rows:")
    for row in table[:3]:
        print(",".join(f"{float(x):.8f}" for x in row))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
