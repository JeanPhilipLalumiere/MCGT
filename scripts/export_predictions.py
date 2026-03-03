#!/usr/bin/env python3
"""Export falsifiable Ψ-Time Metric Gravity predictions on z in [0, 20]."""

from __future__ import annotations

import argparse
import configparser
import importlib.util
import math
from pathlib import Path

import emcee
import numpy as np

DEFAULT_CHAIN = Path("output/ptmg_chains.h5")
DEFAULT_CHAIN_NAME = "ptmg_chain"
DEFAULT_OUTPUT = Path("zz-zenodo/ptmg_predictions_z0_to_z20.csv")
DEFAULT_COMPARISON_OUTPUT = Path("zz-zenodo/ptmg_growth_comparison_GR_vs_k0.csv")
DEFAULT_CONFIG = Path("config/mcgt-global-config.ini")
DEFAULT_POINTS = 200
DEFAULT_Q0STAR_SAFE = -1.0e-6
DEFAULT_Q0STAR_MAX = -2.0e-3
DEFAULT_ALPHA = 0.50

# Fallback (v3.2.0-like) if chain is unavailable.
FALLBACK_BESTFIT = {
    "omega_m": 0.243,
    "h_0": 72.97,
    "w_0": -0.69,
    "w_a": -2.81,
    "s_8": 0.718,
}


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Export Ψ-Time Metric Gravity predictions from z=0 to z=20.")
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
    parser.add_argument(
        "--eos-model",
        type=str,
        default="CPL",
        help="Dark-energy model passed to the background/growth solver: CPL, JBP, or wCDM.",
    )
    parser.add_argument(
        "--config",
        type=Path,
        default=DEFAULT_CONFIG,
        help="INI configuration used to read the default alpha value.",
    )
    parser.add_argument(
        "--branch",
        type=str,
        default="k_lss_step",
        choices=("universal", "k_lss_step"),
        help="Prediction branch to export.",
    )
    parser.add_argument("--alpha", type=float, default=None, help="Override perturbation alpha.")
    parser.add_argument(
        "--q0star-safe",
        type=float,
        default=DEFAULT_Q0STAR_SAFE,
        help="LIGO-safe branch coupling used outside the cosmological step.",
    )
    parser.add_argument(
        "--q0star-max",
        type=float,
        default=DEFAULT_Q0STAR_MAX,
        help="Cosmological k->0 branch coupling for the Step-Function solution.",
    )
    parser.add_argument(
        "--comparison-output",
        type=Path,
        default=DEFAULT_COMPARISON_OUTPUT,
        help="Optional GR-vs-k0 comparison CSV path.",
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


def load_k_growth_module():
    root = Path(__file__).resolve().parent.parent
    module_path = root / "scripts/11_lss_s8_tension/11_k_dependent_solver.py"
    spec = importlib.util.spec_from_file_location("mcgt_k_growth", module_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Unable to load k-dependent growth module: {module_path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def load_alpha(config_path: Path) -> float:
    if not config_path.exists():
        return DEFAULT_ALPHA
    cfg = configparser.ConfigParser(interpolation=None, inline_comment_prefixes=("#", ";"))
    if not cfg.read(config_path, encoding="utf-8"):
        return DEFAULT_ALPHA
    if "perturbations" not in cfg:
        return DEFAULT_ALPHA
    return cfg["perturbations"].getfloat("alpha", fallback=DEFAULT_ALPHA)


def compute_hubble(
    z: np.ndarray,
    h_0: float,
    omega_m: float,
    w_0: float,
    w_a: float,
    eos_model: str,
    growth_mod,
) -> np.ndarray:
    a = 1.0 / (1.0 + z)
    e2 = growth_mod.e2_cpl(a, omega_m, w_0, w_a, eos_model=eos_model)
    return h_0 * np.sqrt(e2)


def compute_growth_outputs(
    z: np.ndarray,
    omega_m: float,
    h_0: float,
    w_0: float,
    w_a: float,
    s_8: float,
    eos_model: str,
    growth_mod,
) -> tuple[np.ndarray, np.ndarray]:
    a_grid, delta, ddelta_da = growth_mod.solve_growth_delta(
        omega_m=omega_m,
        h_0=h_0,
        w_0=w_0,
        w_a=w_a,
        eos_model=eos_model,
    )
    f_grid = growth_mod.growth_rate_f(a_grid, delta, ddelta_da)

    a_target = 1.0 / (1.0 + z)
    f_vals = np.interp(a_target, a_grid, f_grid)

    sigma8_0 = s_8 / math.sqrt(omega_m / 0.3)
    sigma8_z = np.interp(a_target, a_grid, sigma8_0 * delta)
    s8_z = sigma8_z * math.sqrt(omega_m / 0.3)
    return f_vals, s8_z


def compute_k_lss_step_outputs(
    z: np.ndarray,
    omega_m: float,
    h_0: float,
    w_0: float,
    w_a: float,
    alpha: float,
    q0star: float,
    eos_model: str,
    growth_mod,
    k_growth_mod,
) -> tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
    a_grid_bg, delta_gr, ddelta_gr = growth_mod.solve_growth_delta(
        omega_m=omega_m,
        h_0=h_0,
        w_0=w_0,
        w_a=w_a,
        eos_model=eos_model,
    )
    f_gr = growth_mod.growth_rate_f(a_grid_bg, delta_gr, ddelta_gr)

    a_grid = a_grid_bg
    mu_fn = lambda a: k_growth_mod.g_eff(a, q0star, alpha)
    delta_model = k_growth_mod.solve_growth(
        a_grid,
        omega_m,
        1.0 - omega_m,
        mu_fn,
    )
    delta_model /= float(delta_model[-1])

    # Estimate f(a) from the normalized growth history.
    ddelta_da = np.gradient(delta_model, a_grid, edge_order=2)
    f_model = a_grid * ddelta_da / delta_model

    a_target = 1.0 / (1.0 + z)
    delta_vals = np.interp(a_target, a_grid, delta_model)
    f_vals = np.interp(a_target, a_grid, f_model)
    delta_gr_vals = np.interp(a_target, a_grid, delta_gr)
    f_gr_vals = np.interp(a_target, a_grid, f_gr)
    return delta_vals, f_vals, delta_gr_vals, f_gr_vals


def main() -> int:
    args = build_parser().parse_args()
    if args.n_points < 2:
        raise ValueError("--n-points must be >= 2")

    params_ptmg, source = load_bestfit_params(args.chain, args.chain_name)
    growth_mod = load_growth_module()
    k_growth_mod = load_k_growth_module()
    eos_model = growth_mod._normalize_eos_model(args.eos_model)
    alpha = load_alpha(args.config) if args.alpha is None else float(args.alpha)

    z = np.linspace(0.0, 20.0, int(args.n_points))
    h_vals = compute_hubble(
        z,
        params_ptmg["h_0"],
        params_ptmg["omega_m"],
        params_ptmg["w_0"],
        params_ptmg["w_a"],
        eos_model,
        growth_mod,
    )

    if args.branch == "universal":
        f_vals, _ = compute_growth_outputs(
            z,
            params_ptmg["omega_m"],
            params_ptmg["h_0"],
            params_ptmg["w_0"],
            params_ptmg["w_a"],
            params_ptmg["s_8"],
            eos_model,
            growth_mod,
        )
        a_grid, delta_norm, _ = growth_mod.solve_growth_delta(
            omega_m=params_ptmg["omega_m"],
            h_0=params_ptmg["h_0"],
            w_0=params_ptmg["w_0"],
            w_a=params_ptmg["w_a"],
            eos_model=eos_model,
        )
        delta_vals = np.interp(1.0 / (1.0 + z), a_grid, delta_norm)
        delta_gr_vals = delta_vals.copy()
        f_gr_vals = f_vals.copy()
        active_q0star = 0.0
        branch_label = "universal"
    else:
        delta_vals, f_vals, delta_gr_vals, f_gr_vals = compute_k_lss_step_outputs(
            z=z,
            omega_m=params_ptmg["omega_m"],
            h_0=params_ptmg["h_0"],
            w_0=params_ptmg["w_0"],
            w_a=params_ptmg["w_a"],
            alpha=alpha,
            q0star=args.q0star_max,
            eos_model=eos_model,
            growth_mod=growth_mod,
            k_growth_mod=k_growth_mod,
        )
        active_q0star = float(args.q0star_max)
        branch_label = "k_lss_step"

    table = np.column_stack([z, h_vals, f_vals, delta_vals])
    header = "z,H(z),f(z),delta(z)"

    args.output.parent.mkdir(parents=True, exist_ok=True)
    np.savetxt(args.output, table, delimiter=",", header=header, comments="")

    high_z_mask = z >= 10.0
    high_z_boost_pct = 100.0 * np.mean((delta_vals[high_z_mask] - delta_gr_vals[high_z_mask]) / delta_gr_vals[high_z_mask])
    f_boost_pct = 100.0 * np.mean((f_vals[high_z_mask] - f_gr_vals[high_z_mask]) / f_gr_vals[high_z_mask])

    if args.comparison_output:
        args.comparison_output.parent.mkdir(parents=True, exist_ok=True)
        delta_ratio = delta_vals / delta_gr_vals
        f_ratio = f_vals / f_gr_vals
        comparison = np.column_stack(
            [
                z,
                delta_gr_vals,
                delta_vals,
                delta_ratio,
                100.0 * (delta_ratio - 1.0),
                f_gr_vals,
                f_vals,
                f_ratio,
                100.0 * (f_ratio - 1.0),
            ]
        )
        np.savetxt(
            args.comparison_output,
            comparison,
            delimiter=",",
            header=(
                "z,delta_gr,delta_k0,delta_ratio_k0_over_gr,delta_boost_pct,"
                "f_gr,f_k0,f_ratio_k0_over_gr,f_boost_pct"
            ),
            comments="",
        )

    print(f"[ok] Predictions exported to: {args.output}")
    if args.comparison_output:
        print(f"[ok] Growth comparison exported to: {args.comparison_output}")
    print(f"[info] Best-fit source: {source}")
    print(f"[info] eos_model: {eos_model}")
    print(f"[info] branch: {branch_label}")
    print(f"[info] alpha: {alpha:.6f}")
    print(f"[info] q0*_safe (inactive in k->0 branch export): {args.q0star_safe:.6e}")
    print(f"[info] q0*_active: {active_q0star:.6e}")
    print(f"[info] mean delta boost for z>=10 relative to GR: {high_z_boost_pct:.6f}%")
    print(f"[info] mean f boost for z>=10 relative to GR: {f_boost_pct:.6f}%")
    if high_z_boost_pct < 15.0:
        print(
            "[warn] The validated k->0 Step-Function branch does not exceed the exported "
            "JWST-scale 9-10% high-z growth excess and remains close to the GR history."
        )
    print("[info] First 3 rows:")
    for row in table[:3]:
        print(",".join(f"{float(x):.8f}" for x in row))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
