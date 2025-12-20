#!/usr/bin/env python3
"""Chapter 12: CMB shift-parameter likelihood heatmap in (w0, wa)."""

from __future__ import annotations

import argparse
import configparser
import math
from pathlib import Path

import numpy as np

C_KM_S = 299792.458


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Plot CMB shift-parameter heatmap.")
    parser.add_argument(
        "--config",
        default="zz-configuration/mcgt-global-config.ini",
        help="Path to central INI config.",
    )
    parser.add_argument("--w0-min", type=float, default=-1.5)
    parser.add_argument("--w0-max", type=float, default=0.0)
    parser.add_argument("--wa-min", type=float, default=-2.0)
    parser.add_argument("--wa-max", type=float, default=1.0)
    parser.add_argument("--n-w0", type=int, default=61)
    parser.add_argument("--n-wa", type=int, default=61)
    parser.add_argument("--n-steps", type=int, default=4000)
    parser.add_argument(
        "--out",
        default="zz-figures/chapter12/12_fig_01_cmb_likelihood.png",
        help="Output PNG path.",
    )
    return parser.parse_args()


def load_config(path: Path) -> dict[str, float]:
    cfg = configparser.ConfigParser(
        interpolation=None, inline_comment_prefixes=("#", ";")
    )
    if not cfg.read(path, encoding="utf-8"):
        raise FileNotFoundError(f"Cannot read config: {path}")

    cmb = cfg["cmb"]
    rad = cfg["radiation"] if "radiation" in cfg else None

    H0 = cmb.getfloat("H0")
    ombh2 = cmb.getfloat("ombh2")
    omch2 = cmb.getfloat("omch2")

    Tcmb = 2.7255 if rad is None else rad.getfloat("Tcmb_K")
    Neff = 3.046 if rad is None else rad.getfloat("Neff")

    h = H0 / 100.0
    omega_m = (ombh2 + omch2) / (h * h)

    omega_gamma_h2 = 2.469e-5 * (Tcmb / 2.7255) ** 4
    omega_r_h2 = omega_gamma_h2 * (1.0 + 0.2271 * Neff)
    omega_r = omega_r_h2 / (h * h)

    return {
        "H0": H0,
        "ombh2": ombh2,
        "omch2": omch2,
        "Tcmb": Tcmb,
        "Neff": Neff,
        "omega_m": omega_m,
        "omega_r": omega_r,
    }


def z_rec_hu_sugiyama(ombh2: float, ommh2: float) -> float:
    g1 = 0.0783 * ombh2 ** -0.238 / (1.0 + 39.5 * ombh2 ** 0.763)
    g2 = 0.560 / (1.0 + 21.1 * ombh2 ** 1.81)
    return 1048.0 * (1.0 + 0.00124 * ombh2 ** -0.738) * (1.0 + g1 * ommh2 ** g2)


def e2_cpl(z: np.ndarray, omega_m: float, omega_r: float, omega_de: float, w0: float, wa: float) -> np.ndarray:
    a = 1.0 / (1.0 + z)
    de_factor = a ** (-3.0 * (1.0 + w0 + wa)) * np.exp(-3.0 * wa * (1.0 - a))
    return omega_m * (1.0 + z) ** 3 + omega_r * (1.0 + z) ** 4 + omega_de * de_factor


def shift_parameter(z_rec: float, params: dict[str, float], w0: float, wa: float, n_steps: int) -> float:
    z_grid = np.linspace(0.0, z_rec, n_steps)
    omega_de = 1.0 - params["omega_m"] - params["omega_r"]
    e = np.sqrt(e2_cpl(z_grid, params["omega_m"], params["omega_r"], omega_de, w0, wa))
    integral = np.trapezoid(1.0 / e, z_grid)
    return math.sqrt(params["omega_m"]) * integral


def main() -> int:
    args = parse_args()
    cfg = load_config(Path(args.config))

    ommh2 = cfg["ombh2"] + cfg["omch2"]
    z_rec = z_rec_hu_sugiyama(cfg["ombh2"], ommh2)

    w0_vals = np.linspace(args.w0_min, args.w0_max, args.n_w0)
    wa_vals = np.linspace(args.wa_min, args.wa_max, args.n_wa)

    planck_R = 1.7502
    sigma_R = 0.0046

    chi2 = np.zeros((args.n_wa, args.n_w0))

    for i, wa in enumerate(wa_vals):
        for j, w0 in enumerate(w0_vals):
            R = shift_parameter(z_rec, cfg, w0, wa, args.n_steps)
            chi2[i, j] = ((R - planck_R) / sigma_R) ** 2

    try:
        import matplotlib.pyplot as plt
    except ImportError as exc:
        raise SystemExit(f"matplotlib missing: {exc}") from exc

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)

    fig, ax = plt.subplots(figsize=(6.8, 5.2))
    im = ax.imshow(
        chi2,
        origin="lower",
        aspect="auto",
        extent=[w0_vals[0], w0_vals[-1], wa_vals[0], wa_vals[-1]],
        cmap="magma",
    )
    ax.set_xlabel(r"w0")
    ax.set_ylabel(r"wa")
    ax.set_title(r"CMB shift parameter $\chi^2$ (Planck)")
    fig.colorbar(im, ax=ax, label=r"$\chi^2$")
    fig.tight_layout()
    fig.savefig(out_path, dpi=300)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
