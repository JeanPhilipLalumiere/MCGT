#!/usr/bin/env python3
"""Fast-track global MCMC for TIDE v3.3 (SN + BAO + CMB distance prior)."""

from __future__ import annotations

import argparse
import configparser
import math
from pathlib import Path

import corner
import emcee
import h5py
import matplotlib.pyplot as plt
import numpy as np
from scipy.optimize import minimize

from tide_psi_bridge import TidePsiBridge

C_KM_S = 299792.458
PLANCK_R = 1.7502
PLANCK_R_SIGMA = 0.0046


def cumulative_integral(z_grid: np.ndarray, f_grid: np.ndarray) -> np.ndarray:
    dz = np.diff(z_grid)
    avg = 0.5 * (f_grid[1:] + f_grid[:-1])
    integ = np.zeros_like(z_grid)
    integ[1:] = np.cumsum(avg * dz)
    return integ


def z_rec_hu_sugiyama(ombh2: float, ommh2: float) -> float:
    g1 = 0.0783 * ombh2 ** -0.238 / (1.0 + 39.5 * ombh2 ** 0.763)
    g2 = 0.560 / (1.0 + 21.1 * ombh2 ** 1.81)
    return 1048.0 * (1.0 + 0.00124 * ombh2 ** -0.738) * (1.0 + g1 * ommh2 ** g2)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run TIDE v3.3 fast-track emcee pipeline.")
    parser.add_argument("--n-walkers", type=int, default=32)
    parser.add_argument("--n-steps", type=int, default=2000)
    parser.add_argument("--burn-in", type=int, default=500)
    parser.add_argument("--seed", type=int, default=20260305)
    parser.add_argument("--n-steps-int", type=int, default=2500)
    parser.add_argument("--sigma-sys", type=float, default=0.1)
    return parser.parse_args()


def load_config(root: Path) -> dict[str, float]:
    cfg = configparser.ConfigParser(interpolation=None, inline_comment_prefixes=("#", ";"))
    cfg_path = root / "config" / "mcgt-global-config.ini"
    if not cfg.read(cfg_path, encoding="utf-8"):
        raise FileNotFoundError(f"Cannot read config: {cfg_path}")

    cmb = cfg["cmb"]
    rad = cfg["radiation"] if "radiation" in cfg else None
    h0_cfg = cmb.getfloat("H0")
    ombh2 = cmb.getfloat("ombh2")
    omch2 = cmb.getfloat("omch2")
    t_cmb = 2.7255 if rad is None else rad.getfloat("Tcmb_K")
    n_eff = 3.046 if rad is None else rad.getfloat("Neff")
    h = h0_cfg / 100.0

    omega_gamma_h2 = 2.469e-5 * (t_cmb / 2.7255) ** 4
    omega_r_h2 = omega_gamma_h2 * (1.0 + 0.2271 * n_eff)
    omega_r = omega_r_h2 / (h * h)

    return {
        "H0": h0_cfg,
        "ombh2": ombh2,
        "omch2": omch2,
        "omega_r": omega_r,
    }


