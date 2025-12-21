#!/usr/bin/env python3
"""Chapter 09: Tri-probe Metropolis-Hastings sampler (SN+BAO+CMB)."""

from __future__ import annotations

import argparse
import configparser
import json
import logging
import math
from pathlib import Path

import numpy as np

C_KM_S = 299792.458
PLANCK_R = 1.7502
PLANCK_R_SIGMA = 0.0046


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run tri-probe MCMC (SN+BAO+CMB).")
    parser.add_argument(
        "--config",
        default="config/mcgt-global-config.ini",
        help="Path to central INI config.",
    )
    parser.add_argument("--steps", type=int, default=1000)
    parser.add_argument("--seed", type=int, default=1234)
    parser.add_argument("--step-w0", type=float, default=0.03)
    parser.add_argument("--step-wa", type=float, default=0.10)
    parser.add_argument("--step-om", type=float, default=0.01)
    parser.add_argument("--n-steps-int", type=int, default=2500)
    parser.add_argument("--sigma-sys", type=float, default=0.1)
    parser.add_argument("--out", default="assets/zz-data/chapter09/09_mcmc_tri_probe.csv")
    parser.add_argument(
        "--summary",
        default="assets/zz-data/chapter09/09_mcmc_tri_probe_summary.json",
    )
    return parser.parse_args()


def load_config(path: Path) -> dict[str, float]:
    cfg = configparser.ConfigParser(
        interpolation=None, inline_comment_prefixes=("#", ";")
    )
    if not cfg.read(path, encoding="utf-8"):
        raise FileNotFoundError(f"Cannot read config: {path}")

    cmb = cfg["cmb"]
    de = cfg["dark_energy"]
    rad = cfg["radiation"] if "radiation" in cfg else None

    H0 = cmb.getfloat("H0")
    ombh2 = cmb.getfloat("ombh2")
    omch2 = cmb.getfloat("omch2")
    w0 = de.getfloat("w0")
    wa = de.getfloat("wa")

    Tcmb = 2.7255 if rad is None else rad.getfloat("Tcmb_K")
    Neff = 3.046 if rad is None else rad.getfloat("Neff")

    h = H0 / 100.0
    omega_b = ombh2 / (h * h)
    omega_m = (ombh2 + omch2) / (h * h)

    omega_gamma_h2 = 2.469e-5 * (Tcmb / 2.7255) ** 4
    omega_r_h2 = omega_gamma_h2 * (1.0 + 0.2271 * Neff)
    omega_r = omega_r_h2 / (h * h)

    return {
        "H0": H0,
        "h": h,
        "ombh2": ombh2,
        "omch2": omch2,
        "omega_b": omega_b,
        "omega_m": omega_m,
        "omega_r": omega_r,
        "w0": w0,
        "wa": wa,
    }


def load_sn_data(root: Path) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    data = np.loadtxt(root / "assets/zz-data" / "chapter08" / "08_pantheon_data.csv", delimiter=",", skiprows=1)
    z = data[:, 0]
    mu = data[:, 1]
    sigma = data[:, 2]
    return z, mu, sigma


def load_bao_data(root: Path) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    data = np.loadtxt(root / "assets/zz-data" / "chapter08" / "08_bao_data.csv", delimiter=",", skiprows=1)
    z = data[:, 0]
    dv = data[:, 1]
    sigma = data[:, 2]
    return z, dv, sigma


def z_rec_hu_sugiyama(ombh2: float, ommh2: float) -> float:
    g1 = 0.0783 * ombh2 ** -0.238 / (1.0 + 39.5 * ombh2 ** 0.763)
    g2 = 0.560 / (1.0 + 21.1 * ombh2 ** 1.81)
    return 1048.0 * (1.0 + 0.00124 * ombh2 ** -0.738) * (1.0 + g1 * ommh2 ** g2)


def e2_cpl(z: np.ndarray, omega_m: float, omega_r: float, omega_de: float, w0: float, wa: float) -> np.ndarray:
    a = 1.0 / (1.0 + z)
    de_factor = a ** (-3.0 * (1.0 + w0 + wa)) * np.exp(-3.0 * wa * (1.0 - a))
    return omega_m * (1.0 + z) ** 3 + omega_r * (1.0 + z) ** 4 + omega_de * de_factor


def cumulative_integral(z_grid: np.ndarray, f_grid: np.ndarray) -> np.ndarray:
    dz = np.diff(z_grid)
    avg = 0.5 * (f_grid[1:] + f_grid[:-1])
    integ = np.zeros_like(z_grid)
    integ[1:] = np.cumsum(avg * dz)
    return integ


def build_distance_helpers(
    z_max: float,
    params: dict[str, float],
    omega_m: float,
    w0: float,
    wa: float,
    n_steps: int,
) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    omega_r = params["omega_r"]
    omega_de = 1.0 - omega_m - omega_r
    if omega_de <= 0:
        return np.array([0.0, z_max]), np.array([0.0, 0.0]), np.array([1.0, 1.0])
    z_grid = np.linspace(0.0, z_max, n_steps)
    e = np.sqrt(e2_cpl(z_grid, omega_m, omega_r, omega_de, w0, wa))
    inv_e = 1.0 / e
    integral = cumulative_integral(z_grid, inv_e)
    return z_grid, integral, e


