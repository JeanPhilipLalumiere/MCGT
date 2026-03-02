#!/usr/bin/env python3
"""Chapter 11: density-based screening prototype inspired by chameleon ideas."""

from __future__ import annotations

import argparse
import configparser
from pathlib import Path

import numpy as np
from scipy.integrate import solve_ivp


DEFAULT_A_INIT = 1.0e-3
DEFAULT_Q0STAR_LIGO = -1.0e-6
DEFAULT_Q0STAR_COSMO = -2.092224e-3
DEFAULT_S8_REF = 0.83
DEFAULT_S8_TARGET = 0.77
DEFAULT_A_TRANS = 0.5
DEFAULT_N_SCREEN = 4.0
DEFAULT_MAX_ABS_Q0EFF = 1.0e-2
DEFAULT_LOCAL_DENSITY_BOOST = 1.0e12


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Density-based screening toy model for Chapter 11."
    )
    parser.add_argument("--config", default="config/mcgt-global-config.ini")
    parser.add_argument("--a-min", type=float, default=0.01)
    parser.add_argument("--a-max", type=float, default=1.0)
    parser.add_argument("--n-a", type=int, default=400)
    parser.add_argument("--a-init", type=float, default=DEFAULT_A_INIT)
    parser.add_argument("--alpha", type=float, help="Override perturbation alpha.")
    parser.add_argument("--q0star-ligo", type=float, default=DEFAULT_Q0STAR_LIGO)
    parser.add_argument("--q0star-cosmo", type=float, default=DEFAULT_Q0STAR_COSMO)
    parser.add_argument("--a-trans", type=float, default=DEFAULT_A_TRANS)
    parser.add_argument("--n-screen", type=float, default=DEFAULT_N_SCREEN)
    parser.add_argument("--max-abs-q0eff", type=float, default=DEFAULT_MAX_ABS_Q0EFF)
    parser.add_argument("--local-density-boost", type=float, default=DEFAULT_LOCAL_DENSITY_BOOST)
    parser.add_argument("--s8-ref", type=float, default=DEFAULT_S8_REF)
    parser.add_argument("--s8-target", type=float, default=DEFAULT_S8_TARGET)
    parser.add_argument(
        "--out",
        default="assets/zz-figures/11_lss_s8_tension/11_chameleon_transition.png",
    )
    return parser.parse_args()


def load_cosmology(config_path: Path) -> dict[str, float]:
    cfg = configparser.ConfigParser(
        interpolation=None, inline_comment_prefixes=("#", ";")
    )
    if not cfg.read(config_path, encoding="utf-8"):
        raise FileNotFoundError(f"Cannot read config: {config_path}")
    cmb = cfg["cmb"]
    pert = cfg["perturbations"]
    h = cmb.getfloat("h0") / 100.0
    omega_m0 = (cmb.getfloat("ombh2") + cmb.getfloat("omch2")) / (h * h)
    omega_de0 = 1.0 - omega_m0
    return {
        "omega_m0": omega_m0,
        "omega_de0": omega_de0,
        "alpha": pert.getfloat("alpha"),
    }


def e2_lcdm(a: float, omega_m0: float, omega_de0: float) -> float:
    return omega_m0 * a ** -3 + omega_de0


def dlnh_da(a: float, omega_m0: float, omega_de0: float) -> float:
    return 0.5 * (-3.0 * omega_m0 * a ** -4) / e2_lcdm(a, omega_m0, omega_de0)


def omega_m_of_a(a: float, omega_m0: float, omega_de0: float) -> float:
    return omega_m0 * a ** -3 / e2_lcdm(a, omega_m0, omega_de0)


def rho_ratio(a: float) -> float:
    return a ** -3


def activation_density(a: float, a_trans: float, n_screen: float, density_boost: float) -> float:
    rho_trans = a_trans ** -3
    rho_eff = rho_ratio(a) * density_boost
    return 1.0 / (1.0 + (rho_eff / rho_trans) ** n_screen)


def q0eff_density(
    a: float,
    q0star_ligo: float,
    q0star_cosmo: float,
    a_trans: float,
    n_screen: float,
    density_boost: float,
    max_abs_q0eff: float,
) -> float:
    activation = activation_density(a, a_trans, n_screen, density_boost)
    q0_eff = q0star_ligo + activation * (q0star_cosmo - q0star_ligo)
    return float(np.clip(q0_eff, -max_abs_q0eff, max_abs_q0eff))


def g_eff(a: float, q0eff: float, alpha: float) -> float:
    alpha_eff = max(alpha, 0.0)
    return float(np.exp(2.0 * alpha * q0eff * a ** (-alpha_eff)))


