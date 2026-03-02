#!/usr/bin/env python3
"""Chapter 11: k-dependent MCGT solver as a scale-splitting rescue test."""

from __future__ import annotations

import argparse
import configparser
from pathlib import Path

import numpy as np
from scipy.integrate import solve_ivp


DEFAULT_A_INIT = 1.0e-3
DEFAULT_Q0STAR_MAX = -2.0e-3
DEFAULT_Q0STAR_SAFE = -1.0e-6
DEFAULT_S8_REF = 0.83
DEFAULT_S8_TARGET = 0.77
DEFAULT_K_LSS = 1.0e-4
DEFAULT_K_GW = 100.0
DEFAULT_K_C = 0.0707


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Test a scale-dependent q0*(k) split between LSS and GW."
    )
    parser.add_argument("--config", default="config/mcgt-global-config.ini")
    parser.add_argument("--a-min", type=float, default=0.01)
    parser.add_argument("--a-max", type=float, default=1.0)
    parser.add_argument("--a-init", type=float, default=DEFAULT_A_INIT)
    parser.add_argument("--n-a", type=int, default=400)
    parser.add_argument("--alpha", type=float, help="Override perturbation alpha.")
    parser.add_argument("--q0star-max", type=float, default=DEFAULT_Q0STAR_MAX)
    parser.add_argument("--q0star-safe", type=float, default=DEFAULT_Q0STAR_SAFE)
    parser.add_argument("--k-lss", type=float, default=DEFAULT_K_LSS)
    parser.add_argument("--k-gw", type=float, default=DEFAULT_K_GW)
    parser.add_argument("--k-c", type=float, default=DEFAULT_K_C)
    parser.add_argument("--s8-ref", type=float, default=DEFAULT_S8_REF)
    parser.add_argument("--s8-target", type=float, default=DEFAULT_S8_TARGET)
    parser.add_argument(
        "--out",
        default="assets/zz-figures/11_lss_s8_tension/11_k_dependent_rescue.png",
    )
    parser.add_argument(
        "--csv-out",
        default="assets/zz-data/11_lss_s8_tension/11_k_dependent_rescue.csv",
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


def q0star_of_k(k_mode: float, q0star_safe: float, q0star_max: float, k_c: float) -> float:
    return q0star_safe + (q0star_max - q0star_safe) / (1.0 + (k_mode / k_c) ** 2)


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


def estimate_s8(s8_ref: float, d_gr_today: float, d_model_today: float) -> float:
    return s8_ref * d_model_today / d_gr_today


def main() -> int:
    args = parse_args()
    cfg = load_cosmology(Path(args.config))
    alpha = cfg["alpha"] if args.alpha is None else args.alpha
    a_out = np.linspace(args.a_min, args.a_max, args.n_a)
    a_grid = np.concatenate(([args.a_init], a_out)) if args.a_init < args.a_min else a_out

    d_gr = solve_growth(a_grid, cfg["omega_m0"], cfg["omega_de0"], lambda a: 1.0)[-len(a_out) :]

    q_lss = q0star_of_k(args.k_lss, args.q0star_safe, args.q0star_max, args.k_c)
    q_gw = q0star_of_k(args.k_gw, args.q0star_safe, args.q0star_max, args.k_c)

    d_lss = solve_growth(
        a_grid,
        cfg["omega_m0"],
        cfg["omega_de0"],
        lambda a: g_eff(a, q_lss, alpha),
    )[-len(a_out) :]
    d_gw = solve_growth(
        a_grid,
        cfg["omega_m0"],
        cfg["omega_de0"],
        lambda a: g_eff(a, q_gw, alpha),
    )[-len(a_out) :]

    s8_lss = estimate_s8(args.s8_ref, d_gr[-1], d_lss[-1])
    s8_gw = estimate_s8(args.s8_ref, d_gr[-1], d_gw[-1])

    print(
        f"k-dependent split -> q0_LSS={q_lss:.6e}, q0_GW={q_gw:.6e}, "
        f"S8_LSS~{s8_lss:.6f}, S8_GW~{s8_gw:.6f}"
    )

    out_csv = Path(args.csv_out)
    out_csv.parent.mkdir(parents=True, exist_ok=True)
    np.savetxt(
        out_csv,
        np.column_stack(
            [
                a_out,
                d_gr,
                d_lss,
                d_gw,
                np.full_like(a_out, q_lss),
                np.full_like(a_out, q_gw),
            ]
        ),
        delimiter=",",
        header="a,D_gr,D_lss,D_gw,q0_lss,q0_gw",
        comments="",
    )

    try:
        import matplotlib.pyplot as plt
    except ImportError as exc:
        raise SystemExit(f"matplotlib missing: {exc}") from exc

    out_fig = Path(args.out)
    out_fig.parent.mkdir(parents=True, exist_ok=True)
    dev_lss = 100.0 * (d_lss - d_gr) / d_gr
    dev_gw = 100.0 * (d_gw - d_gr) / d_gr
    target_delta = 100.0 * (args.s8_target / args.s8_ref - 1.0)
    fig, ax = plt.subplots(figsize=(7.1, 4.8))
    ax.plot(a_out, dev_lss, color="tab:blue", lw=2.2, label=rf"LSS mode ($k={args.k_lss:.1e}$, $S_8\approx {s8_lss:.3f}$)")
    ax.plot(a_out, dev_gw, color="tab:red", lw=2.0, ls="--", label=rf"GW mode ($k={args.k_gw:.1e}$, $S_8\approx {s8_gw:.3f}$)")
    ax.axhline(target_delta, color="black", ls="--", lw=1.2, label=r"Equivalent target for $S_8=0.77$")
    ax.axhline(0.0, color="0.5", ls=":", lw=1.0)
    ax.text(
        0.03,
        0.96,
        "\n".join(
            [
                rf"$q_0^*(k\to 0)\approx {q_lss:.2e}$",
                rf"$q_0^*(k\to \infty)\approx {q_gw:.2e}$",
                rf"$k_c={args.k_c:.3g}$",
            ]
        ),
        transform=ax.transAxes,
        va="top",
        fontsize=9,
    )
    ax.set_xlabel("Scale factor a")
    ax.set_ylabel(r"$100 \times (D-D_{\rm GR}) / D_{\rm GR}$ [%]")
    ax.set_title("k-dependent rescue path for MCGT")
    ax.grid(True, alpha=0.25)
    ax.legend(frameon=False, loc="lower left")
    fig.subplots_adjust(left=0.13, right=0.98, bottom=0.14, top=0.90)
    fig.savefig(out_fig, dpi=180)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