def distance_modulus(z: np.ndarray, params: dict[str, float], omega_m: float, w0: float, wa: float, n_steps: int) -> np.ndarray:
    z_max = float(np.max(z))
    z_grid, integral, _ = build_distance_helpers(z_max, params, omega_m, w0, wa, n_steps)
    dc = np.interp(z, z_grid, integral)
    d_m = (C_KM_S / params["H0"]) * dc
    d_l = (1.0 + z) * d_m
    return 5.0 * np.log10(d_l) + 25.0


def dv_distance(z: np.ndarray, params: dict[str, float], omega_m: float, w0: float, wa: float, n_steps: int) -> np.ndarray:
    z_max = float(np.max(z))
    z_grid, integral, e_grid = build_distance_helpers(z_max, params, omega_m, w0, wa, n_steps)
    dc = np.interp(z, z_grid, integral)
    e = np.interp(z, z_grid, e_grid)
    d_m = (C_KM_S / params["H0"]) * dc
    hz = params["H0"] * e
    return (d_m * d_m * (C_KM_S * z) / hz) ** (1.0 / 3.0)


def shift_parameter(params: dict[str, float], omega_m: float, w0: float, wa: float, n_steps: int) -> float:
    h = params["h"]
    ommh2 = omega_m * h * h
    z_rec = z_rec_hu_sugiyama(params["ombh2"], ommh2)
    z_grid, integral, _ = build_distance_helpers(z_rec, params, omega_m, w0, wa, n_steps)
    dc = integral[-1]
    return math.sqrt(omega_m) * dc


def chi2_sn(z: np.ndarray, mu_obs: np.ndarray, sigma_mu: np.ndarray, params: dict[str, float], omega_m: float, w0: float, wa: float, sigma_sys: float, n_steps: int) -> float:
    mu_model = distance_modulus(z, params, omega_m, w0, wa, n_steps)
    sigma = np.sqrt(sigma_mu * sigma_mu + sigma_sys * sigma_sys)
    resid = mu_obs - mu_model
    return float(np.sum((resid / sigma) ** 2))


def chi2_bao(z: np.ndarray, dv_obs: np.ndarray, sigma_dv: np.ndarray, params: dict[str, float], omega_m: float, w0: float, wa: float, n_steps: int) -> float:
    dv_model = dv_distance(z, params, omega_m, w0, wa, n_steps)
    resid = dv_model - dv_obs
    return float(np.sum((resid / sigma_dv) ** 2))


def chi2_cmb(params: dict[str, float], omega_m: float, w0: float, wa: float, n_steps: int) -> float:
    R = shift_parameter(params, omega_m, w0, wa, n_steps)
    return ((R - PLANCK_R) / PLANCK_R_SIGMA) ** 2


def log_likelihood_cmb(params: dict[str, float], config_path: str | Path = "config/mcgt-global-config.ini") -> float:
    """Gaussian log-likelihood from Planck shift-parameter constraint."""
    config = load_config(Path(config_path))
    chi2 = chi2_cmb(config, config["omega_m"], config["w0"], config["wa"], 2500)
    return -0.5 * chi2


def log_posterior(
    params: dict[str, float],
    omega_m: float,
    w0: float,
    wa: float,
    sn_data: tuple[np.ndarray, np.ndarray, np.ndarray],
    bao_data: tuple[np.ndarray, np.ndarray, np.ndarray],
    sigma_sys: float,
    n_steps: int,
) -> tuple[float, float, float, float]:
    omega_b = params["omega_b"]
    if not (omega_b < omega_m < 0.6):
        return -math.inf, math.inf, math.inf, math.inf
    if not (-2.5 < w0 < 0.5):
        return -math.inf, math.inf, math.inf, math.inf
    if not (-3.0 < wa < 3.0):
        return -math.inf, math.inf, math.inf, math.inf

    chi2_sn_val = chi2_sn(*sn_data, params, omega_m, w0, wa, sigma_sys, n_steps)
    chi2_bao_val = chi2_bao(*bao_data, params, omega_m, w0, wa, n_steps)
    chi2_cmb_val = chi2_cmb(params, omega_m, w0, wa, n_steps)

    chi2_total = chi2_sn_val + chi2_bao_val + chi2_cmb_val
    return -0.5 * chi2_total, chi2_total, chi2_sn_val, chi2_bao_val


