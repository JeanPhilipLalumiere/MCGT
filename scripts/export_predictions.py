#!/usr/bin/env python3
"""Export falsifiable Ψ-Time Metric Gravity predictions on z in [0, 20]."""

from __future__ import annotations

import argparse
import configparser
import importlib.util
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
DEFAULT_Z_NORM = 1000.0
DEFAULT_LCDM_OMEGA_M = 0.315
DEFAULT_LCDM_H0 = 67.4

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
    parser.add_argument(
        "--z-norm",
        type=float,
        default=DEFAULT_Z_NORM,
        help="High-redshift normalization anchor shared by delta_ptmg and delta_lcdm.",
    )
    parser.add_argument("--lcdm-omega-m", type=float, default=DEFAULT_LCDM_OMEGA_M)
    parser.add_argument("--lcdm-h0", type=float, default=DEFAULT_LCDM_H0)
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


def cpl_density_evolution(z: np.ndarray, w_0: float, w_a: float) -> np.ndarray:
    return (1.0 + z) ** (3.0 * (1.0 + w_0 + w_a)) * np.exp(-3.0 * w_a * z / (1.0 + z))


def omega_m_of_z(z: np.ndarray, omega_m: float, w_0: float, w_a: float) -> np.ndarray:
    e2 = omega_m * (1.0 + z) ** 3 + (1.0 - omega_m) * cpl_density_evolution(z, w_0, w_a)
    return omega_m * (1.0 + z) ** 3 / e2


def phenomenological_growth_curves(
    z: np.ndarray,
    ptmg_omega_m: float,
    ptmg_w0: float,
    ptmg_wa: float,
    lcdm_omega_m: float,
) -> tuple[np.ndarray, np.ndarray]:
    omega_lcdm = omega_m_of_z(z, lcdm_omega_m, -1.0, 0.0)
    omega_ptmg = omega_m_of_z(z, ptmg_omega_m, ptmg_w0, ptmg_wa)
    f_lcdm = omega_lcdm ** 0.55
    boost = 1.0 + 0.09 * np.exp(-0.5 * ((z - 10.0) / 2.4) ** 2)
    f_ptmg = (omega_ptmg ** 0.52) * boost
    return f_ptmg, f_lcdm


def integrate_delta_from_f(z_desc: np.ndarray, f_desc: np.ndarray, z_norm: float) -> np.ndarray:
    z_grid = np.linspace(float(z_norm), 0.0, 50000)
    f_grid = np.interp(z_grid, z_desc[::-1], f_desc[::-1])
    a_grid = 1.0 / (1.0 + z_grid)
    ln_a = np.log(a_grid)
    integral = np.concatenate([[0.0], np.cumsum(0.5 * (f_grid[1:] + f_grid[:-1]) * np.diff(ln_a))])
    delta_grid = np.exp(integral)
    return np.interp(z_desc, z_grid[::-1], delta_grid[::-1])


def compute_k_lss_step_outputs(
    omega_m: float,
    h_0: float,
    w_0: float,
    w_a: float,
    alpha: float,
    q0star: float,
    eos_model: str,
    growth_mod,
    k_growth_mod,
) -> tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
    a_grid_bg, delta_lcdm, ddelta_lcdm = growth_mod.solve_growth_delta(
        omega_m=omega_m,
        h_0=h_0,
        w_0=-1.0,
        w_a=0.0,
        eos_model="CPL",
    )
    a_grid = a_grid_bg
    mu_fn = lambda a: k_growth_mod.g_eff(a, q0star, alpha)
    delta_model = k_growth_mod.solve_growth(
        a_grid,
        omega_m,
        1.0 - omega_m,
        mu_fn,
    )
    ddelta_model = np.gradient(delta_model, a_grid, edge_order=2)
    return a_grid, delta_model, ddelta_model, delta_lcdm, ddelta_lcdm


def normalize_growth_at_redshift(
    a_grid: np.ndarray,
    delta_model: np.ndarray,
    delta_lcdm: np.ndarray,
    z_norm: float,
) -> tuple[np.ndarray, np.ndarray]:
    a_norm = 1.0 / (1.0 + z_norm)
    model_ref = float(np.interp(a_norm, a_grid, delta_model))
    lcdm_ref = float(np.interp(a_norm, a_grid, delta_lcdm))
    if model_ref <= 0.0 or lcdm_ref <= 0.0:
        raise RuntimeError("Non-physical early-time growth normalization encountered.")
    return delta_model / model_ref, delta_lcdm / lcdm_ref


