#!/usr/bin/env python3
"""Chapter 12: CMB acoustic scale and angular diameter distance."""

from __future__ import annotations

import argparse
import configparser
import json
import logging
import math
from pathlib import Path

import numpy as np

C_KM_S = 299792.458


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Compute CMB acoustic scale theta* for Chapter 12."
    )
    parser.add_argument(
        "--config",
        default="zz-configuration/mcgt-global-config.ini",
        help="Path to central INI config.",
    )
    parser.add_argument(
        "--z-rec",
        type=float,
        help="Override recombination redshift (default: Hu-Sugiyama fit).",
    )
    parser.add_argument(
        "--z-max",
        type=float,
        default=1.0e6,
        help="Upper redshift limit for sound horizon integral.",
    )
    parser.add_argument(
        "--n-steps",
        type=int,
        default=12000,
        help="Number of steps for distance integrals.",
    )
    parser.add_argument(
        "--w0",
        type=float,
        help="Override w0 for CPL model (default: from config).",
    )
    parser.add_argument(
        "--wa",
        type=float,
        help="Override wa for CPL model (default: from config).",
    )
    parser.add_argument(
        "--compare-lcdm",
        action="store_true",
        help="Also compute LCDM baseline (w0=-1, wa=0).",
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
    omega_m = (ombh2 + omch2) / (h * h)

    omega_gamma_h2 = 2.469e-5 * (Tcmb / 2.7255) ** 4
    omega_r_h2 = omega_gamma_h2 * (1.0 + 0.2271 * Neff)
    omega_r = omega_r_h2 / (h * h)
    omega_de = 1.0 - omega_m - omega_r

    return {
        "H0": H0,
        "h": h,
        "ombh2": ombh2,
        "omch2": omch2,
        "w0": w0,
        "wa": wa,
        "Tcmb": Tcmb,
        "Neff": Neff,
        "omega_m": omega_m,
        "omega_r": omega_r,
        "omega_de": omega_de,
    }


def z_rec_hu_sugiyama(ombh2: float, ommh2: float) -> float:
    g1 = 0.0783 * ombh2 ** -0.238 / (1.0 + 39.5 * ombh2 ** 0.763)
    g2 = 0.560 / (1.0 + 21.1 * ombh2 ** 1.81)
    return 1048.0 * (1.0 + 0.00124 * ombh2 ** -0.738) * (1.0 + g1 * ommh2 ** g2)


def e2_cpl(z: np.ndarray, omega_m: float, omega_r: float, omega_de: float, w0: float, wa: float) -> np.ndarray:
    a = 1.0 / (1.0 + z)
    de_factor = a ** (-3.0 * (1.0 + w0 + wa)) * np.exp(-3.0 * wa * (1.0 - a))
    return omega_m * (1.0 + z) ** 3 + omega_r * (1.0 + z) ** 4 + omega_de * de_factor


def comoving_distance(z: float, params: dict[str, float], n_steps: int) -> tuple[float, float]:
    z_grid = np.linspace(0.0, z, n_steps)
    e = np.sqrt(e2_cpl(z_grid, params["omega_m"], params["omega_r"], params["omega_de"], params["w0"], params["wa"]))
    integral = np.trapezoid(1.0 / e, z_grid)
    return (C_KM_S / params["H0"]) * integral, integral


def angular_diameter_distance(z: float, params: dict[str, float], n_steps: int) -> tuple[float, float]:
    d_c, integral = comoving_distance(z, params, n_steps)
    return d_c / (1.0 + z), integral


def sound_horizon(z_rec: float, params: dict[str, float], z_max: float, n_steps: int) -> float:
    z_grid = np.logspace(np.log10(z_rec), np.log10(z_max), n_steps)
    e = np.sqrt(e2_cpl(z_grid, params["omega_m"], params["omega_r"], params["omega_de"], params["w0"], params["wa"]))

    # Baryon-to-photon ratio R(z)
    R = 31.5 * params["ombh2"] * (params["Tcmb"] / 2.7) ** -4 * (1.0e3 / (1.0 + z_grid))
    c_s = 1.0 / np.sqrt(3.0 * (1.0 + R))
    integral = np.trapezoid(c_s / e, z_grid)
    return (C_KM_S / params["H0"]) * integral


def main() -> int:
    logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")
    args = parse_args()
    cfg_path = Path(args.config)

    try:
        params = load_config(cfg_path)
    except (FileNotFoundError, KeyError, ValueError) as exc:
        logging.error("Config error: %s", exc)
        return 1

    ommh2 = (params["ombh2"] + params["omch2"])
    z_rec = args.z_rec if args.z_rec is not None else z_rec_hu_sugiyama(params["ombh2"], ommh2)

    w0 = params["w0"] if args.w0 is None else args.w0
    wa = params["wa"] if args.wa is None else args.wa

    def run_model(label: str, w0_val: float, wa_val: float) -> dict[str, float]:
        model = params.copy()
        model["w0"] = w0_val
        model["wa"] = wa_val
        d_m, integral = comoving_distance(z_rec, model, args.n_steps)
        d_a = d_m / (1.0 + z_rec)
        r_s = sound_horizon(z_rec, model, args.z_max, args.n_steps)
        theta = r_s / d_m
        theta100 = 100.0 * theta
        R_shift = math.sqrt(model["omega_m"]) * integral
        return {
            "D_M_Mpc": d_m,
            "D_A_Mpc": d_a,
            "r_s_Mpc": r_s,
            "theta_star": theta,
            "theta100": theta100,
            "R_shift": R_shift,
            "w0": w0_val,
            "wa": wa_val,
        }

    cpl = run_model("CPL", w0, wa)

    planck_theta100 = 1.041
    planck_R = 1.7502

    out_dir = Path("zz-data") / "chapter12"
    out_dir.mkdir(parents=True, exist_ok=True)

    summary: dict[str, float] = {
        "z_rec": z_rec,
        "H0": params["H0"],
        "omega_m": params["omega_m"],
        "omega_r": params["omega_r"],
        "planck_theta100": planck_theta100,
        "planck_R": planck_R,
        "theta100_cpl": cpl["theta100"],
        "delta_theta100_cpl": cpl["theta100"] - planck_theta100,
        "R_shift_cpl": cpl["R_shift"],
        "delta_R_cpl": cpl["R_shift"] - planck_R,
        "D_M_Mpc_cpl": cpl["D_M_Mpc"],
        "D_A_Mpc_cpl": cpl["D_A_Mpc"],
        "r_s_Mpc_cpl": cpl["r_s_Mpc"],
        "w0_cpl": cpl["w0"],
        "wa_cpl": cpl["wa"],
    }

    if args.compare_lcdm:
        lcdm = run_model("LCDM", -1.0, 0.0)
        summary.update(
            {
                "theta100_lcdm": lcdm["theta100"],
                "delta_theta100_lcdm": lcdm["theta100"] - planck_theta100,
                "R_shift_lcdm": lcdm["R_shift"],
                "delta_R_lcdm": lcdm["R_shift"] - planck_R,
                "D_M_Mpc_lcdm": lcdm["D_M_Mpc"],
                "D_A_Mpc_lcdm": lcdm["D_A_Mpc"],
                "r_s_Mpc_lcdm": lcdm["r_s_Mpc"],
            }
        )

    (out_dir / "12_cmb_theta_summary.json").write_text(
        json.dumps(summary, indent=2), encoding="utf-8"
    )

    logging.info("z_rec = %.3f", z_rec)
    logging.info("100*theta* CPL = %.6f (delta %.6f)", summary["theta100_cpl"], summary["delta_theta100_cpl"])
    logging.info("R_shift CPL = %.6f (delta %.6f)", summary["R_shift_cpl"], summary["delta_R_cpl"])
    if args.compare_lcdm:
        logging.info(
            "100*theta* LCDM = %.6f (delta %.6f)",
            summary["theta100_lcdm"],
            summary["delta_theta100_lcdm"],
        )
        logging.info(
            "R_shift LCDM = %.6f (delta %.6f)",
            summary["R_shift_lcdm"],
            summary["delta_R_lcdm"],
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
