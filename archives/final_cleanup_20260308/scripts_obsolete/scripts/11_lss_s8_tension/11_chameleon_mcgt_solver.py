#!/usr/bin/env python3
"""Chapter 11: chameleon-like MCGT growth scan."""

from __future__ import annotations

import argparse
import configparser
from pathlib import Path

import numpy as np
from scipy.integrate import solve_ivp


DEFAULT_A_INIT = 1.0e-3
DEFAULT_Q0STAR_TARGET = -2.0e-3
DEFAULT_Q0STAR_LIGO = 1.0e-6
DEFAULT_S8_REF = 0.83
DEFAULT_S8_TARGET = 0.77
DEFAULT_N_MIN = 0.0
DEFAULT_N_MAX = 4.0
DEFAULT_N_STEPS = 81


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Scan a density-based chameleon-MCGT coupling for Chapter 11."
    )
    parser.add_argument("--config", default="config/mcgt-global-config.ini")
    parser.add_argument("--a-min", type=float, default=0.01)
    parser.add_argument("--a-max", type=float, default=1.0)
    parser.add_argument("--a-init", type=float, default=DEFAULT_A_INIT)
    parser.add_argument("--n-a", type=int, default=400)
    parser.add_argument("--alpha", type=float, help="Override perturbation alpha.")
    parser.add_argument("--q0star-target", type=float, default=DEFAULT_Q0STAR_TARGET)
    parser.add_argument("--q0star-ligo", type=float, default=DEFAULT_Q0STAR_LIGO)
    parser.add_argument("--s8-ref", type=float, default=DEFAULT_S8_REF)
    parser.add_argument("--s8-target", type=float, default=DEFAULT_S8_TARGET)
    parser.add_argument("--n-min", type=float, default=DEFAULT_N_MIN)
    parser.add_argument("--n-max", type=float, default=DEFAULT_N_MAX)
    parser.add_argument("--n-steps", type=int, default=DEFAULT_N_STEPS)
    parser.add_argument(
        "--out",
        default="assets/zz-figures/11_lss_s8_tension/11_chameleon_rescue_path.png",
    )
    parser.add_argument(
        "--csv-out",
        default="assets/zz-data/11_lss_s8_tension/11_chameleon_rescue_path.csv",
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
    if omega_m0 <= 0.0 or omega_de0 <= 0.0:
        raise ValueError("Flat-universe background requires 0 < Omega_m0 < 1")
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


def q0star_chameleon(a: float, q0star_target: float, omega_m0: float, n_screen: float) -> float:
    rho_ratio = 1.0 / (omega_m0 * a ** -3)
    return q0star_target * rho_ratio ** n_screen


def g_eff(a: float, q0star: float, alpha: float) -> float:
    alpha_eff = max(alpha, 0.0)
    beta_eff = alpha * q0star * a ** (-alpha_eff)
    return float(np.exp(2.0 * beta_eff))


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


def save_csv(path: Path, rows: np.ndarray) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    np.savetxt(
        path,
        rows,
        delimiter=",",
        header="n_screen,s8,q0eff_early,q0eff_today,ligo_safe",
        comments="",
    )


def make_plot(
    n_values: np.ndarray,
    s8_values: np.ndarray,
    ligo_safe: np.ndarray,
    args: argparse.Namespace,
    best_idx: int,
    out_path: Path,
) -> None:
    try:
        import matplotlib.pyplot as plt
    except ImportError as exc:
        raise SystemExit(f"matplotlib missing: {exc}") from exc

    out_path.parent.mkdir(parents=True, exist_ok=True)
    fig, ax = plt.subplots(figsize=(7.0, 4.6))
    ax.plot(n_values, s8_values, color="tab:blue", lw=2.2, label=r"$S_8(n)$")
    if np.any(ligo_safe):
        safe_n = n_values[ligo_safe]
        ax.axvspan(float(safe_n.min()), float(safe_n.max()), color="0.90", alpha=1.0, label=r"LIGO-safe at $a_{\rm init}$")
    ax.axhline(args.s8_target, color="tab:red", ls="--", lw=1.2, label=rf"Target $S_8={args.s8_target:.3f}$")
    ax.axhline(args.s8_ref, color="0.4", ls=":", lw=1.0, label=rf"Reference $S_8={args.s8_ref:.2f}$")
    ax.scatter([n_values[best_idx]], [s8_values[best_idx]], color="black", zorder=3)
    ax.text(
        0.03,
        0.96,
        rf"Best sampled $n={n_values[best_idx]:.2f}$" + "\n" + rf"$S_8 \approx {s8_values[best_idx]:.3f}$",
        transform=ax.transAxes,
        va="top",
        fontsize=9,
    )
    ax.set_xlabel("Screening index n")
    ax.set_ylabel(r"Estimated $S_8$")
    ax.set_title("Chameleon-MCGT rescue path")
    ax.grid(True, alpha=0.25)
    ax.legend(frameon=False, loc="lower right")
    fig.subplots_adjust(left=0.12, right=0.98, bottom=0.13, top=0.90)
    fig.savefig(out_path, dpi=180)


def main() -> int:
    args = parse_args()
    config = load_cosmology(Path(args.config))
    alpha = config["alpha"] if args.alpha is None else args.alpha

    a_out = np.linspace(args.a_min, args.a_max, args.n_a)
    a_grid = np.concatenate(([args.a_init], a_out)) if args.a_init < args.a_min else a_out

    d_gr = solve_growth(
        a_grid,
        config["omega_m0"],
        config["omega_de0"],
        lambda a: 1.0,
    )[-len(a_out) :]

    n_values = np.linspace(args.n_min, args.n_max, args.n_steps)
    rows = []
    s8_values = []
    safe_mask = []

    for n_screen in n_values:
        mu_fn = lambda a, n=n_screen: g_eff(
            a,
            q0star_chameleon(a, args.q0star_target, config["omega_m0"], n),
            alpha,
        )
        d_model = solve_growth(a_grid, config["omega_m0"], config["omega_de0"], mu_fn)[-len(a_out) :]
        s8_model = estimate_s8(args.s8_ref, d_gr[-1], d_model[-1])
        q0_early = q0star_chameleon(args.a_init, args.q0star_target, config["omega_m0"], n_screen)
        q0_today = q0star_chameleon(1.0, args.q0star_target, config["omega_m0"], n_screen)
        ligo_safe = abs(q0_early) <= args.q0star_ligo
        rows.append([n_screen, s8_model, q0_early, q0_today, 1.0 if ligo_safe else 0.0])
        s8_values.append(s8_model)
        safe_mask.append(ligo_safe)

    rows_arr = np.asarray(rows, dtype=float)
    s8_arr = np.asarray(s8_values, dtype=float)
    safe_arr = np.asarray(safe_mask, dtype=bool)

    if np.any(safe_arr):
        candidate_indices = np.where(safe_arr)[0]
        best_idx = candidate_indices[np.argmin(np.abs(s8_arr[candidate_indices] - args.s8_target))]
    else:
        best_idx = int(np.argmin(np.abs(s8_arr - args.s8_target)))

    print(
        f"Best sampled n -> n={n_values[best_idx]:.3f}, "
        f"S8~{s8_arr[best_idx]:.6f}, "
        f"q0early={rows_arr[best_idx, 2]:.6e}, "
        f"LIGO_safe={bool(rows_arr[best_idx, 4])}"
    )

    save_csv(Path(args.csv_out), rows_arr)
    make_plot(n_values, s8_arr, safe_arr, args, best_idx, Path(args.out))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