class TideLikelihood:
    def __init__(self, root: Path, bridge: TidePsiBridge, n_steps_int: int, sigma_sys: float) -> None:
        self.root = root
        self.bridge = bridge
        self.n_steps_int = int(n_steps_int)
        self.sigma_sys = float(sigma_sys)
        self.cfg = load_config(root)

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
        self.sn_z, self.sn_mu_obs, self.sn_sigma = sn_raw[:, 0], sn_raw[:, 1], sn_raw[:, 2]
        self.bao_z, self.bao_dv_obs, self.bao_sigma = bao_raw[:, 0], bao_raw[:, 1], bao_raw[:, 2]
        self.n_data = int(self.sn_z.size + self.bao_z.size + 1)

    def _de_factor_tide(self, z_grid: np.ndarray, tau0_gyr: float) -> np.ndarray:
        a = 1.0 / (1.0 + z_grid)
        a_eff = self.bridge.a_vac * (tau0_gyr / 1.8)
        w = -1.0 - (a_eff * a ** (-1.5)) / np.sqrt(1.0 + self.bridge.alpha * a ** (-3.0))
        integrand = (1.0 + w) / (1.0 + z_grid)
        integ = cumulative_integral(z_grid, integrand)
        return np.exp(3.0 * integ)

    def _build_helpers_tide(
        self, h0: float, omega_m: float, tau0_gyr: float, z_max: float
    ) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
        omega_r = self.cfg["omega_r"]
        omega_de = 1.0 - omega_m - omega_r
        if omega_de <= 0.0:
            return np.array([0.0, z_max]), np.array([0.0, 0.0]), np.array([1.0, 1.0])

        z_grid = np.linspace(0.0, z_max, self.n_steps_int)
        de_factor = self._de_factor_tide(z_grid, tau0_gyr=tau0_gyr)
        e2 = omega_m * (1.0 + z_grid) ** 3 + omega_r * (1.0 + z_grid) ** 4 + omega_de * de_factor
        if np.any(e2 <= 0.0) or np.any(~np.isfinite(e2)):
            return np.array([0.0, z_max]), np.array([0.0, 0.0]), np.array([1.0, 1.0])
        e = np.sqrt(e2)
        integral = cumulative_integral(z_grid, 1.0 / e)
        return z_grid, integral, e

    def _build_helpers_lcdm(
        self, h0: float, omega_m: float, z_max: float
    ) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
        omega_r = self.cfg["omega_r"]
        omega_de = 1.0 - omega_m - omega_r
        if omega_de <= 0.0:
            return np.array([0.0, z_max]), np.array([0.0, 0.0]), np.array([1.0, 1.0])
        z_grid = np.linspace(0.0, z_max, self.n_steps_int)
        e2 = omega_m * (1.0 + z_grid) ** 3 + omega_r * (1.0 + z_grid) ** 4 + omega_de
        e = np.sqrt(e2)
        integral = cumulative_integral(z_grid, 1.0 / e)
        return z_grid, integral, e

    @staticmethod
    def _distance_modulus(z: np.ndarray, h0: float, z_grid: np.ndarray, dc_grid: np.ndarray) -> np.ndarray:
        dc = np.interp(z, z_grid, dc_grid)
        d_m = (C_KM_S / h0) * dc
        d_l = (1.0 + z) * d_m
        return 5.0 * np.log10(d_l) + 25.0

    @staticmethod
    def _dv_distance(
        z: np.ndarray, h0: float, z_grid: np.ndarray, dc_grid: np.ndarray, e_grid: np.ndarray
    ) -> np.ndarray:
        dc = np.interp(z, z_grid, dc_grid)
        e = np.interp(z, z_grid, e_grid)
        d_m = (C_KM_S / h0) * dc
        hz = h0 * e
        return (d_m * d_m * (C_KM_S * z) / hz) ** (1.0 / 3.0)

    def chi2_tide(self, omega_m: float, h0: float, tau0_gyr: float) -> float:
        ombh2 = self.cfg["ombh2"]
        h = h0 / 100.0
        z_rec = z_rec_hu_sugiyama(ombh2, omega_m * h * h)
        z_max = float(max(np.max(self.sn_z), np.max(self.bao_z), z_rec))
        z_grid, dc_grid, e_grid = self._build_helpers_tide(h0, omega_m, tau0_gyr, z_max)

        mu_model = self._distance_modulus(self.sn_z, h0, z_grid, dc_grid)
        sig = np.sqrt(self.sn_sigma * self.sn_sigma + self.sigma_sys * self.sigma_sys)
        chi2_sn = np.sum(((self.sn_mu_obs - mu_model) / sig) ** 2)

        dv_model = self._dv_distance(self.bao_z, h0, z_grid, dc_grid, e_grid)
        chi2_bao = np.sum(((dv_model - self.bao_dv_obs) / self.bao_sigma) ** 2)

        dc_rec = float(np.interp(z_rec, z_grid, dc_grid))
        r_shift = math.sqrt(omega_m) * dc_rec
        chi2_cmb = ((r_shift - PLANCK_R) / PLANCK_R_SIGMA) ** 2
        return float(chi2_sn + chi2_bao + chi2_cmb)

    def chi2_lcdm(self, omega_m: float, h0: float) -> float:
        ombh2 = self.cfg["ombh2"]
        h = h0 / 100.0
        z_rec = z_rec_hu_sugiyama(ombh2, omega_m * h * h)
        z_max = float(max(np.max(self.sn_z), np.max(self.bao_z), z_rec))
        z_grid, dc_grid, e_grid = self._build_helpers_lcdm(h0, omega_m, z_max)

        mu_model = self._distance_modulus(self.sn_z, h0, z_grid, dc_grid)
        sig = np.sqrt(self.sn_sigma * self.sn_sigma + self.sigma_sys * self.sigma_sys)
        chi2_sn = np.sum(((self.sn_mu_obs - mu_model) / sig) ** 2)

        dv_model = self._dv_distance(self.bao_z, h0, z_grid, dc_grid, e_grid)
        chi2_bao = np.sum(((dv_model - self.bao_dv_obs) / self.bao_sigma) ** 2)

        dc_rec = float(np.interp(z_rec, z_grid, dc_grid))
        r_shift = math.sqrt(omega_m) * dc_rec
        chi2_cmb = ((r_shift - PLANCK_R) / PLANCK_R_SIGMA) ** 2
        return float(chi2_sn + chi2_bao + chi2_cmb)

    def log_prior(self, theta: np.ndarray) -> float:
        omega_m, h0, tau0 = theta
        if not (0.10 < omega_m < 0.50):
            return -np.inf
        if not (60.0 < h0 < 85.0):
            return -np.inf
        if not (1.0 < tau0 < 3.0):
            return -np.inf
        omega_r = self.cfg["omega_r"]
        if 1.0 - omega_m - omega_r <= 0.0:
            return -np.inf
        return 0.0

    def log_prob(self, theta: np.ndarray) -> float:
        lp = self.log_prior(theta)
        if not np.isfinite(lp):
            return -np.inf
        chi2 = self.chi2_tide(theta[0], theta[1], theta[2])
        if not np.isfinite(chi2):
            return -np.inf
        return lp - 0.5 * chi2


