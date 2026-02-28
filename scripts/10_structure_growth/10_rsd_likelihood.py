#!/usr/bin/env python3
"""Chapter 10: RSD likelihood for constraining S_8 via f*sigma8(z)."""

from __future__ import annotations

import argparse
import configparser
import math
from pathlib import Path

import numpy as np
from scipy.integrate import solve_ivp

DEFAULT_DATA = Path("assets/zz-data/10_structure_growth/10_rsd_data.csv")
DEFAULT_CONFIG = Path("config/mcgt-global-config.ini")


def _normalize_eos_model(eos_model: str) -> str:
    model = eos_model.strip()
    if model.lower() == "cpl":
        return "CPL"
    if model.lower() == "jbp":
        return "JBP"
    if model.lower() == "wcdm":
        return "wCDM"
    raise ValueError(f"Unsupported eos_model={eos_model!r}. Expected CPL, JBP, or wCDM.")


def _effective_wa(w_a: float, eos_model: str) -> float:
    return 0.0 if _normalize_eos_model(eos_model) == "wCDM" else w_a


def w_of_a(
    a: np.ndarray | float,
    w_0: float,
    w_a: float,
    eos_model: str = "CPL",
) -> np.ndarray | float:
    """Dark-energy equation of state w(a) for the supported background models."""
    a_arr = np.asarray(a, dtype=float)
    model = _normalize_eos_model(eos_model)
    w_a_eff = _effective_wa(w_a, model)
    if model == "CPL":
        return w_0 + w_a_eff * (1.0 - a_arr)
    if model == "JBP":
        return w_0 + w_a_eff * a_arr * (1.0 - a_arr)
    return np.full_like(a_arr, w_0, dtype=float)


def de_density_factor(
    a: np.ndarray | float,
    w_0: float,
    w_a: float,
    eos_model: str = "CPL",
) -> np.ndarray | float:
    """rho_de(a) / rho_de(a=1) for the supported dark-energy models."""
    a_arr = np.asarray(a, dtype=float)
    model = _normalize_eos_model(eos_model)
    w_a_eff = _effective_wa(w_a, model)
    if model == "CPL":
        return a_arr ** (-3.0 * (1.0 + w_0 + w_a_eff)) * np.exp(-3.0 * w_a_eff * (1.0 - a_arr))
    if model == "JBP":
        return a_arr ** (-3.0 * (1.0 + w_0)) * np.exp(1.5 * w_a_eff * (a_arr - 1.0) ** 2)
    return a_arr ** (-3.0 * (1.0 + w_0))


def e2_cpl(
    a: np.ndarray | float,
    omega_m: float,
    w_0: float,
    w_a: float,
    eos_model: str = "CPL",
) -> np.ndarray | float:
    """E(a)^2 = H(a)^2/H0^2 in flat dark-energy cosmology."""
    a_arr = np.asarray(a, dtype=float)
    omega_de = 1.0 - omega_m
    de = de_density_factor(a_arr, w_0, w_a, eos_model=eos_model)
    return omega_m * a_arr ** -3 + omega_de * de


def dlnh_da(a: float, omega_m: float, w_0: float, w_a: float, eos_model: str = "CPL") -> float:
    """Derivative d ln(H)/da."""
    e2 = float(e2_cpl(a, omega_m, w_0, w_a, eos_model=eos_model))
    if e2 <= 0:
        return 0.0
    omega_de = 1.0 - omega_m
    de = float(de_density_factor(a, w_0, w_a, eos_model=eos_model))
    dln_de_da = -3.0 * (1.0 + float(w_of_a(a, w_0, w_a, eos_model=eos_model))) / a
    de_prime = omega_de * de * dln_de_da
    e2_prime = -3.0 * omega_m * a ** -4 + de_prime
    return 0.5 * e2_prime / e2