def run_mcmc(
    params: dict[str, float],
    sn_data: tuple[np.ndarray, np.ndarray, np.ndarray],
    bao_data: tuple[np.ndarray, np.ndarray, np.ndarray],
    steps: int,
    step_sizes: tuple[float, float, float],
    sigma_sys: float,
    n_steps: int,
    seed: int,
) -> tuple[np.ndarray, np.ndarray]:
    rng = np.random.default_rng(seed)
    chain = np.zeros((steps, 6))
    # columns: w0, wa, omega_m, chi2_total, chi2_sn, chi2_bao, chi2_cmb
    chi2_cmb_vals = np.zeros(steps)
    accepted = np.zeros(steps, dtype=int)

    w0 = params["w0"]
    wa = params["wa"]
    omega_m = params["omega_m"]

    logp, chi2_total, chi2_sn_val, chi2_bao_val = log_posterior(
        params, omega_m, w0, wa, sn_data, bao_data, sigma_sys, n_steps
    )
    chi2_cmb_val = chi2_cmb(params, omega_m, w0, wa, n_steps)

    for i in range(steps):
        w0_prop = w0 + rng.normal(0.0, step_sizes[0])
        wa_prop = wa + rng.normal(0.0, step_sizes[1])
        om_prop = omega_m + rng.normal(0.0, step_sizes[2])

        logp_prop, chi2_tot_prop, chi2_sn_prop, chi2_bao_prop = log_posterior(
            params, om_prop, w0_prop, wa_prop, sn_data, bao_data, sigma_sys, n_steps
        )
        if np.isfinite(logp_prop) and math.log(rng.random()) < (logp_prop - logp):
            w0, wa, omega_m = w0_prop, wa_prop, om_prop
            logp = logp_prop
            chi2_total = chi2_tot_prop
            chi2_sn_val = chi2_sn_prop
            chi2_bao_val = chi2_bao_prop
            chi2_cmb_val = chi2_cmb(params, omega_m, w0, wa, n_steps)
            accepted[i] = 1

        chain[i, 0] = w0
        chain[i, 1] = wa
        chain[i, 2] = omega_m
        chain[i, 3] = chi2_total
        chain[i, 4] = chi2_sn_val
        chain[i, 5] = chi2_bao_val
        chi2_cmb_vals[i] = chi2_cmb_val

    return chain, chi2_cmb_vals, accepted


def main() -> int:
    logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")
    args = parse_args()
    root = Path(__file__).resolve().parents[2]

    params = load_config(Path(args.config))
    sn_data = load_sn_data(root)
    bao_data = load_bao_data(root)

    chain, chi2_cmb_vals, accepted = run_mcmc(
        params,
        sn_data,
        bao_data,
        args.steps,
        (args.step_w0, args.step_wa, args.step_om),
        args.sigma_sys,
        args.n_steps_int,
        args.seed,
    )

    chi2_total = chain[:, 3]
    chi2_sn_vals = chain[:, 4]
    chi2_bao_vals = chain[:, 5]
    chi2_no_cmb = chi2_sn_vals + chi2_bao_vals

    best_idx = int(np.argmin(chi2_total))
    best_no_cmb_idx = int(np.argmin(chi2_no_cmb))

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    data = np.column_stack([chain, chi2_cmb_vals, accepted])

    header = "w0,wa,omega_m,chi2_total,chi2_sn,chi2_bao,chi2_cmb,accepted"
    np.savetxt(out_path, data, delimiter=",", header=header, comments="")

    summary = {
        "steps": args.steps,
        "acceptance_rate": float(np.mean(accepted)),
        "best_fit": {
            "w0": float(chain[best_idx, 0]),
            "wa": float(chain[best_idx, 1]),
            "omega_m": float(chain[best_idx, 2]),
            "chi2_total": float(chi2_total[best_idx]),
            "chi2_sn": float(chi2_sn_vals[best_idx]),
            "chi2_bao": float(chi2_bao_vals[best_idx]),
            "chi2_cmb": float(chi2_cmb_vals[best_idx]),
        },
        "best_fit_no_cmb": {
            "w0": float(chain[best_no_cmb_idx, 0]),
            "wa": float(chain[best_no_cmb_idx, 1]),
            "omega_m": float(chain[best_no_cmb_idx, 2]),
            "chi2_sn": float(chi2_sn_vals[best_no_cmb_idx]),
            "chi2_bao": float(chi2_bao_vals[best_no_cmb_idx]),
            "chi2_total_no_cmb": float(chi2_no_cmb[best_no_cmb_idx]),
        },
    }

    summary_path = Path(args.summary)
    summary_path.parent.mkdir(parents=True, exist_ok=True)
    summary_path.write_text(json.dumps(summary, indent=2), encoding="utf-8")

    logging.info("Acceptance rate: %.3f", summary["acceptance_rate"])
    logging.info(
        "Best chi2_total=%.3f (w0=%.4f, wa=%.4f, Omega_m=%.4f)",
        summary["best_fit"]["chi2_total"],
        summary["best_fit"]["w0"],
        summary["best_fit"]["wa"],
        summary["best_fit"]["omega_m"],
    )
    logging.info(
        "Best chi2_no_cmb=%.3f (w0=%.4f, wa=%.4f, Omega_m=%.4f)",
        summary["best_fit_no_cmb"]["chi2_total_no_cmb"],
        summary["best_fit_no_cmb"]["w0"],
        summary["best_fit_no_cmb"]["wa"],
        summary["best_fit_no_cmb"]["omega_m"],
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