def main() -> int:
    args = parse_args()
    root = Path(__file__).resolve().parents[2]
    out_dir = Path(__file__).resolve().parent / "outputs"
    out_dir.mkdir(parents=True, exist_ok=True)

    bridge = TidePsiBridge(outputs_dir=out_dir)
    engine = TideLikelihood(root=root, bridge=bridge, n_steps_int=args.n_steps_int, sigma_sys=args.sigma_sys)

    ndim = 3
    if args.n_walkers < 2 * ndim:
        raise ValueError("n_walkers must satisfy emcee rule n_walkers >= 2 * ndim.")
    if args.burn_in >= args.n_steps:
        raise ValueError("burn-in must be strictly smaller than n-steps.")

    chain_path = out_dir / "tide_v3_3_chain.h5"
    if chain_path.exists():
        chain_path.unlink()
    backend = emcee.backends.HDFBackend(str(chain_path), name="tide_v3_3_chain")
    backend.reset(args.n_walkers, ndim)

    rng = np.random.default_rng(args.seed)
    center = np.array([bridge.omega_m0, bridge.h0, 1.8], dtype=float)
    scales = np.array([0.01, 0.4, 0.05], dtype=float)
    p0 = center + scales * rng.normal(size=(args.n_walkers, ndim))
    p0[:, 0] = np.clip(p0[:, 0], 0.11, 0.49)
    p0[:, 1] = np.clip(p0[:, 1], 60.2, 84.8)
    p0[:, 2] = np.clip(p0[:, 2], 1.02, 2.98)

    print("MCMC TIDE v3.3 INITIALIZED")
    sampler = emcee.EnsembleSampler(args.n_walkers, ndim, engine.log_prob, backend=backend)
    sampler.run_mcmc(p0, args.n_steps, progress=True)

    chain = backend.get_chain(discard=args.burn_in, flat=True)
    lnp = backend.get_log_prob(discard=args.burn_in, flat=True)
    if chain.size == 0:
        raise RuntimeError("No post-burnin samples available.")

    best_idx = int(np.argmax(lnp))
    best_theta = chain[best_idx]
    chi2_tide_best = engine.chi2_tide(best_theta[0], best_theta[1], best_theta[2])

    # Baseline LCDM reference (same data vector, no tau0 parameter).
    def obj_lcdm(x: np.ndarray) -> float:
        return engine.chi2_lcdm(omega_m=float(x[0]), h0=float(x[1]))

    opt = minimize(
        obj_lcdm,
        x0=np.array([0.30, 70.0]),
        bounds=[(0.10, 0.50), (60.0, 85.0)],
        method="L-BFGS-B",
    )
    if opt.success and np.isfinite(opt.fun):
        chi2_lcdm_best = float(opt.fun)
        lcdm_best = np.array(opt.x, dtype=float)
    else:
        # fallback coarse scan
        om_grid = np.linspace(0.15, 0.45, 80)
        h0_grid = np.linspace(62.0, 82.0, 80)
        chi2_min = np.inf
        lcdm_best = np.array([0.3, 70.0], dtype=float)
        for om in om_grid:
            for h0 in h0_grid:
                chi2 = engine.chi2_lcdm(float(om), float(h0))
                if chi2 < chi2_min:
                    chi2_min = chi2
                    lcdm_best[:] = (om, h0)
        chi2_lcdm_best = float(chi2_min)

    bic_tide = chi2_tide_best + 3 * math.log(engine.n_data)
    bic_lcdm = chi2_lcdm_best + 2 * math.log(engine.n_data)
    delta_bic = bic_tide - bic_lcdm

    fig = corner.corner(
        chain,
        labels=[r"$\Omega_m$", r"$H_0$", r"$\tau_0$ [Gyr]"],
        truths=best_theta,
        show_titles=True,
        title_fmt=".4f",
    )
    corner_path = out_dir / "tide_v3_3_corner.pdf"
    fig.savefig(corner_path, dpi=180)
    plt.close(fig)

    stats_path = out_dir / "tide_v3_3_global_stats.txt"
    stats_lines = [
        "TIDE v3.3 global MCMC stats (SN + BAO + CMB prior)",
        f"n_walkers: {args.n_walkers}",
        f"n_steps: {args.n_steps}",
        f"burn_in: {args.burn_in}",
        f"n_data: {engine.n_data}",
        f"acceptance_fraction_mean: {float(np.mean(sampler.acceptance_fraction)):.6f}",
        "",
        "Best-fit TIDE parameters (post burn-in max log posterior):",
        f"Omega_m: {best_theta[0]:.6f}",
        f"H0: {best_theta[1]:.6f}",
        f"tau0_gyr: {best_theta[2]:.6f}",
        f"chi2_tide_best: {chi2_tide_best:.6f}",
        "",
        "Best-fit LCDM reference (same probes):",
        f"Omega_m_lcdm: {lcdm_best[0]:.6f}",
        f"H0_lcdm: {lcdm_best[1]:.6f}",
        f"chi2_lcdm_best: {chi2_lcdm_best:.6f}",
        "",
        f"BIC_tide (k=3): {bic_tide:.6f}",
        f"BIC_lcdm (k=2): {bic_lcdm:.6f}",
        f"Delta_BIC = BIC_tide - BIC_lcdm: {delta_bic:.6f}",
    ]
    stats_path.write_text("\n".join(stats_lines) + "\n", encoding="utf-8")

    # Store quick metadata in HDF5 for traceability.
    with h5py.File(chain_path, "a") as h5:
        grp = h5.require_group("tide_v3_3_meta")
        grp.attrs["n_data"] = engine.n_data
        grp.attrs["bic_tide"] = bic_tide
        grp.attrs["bic_lcdm"] = bic_lcdm
        grp.attrs["delta_bic"] = delta_bic

    print(f"Saved chain: {chain_path}")
    print(f"Saved corner: {corner_path}")
    print(f"Saved stats: {stats_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