def solve_growth(a_eval: np.ndarray, omega_m0: float, omega_de0: float, mu_fn) -> np.ndarray:
    def rhs(a: float, y: np.ndarray) -> np.ndarray:
        growth, growth_prime = y
        friction = 3.0 / a + dlnh_da(a, omega_m0, omega_de0)
        source = 1.5 * omega_m_of_a(a, omega_m0, omega_de0) / (a * a)
        return np.array([growth_prime, -friction * growth_prime + source * mu_fn(a) * growth])

    sol = solve_ivp(
        rhs,
        (float(a_eval[0]), float(a_eval[-1])),
        np.array([a_eval[0], 1.0]),
        t_eval=a_eval,
        rtol=1.0e-8,
        atol=1.0e-10,
    )
    if not sol.success:
        raise RuntimeError(sol.message)
    return sol.y[0]


def estimate_s8(s8_ref: float, d_gr_today: float, d_model_today: float) -> float:
    return s8_ref * d_model_today / d_gr_today


def make_plot(
    a_out: np.ndarray,
    q0_lss: np.ndarray,
    q0_local: np.ndarray,
    d_gr: np.ndarray,
    d_density: np.ndarray,
    s8_density: float,
    args: argparse.Namespace,
    out_path: Path,
) -> None:
    try:
        import matplotlib.pyplot as plt
    except ImportError as exc:
        raise SystemExit(f"matplotlib missing: {exc}") from exc

    out_path.parent.mkdir(parents=True, exist_ok=True)
    deviation = 100.0 * (d_density - d_gr) / d_gr

    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(7.0, 6.0), sharex=True)
    ax1.plot(a_out, q0_lss, lw=2.2, color="tab:blue", label="Background density")
    ax1.plot(a_out, q0_local, lw=2.0, ls="--", color="tab:red", label="Local high density")
    ax1.axhline(args.q0star_ligo, color="0.4", ls=":")
    ax1.axhline(-args.max_abs_q0eff, color="0.4", ls=":")
    ax1.axvline(args.a_trans, color="0.3", ls=":")
    ax1.set_ylabel(r"$q_{0,\mathrm{eff}}^*(a)$")
    ax1.set_title("Density-based screening toy model")
    ax1.grid(True, alpha=0.25)
    ax1.legend(frameon=False, loc="lower left")

    ax2.plot(a_out, deviation, lw=2.2, color="tab:green")
    ax2.axhline(0.0, color="0.4", ls="--", lw=1.0)
    ax2.text(
        0.03,
        0.94,
        rf"$S_8^{{density}} \approx {s8_density:.3f}$" + "\n" + rf"Target $S_8={args.s8_target:.3f}$",
        transform=ax2.transAxes,
        va="top",
        fontsize=9,
    )
    ax2.set_xlabel("Scale factor a")
    ax2.set_ylabel(r"$100 \times (D-D_{\rm GR}) / D_{\rm GR}$ [%]")
    ax2.grid(True, alpha=0.25)
    fig.subplots_adjust(left=0.12, right=0.98, bottom=0.10, top=0.93, hspace=0.10)
    fig.savefig(out_path, dpi=180)


def main() -> int:
    args = parse_args()
    config = load_cosmology(Path(args.config))
    alpha = config["alpha"] if args.alpha is None else args.alpha
    a_out = np.linspace(args.a_min, args.a_max, args.n_a)
    a_grid = np.concatenate(([args.a_init], a_out)) if args.a_init < args.a_min else a_out

    mu_gr = lambda a: 1.0
    mu_density = lambda a: g_eff(
        a,
        q0eff_density(
            a,
            args.q0star_ligo,
            args.q0star_cosmo,
            args.a_trans,
            args.n_screen,
            1.0,
            args.max_abs_q0eff,
        ),
        alpha,
    )

    d_gr = solve_growth(a_grid, config["omega_m0"], config["omega_de0"], mu_gr)[-len(a_out) :]
    d_density = solve_growth(a_grid, config["omega_m0"], config["omega_de0"], mu_density)[-len(a_out) :]

    q0_lss = np.array(
        [
            q0eff_density(
                a,
                args.q0star_ligo,
                args.q0star_cosmo,
                args.a_trans,
                args.n_screen,
                1.0,
                args.max_abs_q0eff,
            )
            for a in a_out
        ]
    )
    q0_local = np.array(
        [
            q0eff_density(
                a,
                args.q0star_ligo,
                args.q0star_cosmo,
                args.a_trans,
                args.n_screen,
                args.local_density_boost,
                args.max_abs_q0eff,
            )
            for a in a_out
        ]
    )
    s8_density = estimate_s8(args.s8_ref, d_gr[-1], d_density[-1])

    print(f"Density-based screened mode -> S8~{s8_density:.6f}")
    print(
        f"Today q0eff: background={q0_lss[-1]:.6e}, local={q0_local[-1]:.6e}, "
        f"target={args.s8_target:.3f}"
    )

    make_plot(a_out, q0_lss, q0_local, d_gr, d_density, s8_density, args, Path(args.out))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