def _growth_ode(
    a: float,
    y: np.ndarray,
    omega_m: float,
    w_0: float,
    w_a: float,
    eos_model: str = "CPL",
) -> np.ndarray:
    """Linear growth ODE in scale factor a for y=[delta, d(delta)/da]."""
    delta, ddelta_da = y
    e2 = float(e2_cpl(a, omega_m, w_0, w_a, eos_model=eos_model))
    if e2 <= 0:
        return np.array([ddelta_da, 0.0], dtype=float)

    source = 1.5 * omega_m / (a ** 5 * e2)
    friction = 3.0 / a + dlnh_da(a, omega_m, w_0, w_a, eos_model=eos_model)
    d2delta_da2 = -friction * ddelta_da + source * delta
    return np.array([ddelta_da, d2delta_da2], dtype=float)


def solve_growth_delta(
    omega_m: float,
    h_0: float,
    w_0: float,
    w_a: float,
    eos_model: str = "CPL",
    a_min: float = 1.0e-3,
    n_grid: int = 4000,
) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    """
    Solve linear matter growth for delta(a).

    h_0 is kept explicit for API consistency with cosmological parameter sets.
    """
    _ = h_0
    a_grid = np.geomspace(a_min, 1.0, n_grid)

    y0 = np.array([a_min, 1.0], dtype=float)
    sol = solve_ivp(
        fun=lambda a, y: _growth_ode(a, y, omega_m, w_0, w_a, eos_model=eos_model),
        t_span=(a_min, 1.0),
        y0=y0,
        t_eval=a_grid,
        method="RK45",
        rtol=1e-7,
        atol=1e-9,
    )
    if not sol.success:
        raise RuntimeError(f"Growth ODE failed: {sol.message}")

    delta = sol.y[0]
    ddelta_da = sol.y[1]

    # Normalize growth to delta(a=1)=1 for stable sigma8(z) scaling.
    delta0 = float(delta[-1])
    if delta0 <= 0:
        raise RuntimeError("Non-physical growth solution: delta(a=1) <= 0")

    delta_norm = delta / delta0
    ddelta_da_norm = ddelta_da / delta0
    return a_grid, delta_norm, ddelta_da_norm


def growth_rate_f(a: np.ndarray, delta: np.ndarray, ddelta_da: np.ndarray) -> np.ndarray:
    """f(a) = d ln(delta)/d ln(a) = a/delta * ddelta/da."""
    return a * ddelta_da / delta


def fsigma8_theory(
    z: np.ndarray,
    omega_m: float,
    h_0: float,
    w_0: float,
    w_a: float,
    sigma_8_0: float,
    eos_model: str = "CPL",
) -> np.ndarray:
    """Compute theoretical f*sigma8(z)."""
    a_grid, delta, ddelta_da = solve_growth_delta(omega_m, h_0, w_0, w_a, eos_model=eos_model)
    f_grid = growth_rate_f(a_grid, delta, ddelta_da)
    sigma8_grid = sigma_8_0 * delta
    fs8_grid = f_grid * sigma8_grid

    a_target = 1.0 / (1.0 + np.asarray(z, dtype=float))
    return np.interp(a_target, a_grid, fs8_grid)


def load_rsd_data(path: Path = DEFAULT_DATA) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    """Load RSD data columns: z, fsigma8, erreur (or error)."""
    if not path.exists():
        raise FileNotFoundError(f"RSD data file not found: {path}")

    data = np.genfromtxt(path, delimiter=",", names=True, dtype=float, encoding="utf-8")
    names = set(data.dtype.names or ())
    if "z" not in names or "fsigma8" not in names:
        raise ValueError(f"Missing required columns in {path}: expected z, fsigma8")

    if "erreur" in names:
        err = data["erreur"]
    elif "error" in names:
        err = data["error"]
    elif "sigma" in names:
        err = data["sigma"]
    else:
        raise ValueError(f"Missing uncertainty column in {path}: expected erreur|error|sigma")

    z = np.asarray(data["z"], dtype=float)
    fs8 = np.asarray(data["fsigma8"], dtype=float)
    err = np.asarray(err, dtype=float)
    if np.any(err <= 0):
        raise ValueError("RSD uncertainties must be strictly positive.")
    return z, fs8, err


