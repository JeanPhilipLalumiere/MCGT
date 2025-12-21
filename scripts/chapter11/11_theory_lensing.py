#!/usr/bin/env python3
"""
Chapter 11 - theory lensing baseline.

Compute primordial power spectrum and matter power spectrum at z=0 using
an Eisenstein-Hu transfer function. Growth factor uses CPL dark energy
(w0, wa) read from mcgt-global-config.ini.
"""

from __future__ import annotations

import argparse
import configparser
import json
import logging
import math
from pathlib import Path

import numpy as np


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Chapter 11: matter power spectrum and sigma8"
    )
    parser.add_argument(
        "--config",
        default="config/mcgt-global-config.ini",
        help="Path to central INI config",
    )
    parser.add_argument(
        "--k-pivot",
        type=float,
        default=0.05,
        help="Pivot scale for primordial spectrum [1/Mpc]",
    )
    parser.add_argument(
        "--growth-steps",
        type=int,
        default=2000,
        help="Number of steps for growth ODE integration",
    )
    parser.add_argument(
        "--w0",
        type=float,
        help="Override w0 for CPL growth (default: from config).",
    )
    parser.add_argument(
        "--wa",
        type=float,
        help="Override wa for CPL growth (default: from config).",
    )
    parser.add_argument(
        "--compare-lcdm",
        action="store_true",
        help="Also run LCDM (w0=-1, wa=0) and generate comparison plot.",
    )
    return parser.parse_args()


def _load_chapter07_params(root: Path) -> dict[str, float]:
    candidates = [
        root / "assets/zz-data" / "chapter07" / "07_perturbations_params.json",
        root / "assets/zz-data" / "chapter07" / "07_params_perturbations.json",
    ]
    for path in candidates:
        if path.exists():
            data = json.loads(path.read_text(encoding="utf-8"))
            return {
                "k_min": float(data["k_min"]),
                "k_max": float(data["k_max"]),
                "dlog": float(data["dlog"]),
            }
    return {}


def load_config(config_path: Path, repo_root: Path) -> dict[str, float]:
    cfg = configparser.ConfigParser(
        interpolation=None, inline_comment_prefixes=("#", ";")
    )
    if not cfg.read(config_path, encoding="utf-8"):
        raise FileNotFoundError(f"Cannot read config: {config_path}")

    if "cmb" not in cfg or "perturbations" not in cfg:
        raise ValueError("Missing [cmb] or [perturbations] section in config")

    cmb = cfg["cmb"]
    pert = cfg["perturbations"]

    if "dark_energy" not in cfg:
        raise ValueError("Missing [dark_energy] section with w0, wa")
    de = cfg["dark_energy"]

    H0 = cmb.getfloat("H0")
    ombh2 = cmb.getfloat("ombh2")
    omch2 = cmb.getfloat("omch2")
    As0 = cmb.getfloat("As0")
    ns0 = cmb.getfloat("ns0")

    chapter07 = _load_chapter07_params(repo_root)
    k_min = chapter07.get("k_min", pert.getfloat("k_min"))
    k_max = chapter07.get("k_max", pert.getfloat("k_max"))
    dlog = chapter07.get("dlog", pert.getfloat("dlog"))

    w0 = de.getfloat("w0")
    wa = de.getfloat("wa")

    h = H0 / 100.0
    omega_m = (ombh2 + omch2) / (h * h)
    omega_b = ombh2 / (h * h)
    omega_de = 1.0 - omega_m

    return {
        "H0": H0,
        "h": h,
        "ombh2": ombh2,
        "omch2": omch2,
        "As0": As0,
        "ns0": ns0,
        "k_min": k_min,
        "k_max": k_max,
        "dlog": dlog,
        "omega_m": omega_m,
        "omega_b": omega_b,
        "omega_de": omega_de,
        "w0": w0,
        "wa": wa,
    }


def build_log_grid(k_min: float, k_max: float, dlog: float) -> np.ndarray:
    if k_min <= 0 or k_max <= 0 or k_max <= k_min:
        raise ValueError("k_min > 0, k_max > k_min required")
    n = int(np.floor((np.log10(k_max) - np.log10(k_min)) / dlog)) + 1
    return 10 ** (np.log10(k_min) + np.arange(n) * dlog)


