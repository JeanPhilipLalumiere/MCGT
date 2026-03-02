#!/usr/bin/env python3
"""Chapter 11: final comparison plot across the main screening prototypes."""

from __future__ import annotations

import argparse
import configparser
from pathlib import Path

import numpy as np
from scipy.integrate import solve_ivp


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Plot final Chapter 11 model comparison.")
    parser.add_argument("--config", default="config/mcgt-global-config.ini")
    parser.add_argument("--a-min", type=float, default=0.01)
    parser.add_argument("--a-max", type=float, default=1.0)
    parser.add_argument("--a-init", type=float, default=1.0e-3)
    parser.add_argument("--n-a", type=int, default=500)
    parser.add_argument("--s8-ref", type=float, default=0.83)
    parser.add_argument("--s8-target", type=float, default=0.77)
    parser.add_argument(
        "--out",
        default="assets/zz-figures/11_lss_s8_tension/11_all_models_comparison.png",
    )
    return parser.parse_args()


def load_cosmology(config_path: Path) -> dict[str, float]:
    cfg = configparser.ConfigParser(interpolation=None, inline_comment_prefixes=("#", ";"))
    if not cfg.read(config_path, encoding="utf-8"):
        raise FileNotFoundError(f"Cannot read config: {config_path}")
    cmb = cfg["cmb"]
    pert = cfg["perturbations"]
    h = cmb.getfloat("h0") / 100.0
    omega_m0 = (cmb.getfloat("ombh2") + cmb.getfloat("omch2")) / (h * h)
    omega_de0 = 1.0 - omega_m0
    return {"omega_m0": omega_m0, "omega_de0": omega_de0, "alpha": pert.getfloat("alpha")}


def e2_lcdm(a: float, omega_m0: float, omega_de0: float) -> float:
    return omega_m0 * a ** -3 + omega_de0


def dlnh_da(a: float, omega_m0: float, omega_de0: float) -> float:
    return 0.5 * (-3.0 * omega_m0 * a ** -4) / e2_lcdm(a, omega_m0, omega_de0)


def omega_m_of_a(a: float, omega_m0: float, omega_de0: float) -> float:
    return omega_m0 * a ** -3 / e2_lcdm(a, omega_m0, omega_de0)


def g_eff(a: float, q0star: float, alpha: float) -> float:
    alpha_eff = max(alpha, 0.0)
    return float(np.exp(2.0 * alpha * q0star * a ** (-alpha_eff)))


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


def q0star_chameleon(a: float, q0star_target: float, omega_m0: float, n_screen: float) -> float:
    return q0star_target * (1.0 / (omega_m0 * a ** -3)) ** n_screen


def logistic_step(a: float, a_trigger: float, delta_a: float) -> float:
    x = np.clip((a - a_trigger) / delta_a, -60.0, 60.0)
    return 1.0 / (1.0 + np.exp(-x))


def q0star_late_trigger(
    a: float,
    q0star_safe: float,
    q0star_peak: float,
    a_lock: float,
    a_trigger: float,
    delta_a: float,
) -> float:
    if a <= a_lock:
        return q0star_safe
    return q0star_safe + logistic_step(a, a_trigger, delta_a) * (q0star_peak - q0star_safe)


def estimate_s8(s8_ref: float, d_gr_today: float, d_model_today: float) -> float:
    return s8_ref * d_model_today / d_gr_today


def main() -> int:
    args = parse_args()
    cfg = load_cosmology(Path(args.config))
    a_out = np.linspace(args.a_min, args.a_max, args.n_a)
    a_grid = np.concatenate(([args.a_init], a_out)) if args.a_init < args.a_min else a_out

    d_gr = solve_growth(a_grid, cfg["omega_m0"], cfg["omega_de0"], lambda a: 1.0)[-len(a_out) :]

    curves: list[tuple[str, np.ndarray, float, str]] = []

    q_ligo = -1.0e-6
    d_ligo = solve_growth(a_grid, cfg["omega_m0"], cfg["omega_de0"], lambda a: g_eff(a, q_ligo, cfg["alpha"]))[-len(a_out) :]
    curves.append(("LIGO-safe", d_ligo, estimate_s8(args.s8_ref, d_gr[-1], d_ligo[-1]), "tab:orange"))

    n_cham = 0.4
    q_cham = lambda a: q0star_chameleon(a, -2.0e-3, cfg["omega_m0"], n_cham)
    d_cham = solve_growth(a_grid, cfg["omega_m0"], cfg["omega_de0"], lambda a: g_eff(a, q_cham(a), cfg["alpha"]))[-len(a_out) :]
    curves.append(("Chameleon", d_cham, estimate_s8(args.s8_ref, d_gr[-1], d_cham[-1]), "tab:green"))

    q_late = lambda a: q0star_late_trigger(a, -1.0e-6, -5.0e-1, 0.5, 2.0 / 3.0, 0.015)
    d_late = solve_growth(a_grid, cfg["omega_m0"], cfg["omega_de0"], lambda a: g_eff(a, q_late(a), cfg["alpha"]))[-len(a_out) :]
    curves.append(("Late-Trigger", d_late, estimate_s8(args.s8_ref, d_gr[-1], d_late[-1]), "tab:blue"))

    target_delta = 100.0 * (args.s8_target / args.s8_ref - 1.0)

    try:
        import matplotlib.pyplot as plt
    except ImportError as exc:
        raise SystemExit(f"matplotlib missing: {exc}") from exc

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    fig, ax = plt.subplots(figsize=(7.1, 4.8))
    for label, d_model, s8_value, color in curves:
        deviation = 100.0 * (d_model - d_gr) / d_gr
        ax.plot(a_out, deviation, lw=2.2, color=color, label=f"{label} ($S_8\\approx {s8_value:.3f}$)")
    ax.axhline(target_delta, color="black", ls="--", lw=1.2, label=r"Equivalent target for $S_8=0.77$")
    ax.axhline(0.0, color="0.5", ls=":", lw=1.0)
    ax.set_xlabel("Scale factor a")
    ax.set_ylabel(r"$100 \times (D-D_{\rm GR}) / D_{\rm GR}$ [%]")
    ax.set_title("Chapter 11 synthesis: time-only screening prototypes")
    ax.grid(True, alpha=0.25)
    ax.legend(frameon=False, loc="lower left")
    fig.subplots_adjust(left=0.13, right=0.98, bottom=0.14, top=0.90)
    fig.savefig(out_path, dpi=180)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