def get_chi2_rsd(
    omega_m: float,
    w_0: float,
    w_a: float,
    sigma_8_0: float,
    h_0: float = 70.0,
    data_path: str | Path = DEFAULT_DATA,
    eos_model: str = "CPL",
) -> float:
    """Return chi2_RSD for f*sigma8 data against MCGT theoretical prediction."""
    z, fs8_obs, fs8_err = load_rsd_data(Path(data_path))
    fs8_th = fsigma8_theory(z, omega_m, h_0, w_0, w_a, sigma_8_0, eos_model=eos_model)
    chi2 = np.sum(((fs8_obs - fs8_th) / fs8_err) ** 2)
    return float(chi2)


def load_params_from_config(config_path: Path) -> dict[str, float | str]:
    cfg = configparser.ConfigParser(interpolation=None, inline_comment_prefixes=("#", ";"))
    if not cfg.read(config_path, encoding="utf-8"):
        raise FileNotFoundError(f"Cannot read config: {config_path}")

    cmb = cfg["cmb"]
    de = cfg["dark_energy"]

    h_0 = cmb.getfloat("H0")
    h = h_0 / 100.0
    omega_m = (cmb.getfloat("ombh2") + cmb.getfloat("omch2")) / (h * h)

    sigma_8_0 = 0.80
    if "lss" in cfg and "sigma8" in cfg["lss"]:
        sigma_8_0 = cfg["lss"].getfloat("sigma8")

    return {
        "omega_m": omega_m,
        "h_0": h_0,
        "w_0": de.getfloat("w0"),
        "w_a": de.getfloat("wa"),
        "sigma_8_0": sigma_8_0,
        "eos_model": _normalize_eos_model(de.get("eos_model", fallback="CPL")),
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Compute chi2 for RSD f*sigma8 data.")
    parser.add_argument("--data", type=Path, default=DEFAULT_DATA, help="RSD CSV data path")
    parser.add_argument("--config", type=Path, default=DEFAULT_CONFIG, help="INI config path")
    parser.add_argument("--omega-m", type=float, help="Override Omega_m")
    parser.add_argument("--h0", type=float, help="Override H_0 [km s^-1 Mpc^-1]")
    parser.add_argument("--w0", type=float, help="Override w_0")
    parser.add_argument("--wa", type=float, help="Override w_a")
    parser.add_argument("--sigma8", type=float, help="Override sigma_8(z=0)")
    parser.add_argument("--eos-model", type=str, default=None, help="Dark-energy model: CPL, JBP, or wCDM")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    params = load_params_from_config(args.config)

    omega_m = params["omega_m"] if args.omega_m is None else float(args.omega_m)
    h_0 = params["h_0"] if args.h0 is None else float(args.h0)
    w_0 = params["w_0"] if args.w0 is None else float(args.w0)
    w_a = params["w_a"] if args.wa is None else float(args.wa)
    sigma_8_0 = params["sigma_8_0"] if args.sigma8 is None else float(args.sigma8)
    eos_model = params["eos_model"] if args.eos_model is None else _normalize_eos_model(args.eos_model)

    chi2 = get_chi2_rsd(
        omega_m=omega_m,
        w_0=w_0,
        w_a=w_a,
        sigma_8_0=sigma_8_0,
        h_0=h_0,
        data_path=args.data,
        eos_model=eos_model,
    )

    print(f"RSD chi2 = {chi2:.6f}")
    print(
        "Parameters: "
        f"Omega_m={omega_m:.5f}, H_0={h_0:.3f}, w_0={w_0:.4f}, w_a={w_a:.4f}, sigma8_0={sigma_8_0:.4f}, eos_model={eos_model}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