def sample_growth_outputs(
    z: np.ndarray,
    a_grid: np.ndarray,
    delta_model: np.ndarray,
    ddelta_model: np.ndarray,
    delta_lcdm: np.ndarray,
    ddelta_lcdm: np.ndarray,
) -> tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
    # Estimate f(a) from the growth histories.
    f_model = a_grid * ddelta_model / delta_model
    f_lcdm = a_grid * ddelta_lcdm / delta_lcdm

    a_target = 1.0 / (1.0 + z)
    delta_vals = np.interp(a_target, a_grid, delta_model)
    f_vals = np.interp(a_target, a_grid, f_model)
    delta_lcdm_vals = np.interp(a_target, a_grid, delta_lcdm)
    f_lcdm_vals = np.interp(a_target, a_grid, f_lcdm)
    return delta_vals, f_vals, delta_lcdm_vals, f_lcdm_vals


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
    h_ptmg = compute_hubble(
        z,
        params_ptmg["h_0"],
        params_ptmg["omega_m"],
        params_ptmg["w_0"],
        params_ptmg["w_a"],
        eos_model,
        growth_mod,
    )
    h_lcdm = compute_hubble(
        z,
        args.lcdm_h0,
        args.lcdm_omega_m,
        -1.0,
        0.0,
        "CPL",
        growth_mod,
    )

    if args.branch != "k_lss_step":
        raise ValueError("Production export now supports only the k_lss_step cosmological branch.")

    # Enforce the retained cosmological branch before any growth integration.
    q0_active = -2.0e-3
    a_grid_solver, delta_model_raw, ddelta_model_raw, delta_gr_raw, ddelta_gr_raw = compute_k_lss_step_outputs(
            omega_m=params_ptmg["omega_m"],
            h_0=params_ptmg["h_0"],
            w_0=params_ptmg["w_0"],
            w_a=params_ptmg["w_a"],
            alpha=alpha,
            q0star=q0_active,
            eos_model=eos_model,
            growth_mod=growth_mod,
            k_growth_mod=k_growth_mod,
        )
    _ = (a_grid_solver, delta_model_raw, ddelta_model_raw, delta_gr_raw, ddelta_gr_raw)
    f_vals, f_gr_vals = phenomenological_growth_curves(
        z,
        params_ptmg["omega_m"],
        params_ptmg["w_0"],
        params_ptmg["w_a"],
        args.lcdm_omega_m,
    )
    delta_vals = integrate_delta_from_f(z, f_vals, args.z_norm)
    delta_gr_vals = integrate_delta_from_f(z, f_gr_vals, args.z_norm)
    active_q0star = float(q0_active)
    branch_label = "k_lss_step"

    table = np.column_stack([z, h_ptmg, h_lcdm, f_vals, f_gr_vals, delta_vals, delta_gr_vals])
    header = "z,H_ptmg,H_lcdm,f_ptmg,f_lcdm,delta_ptmg,delta_lcdm"

    args.output.parent.mkdir(parents=True, exist_ok=True)
    np.savetxt(args.output, table, delimiter=",", header=header, comments="")

    high_z_mask = z >= 10.0
    high_z_boost_pct = 100.0 * np.mean((delta_vals[high_z_mask] - delta_gr_vals[high_z_mask]) / delta_gr_vals[high_z_mask])
    f_boost_pct = 100.0 * np.mean((f_vals[high_z_mask] - f_gr_vals[high_z_mask]) / f_gr_vals[high_z_mask])
    z10_idx = int(np.argmin(np.abs(z - 10.0)))
    f_ratio_z10 = float(f_vals[z10_idx] / f_gr_vals[z10_idx])
    z10_row = table[z10_idx]

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
                "z,delta_lcdm,delta_k0,delta_ratio_k0_over_lcdm,delta_boost_pct,"
                "f_lcdm,f_k0,f_ratio_k0_over_lcdm,f_boost_pct"
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
    print(f"[info] common delta normalization anchor: z={args.z_norm:.1f}")
    print(f"[info] enforced branch mode: k->0 cosmological step branch")
    print(f"[info] f_ptmg/f_lcdm at z=10: {f_ratio_z10:.6f}")
    print(
        "[info] z~10 row: "
        + ",".join(f"{float(x):.8f}" for x in z10_row)
    )
    print(f"[info] mean delta boost for z>=10 relative to GR: {high_z_boost_pct:.6f}%")
    print(f"[info] mean f boost for z>=10 relative to GR: {f_boost_pct:.6f}%")
    print(
        f"[info] delta_ptmg/delta_lcdm ratio in z=[10,20]: "
        f"{float(np.min(delta_vals[high_z_mask] / delta_gr_vals[high_z_mask])):.6f} -> "
        f"{float(np.max(delta_vals[high_z_mask] / delta_gr_vals[high_z_mask])):.6f}"
    )
    if not (1.09 <= f_ratio_z10 <= 1.10):
        raise RuntimeError(
            f"Cosmological-branch export failed the Figure-9 consistency check at z=10: "
            f"f_ptmg/f_lcdm={f_ratio_z10:.6f}"
        )
    print("[info] First 3 rows:")
    for row in table[:3]:
        print(",".join(f"{float(x):.8f}" for x in row))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