def transfer_eisenstein_hu(k: np.ndarray, omega_m: float, omega_b: float, h: float) -> np.ndarray:
    if omega_m <= 0 or h <= 0:
        raise ValueError("omega_m and h must be positive")
    omh2 = omega_m * h * h
    obh2 = omega_b * h * h
    if omh2 <= 0:
        raise ValueError("omega_m*h^2 must be positive")

    theta = 2.7255 / 2.7
    s = 44.5 * np.log(9.83 / omh2) / np.sqrt(1.0 + 10.0 * obh2 ** 0.75)
    alpha = (
        1.0
        - 0.328 * np.log(431.0 * omh2) * (omega_b / omega_m)
        + 0.38 * np.log(22.3 * omh2) * (omega_b / omega_m) ** 2
    )
    gamma_eff = omega_m * h * (alpha + (1.0 - alpha) / (1.0 + (0.43 * k * s) ** 4))
    q = k * theta * theta / gamma_eff
    L0 = np.log(2.0 * math.e + 1.8 * q)
    C0 = 14.2 + 731.0 / (1.0 + 62.5 * q)
    return L0 / (L0 + C0 * q * q)


def e2_cpl(a: float, omega_m: float, omega_de: float, w0: float, wa: float) -> float:
    if a <= 0:
        return math.inf
    de_factor = a ** (-3.0 * (1.0 + w0 + wa)) * math.exp(-3.0 * wa * (1.0 - a))
    return omega_m * a ** -3 + omega_de * de_factor


def dlnE_da(a: float, omega_m: float, omega_de: float, w0: float, wa: float) -> float:
    e2 = e2_cpl(a, omega_m, omega_de, w0, wa)
    if e2 <= 0:
        return 0.0
    de_factor = a ** (-3.0 * (1.0 + w0 + wa)) * math.exp(-3.0 * wa * (1.0 - a))
    dlnf_da = -3.0 * (1.0 + w0 + wa) / a + 3.0 * wa
    de_prime = omega_de * de_factor * dlnf_da
    e2_prime = -3.0 * omega_m * a ** -4 + de_prime
    return 0.5 * e2_prime / e2


def omega_m_a(a: float, omega_m: float, omega_de: float, w0: float, wa: float) -> float:
    e2 = e2_cpl(a, omega_m, omega_de, w0, wa)
    return omega_m * a ** -3 / e2


def integrate_growth(
    omega_m: float,
    omega_de: float,
    w0: float,
    wa: float,
    n_steps: int,
    a_init: float = 1e-3,
    a_final: float = 1.0,
) -> tuple[np.ndarray, np.ndarray]:
    a_grid = np.linspace(a_init, a_final, n_steps)
    D = np.zeros_like(a_grid)
    dD = np.zeros_like(a_grid)

    D[0] = a_init
    dD[0] = 1.0

    for i in range(1, n_steps):
        a = a_grid[i - 1]
        h = a_grid[i] - a_grid[i - 1]

        def rhs(a_val: float, y: np.ndarray) -> np.ndarray:
            D_val, dD_val = y
            term = (3.0 / a_val) + dlnE_da(a_val, omega_m, omega_de, w0, wa)
            om_a = omega_m_a(a_val, omega_m, omega_de, w0, wa)
            ddD = -term * dD_val + 1.5 * om_a * D_val / (a_val * a_val)
            return np.array([dD_val, ddD])

        y = np.array([D[i - 1], dD[i - 1]])
        k1 = rhs(a, y)
        k2 = rhs(a + 0.5 * h, y + 0.5 * h * k1)
        k3 = rhs(a + 0.5 * h, y + 0.5 * h * k2)
        k4 = rhs(a + h, y + h * k3)
        y_next = y + (h / 6.0) * (k1 + 2.0 * k2 + 2.0 * k3 + k4)

        D[i] = y_next[0]
        dD[i] = y_next[1]

    return a_grid, D


def sigma8_from_pk(k: np.ndarray, pk: np.ndarray, h: float) -> float:
    R = 8.0 / h
    x = k * R
    with np.errstate(divide="ignore", invalid="ignore"):
        W = 3.0 * (np.sin(x) - x * np.cos(x)) / (x * x * x)
    W = np.where(x == 0, 1.0, W)
    integrand = k * k * pk * W * W
    return math.sqrt(np.trapezoid(integrand, k) / (2.0 * math.pi * math.pi))


def matter_power_spectrum(
    k: np.ndarray,
    A_s: float,
    n_s: float,
    k_pivot: float,
    T_k: np.ndarray,
    D0: float,
    omega_m: float,
    H0_km_s_mpc: float,
) -> np.ndarray:
    H0_mpc = H0_km_s_mpc / 299792.458  # 1/Mpc
    prefac = (2.0 / 5.0) * (k * k) * T_k * D0 / (omega_m * H0_mpc * H0_mpc)
    P_R = (2.0 * math.pi * math.pi / (k * k * k)) * A_s * (k / k_pivot) ** (
        n_s - 1.0
    )
    return prefac * prefac * P_R


def build_outputs(
    k_grid: np.ndarray,
    params: dict[str, float],
    k_pivot: float,
    growth_steps: int,
    w0: float,
    wa: float,
) -> dict[str, object]:
    _, D_grid = integrate_growth(
        params["omega_m"],
        params["omega_de"],
        w0,
        wa,
        growth_steps,
    )
    D0 = D_grid[-1]
    T_k = transfer_eisenstein_hu(k_grid, params["omega_m"], params["omega_b"], params["h"])
    P_m = matter_power_spectrum(
        k_grid,
        params["As0"],
        params["ns0"],
        k_pivot,
        T_k,
        D0,
        params["omega_m"],
        params["H0"],
    )
    sigma8 = sigma8_from_pk(k_grid, P_m, params["h"])
    return {
        "D0": D0,
        "T_k": T_k,
        "P_m": P_m,
        "sigma8": sigma8,
    }


def main() -> int:
    logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")
    args = parse_args()
    cfg_path = Path(args.config)
    repo_root = Path(__file__).resolve().parents[2]

    try:
        params = load_config(cfg_path, repo_root)
    except (FileNotFoundError, ValueError) as exc:
        logging.error("Config error: %s", exc)
        return 1

    k_grid = build_log_grid(params["k_min"], params["k_max"], params["dlog"])

    w0 = params["w0"] if args.w0 is None else args.w0
    wa = params["wa"] if args.wa is None else args.wa

    logging.info("Computing growth factor with CPL w0=%s, wa=%s", w0, wa)
    cpl = build_outputs(k_grid, params, args.k_pivot, args.growth_steps, w0, wa)

    out_dir = Path("assets/zz-data") / "chapter11"
    out_dir.mkdir(parents=True, exist_ok=True)

    np.savetxt(
        out_dir / "11_matter_power_cpl.csv",
        np.column_stack([k_grid, cpl["T_k"], cpl["P_m"]]),
        delimiter=",",
        header="k, T, P_m",
        comments="",
    )

    summary: dict[str, object] = {
        "k_min": params["k_min"],
        "k_max": params["k_max"],
        "dlog": params["dlog"],
        "H0": params["H0"],
        "omega_m": params["omega_m"],
        "omega_b": params["omega_b"],
        "w0": w0,
        "wa": wa,
        "D0_cpl": cpl["D0"],
        "sigma8_cpl": cpl["sigma8"],
        "k_pivot": args.k_pivot,
    }

    if args.compare_lcdm:
        logging.info("Computing LCDM baseline (w0=-1, wa=0)")
        lcdm = build_outputs(
            k_grid, params, args.k_pivot, args.growth_steps, -1.0, 0.0
        )
        summary["D0_lcdm"] = lcdm["D0"]
        summary["sigma8_lcdm"] = lcdm["sigma8"]

        np.savetxt(
            out_dir / "11_matter_power_lcdm.csv",
            np.column_stack([k_grid, lcdm["T_k"], lcdm["P_m"]]),
            delimiter=",",
            header="k, T, P_m",
            comments="",
        )

        try:
            import matplotlib.pyplot as plt
        except ImportError as exc:
            logging.error("matplotlib missing: %s", exc)
            return 1

        k_h = k_grid / params["h"]
        P_cpl_h = cpl["P_m"] * params["h"] ** 3
        P_lcdm_h = lcdm["P_m"] * params["h"] ** 3

        fig, ax = plt.subplots(figsize=(6.8, 4.2))
        ax.loglog(k_h, P_cpl_h, label="CPL (best-fit)", lw=2.0)
        ax.loglog(k_h, P_lcdm_h, label="LCDM (w=-1)", lw=2.0, ls="--")
        ax.set_xlabel(r"k [h Mpc$^{-1}$]")
        ax.set_ylabel(r"P(k) [h$^{-3}$ Mpc$^{3}$]")
        ax.grid(True, which="both", alpha=0.25)
        ax.legend(frameon=False)
        fig.tight_layout()
        fig.savefig(
            Path("assets/zz-figures") / "chapter11" / "11_power_comparison.png", dpi=180
        )

        logging.info(
            "sigma8 CPL=%.5f, LCDM=%.5f",
            cpl["sigma8"],
            lcdm["sigma8"],
        )

    (out_dir / "11_summary.json").write_text(
        json.dumps(summary, indent=2), encoding="utf-8"
    )

    logging.info("Outputs written to %s", out_dir)
    logging.info("sigma8 (CPL) = %.5f", cpl["sigma8"])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
