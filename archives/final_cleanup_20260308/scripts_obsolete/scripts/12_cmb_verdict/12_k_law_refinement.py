#!/usr/bin/env python3
"""Chapter 12: refine the optimal k-dependent transition law for MCGT."""

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


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Compare k-space kernels for the final MCGT rescue law."
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
    parser.add_argument("--k-c-min", type=float, default=1.0e-4)
    parser.add_argument("--k-c-max", type=float, default=1.0e1)
    parser.add_argument("--n-kc", type=int, default=121)
    parser.add_argument("--s8-ref", type=float, default=DEFAULT_S8_REF)
    parser.add_argument("--s8-target", type=float, default=DEFAULT_S8_TARGET)
    parser.add_argument(
        "--out",
        default="assets/zz-figures/12_cmb_verdict/12_perfect_k_law.png",
    )
    parser.add_argument(
        "--csv-out",
        default="assets/zz-data/12_cmb_verdict/12_k_law_refinement.csv",
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


def q0_kernel_lorentzian(k_mode: float, k_c: float) -> float:
    return 1.0 / (1.0 + (k_mode / k_c) ** 2)


def q0_kernel_yukawa(k_mode: float, k_c: float) -> float:
    return float(np.exp(-((k_mode / k_c) ** 2)))


def q0_kernel_step(k_mode: float, k_c: float) -> float:
    return 1.0 if k_mode <= k_c else 0.0


def q0star_of_k(
    kernel_name: str,
    k_mode: float,
    q0star_safe: float,
    q0star_max: float,
    k_c: float,
) -> float:
    kernels = {
        "lorentzian": q0_kernel_lorentzian,
        "yukawa": q0_kernel_yukawa,
        "step": q0_kernel_step,
    }
    weight = kernels[kernel_name](k_mode, k_c)
    return q0star_safe + (q0star_max - q0star_safe) * weight


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
    k_c_values = np.logspace(np.log10(args.k_c_min), np.log10(args.k_c_max), args.n_kc)
    kernel_names = ["lorentzian", "yukawa", "step"]

    rows: list[list[float | str]] = []
    best: dict[str, float | str | np.ndarray] | None = None

    for kernel_name in kernel_names:
        for k_c in k_c_values:
            q_lss = q0star_of_k(kernel_name, args.k_lss, args.q0star_safe, args.q0star_max, k_c)
            q_gw = q0star_of_k(kernel_name, args.k_gw, args.q0star_safe, args.q0star_max, k_c)
            d_lss = solve_growth(
                a_grid,
                cfg["omega_m0"],
                cfg["omega_de0"],
                lambda a, q=q_lss: g_eff(a, q, alpha),
            )[-len(a_out) :]
            d_gw = solve_growth(
                a_grid,
                cfg["omega_m0"],
                cfg["omega_de0"],
                lambda a, q=q_gw: g_eff(a, q, alpha),
            )[-len(a_out) :]
            s8_lss = estimate_s8(args.s8_ref, d_gr[-1], d_lss[-1])
            s8_gw = estimate_s8(args.s8_ref, d_gr[-1], d_gw[-1])
            ligo_impact = abs(q_gw - args.q0star_safe)
            target_error = abs(s8_lss - args.s8_target)
            score = target_error + 10.0 * ligo_impact
            rows.append(
                [
                    kernel_name,
                    k_c,
                    q_lss,
                    q_gw,
                    s8_lss,
                    s8_gw,
                    target_error,
                    ligo_impact,
                    score,
                ]
            )
            if best is None or score < float(best["score"]):
                best = {
                    "kernel": kernel_name,
                    "k_c": float(k_c),
                    "q_lss": float(q_lss),
                    "q_gw": float(q_gw),
                    "s8_lss": float(s8_lss),
                    "s8_gw": float(s8_gw),
                    "score": float(score),
                    "d_lss": d_lss.copy(),
                }

    assert best is not None

    out_csv = Path(args.csv_out)
    out_csv.parent.mkdir(parents=True, exist_ok=True)
    header = "kernel,k_c,q0_lss,q0_gw,s8_lss,s8_gw,target_error,ligo_impact,score"
    np.savetxt(
        out_csv,
        np.array(rows, dtype=object),
        fmt="%s",
        delimiter=",",
        header=header,
        comments="",
    )

    try:
        import matplotlib.pyplot as plt
    except ImportError as exc:
        raise SystemExit(f"matplotlib missing: {exc}") from exc

    fig, (ax1, ax2) = plt.subplots(
        2, 1, figsize=(7.2, 7.0), gridspec_kw={"height_ratios": [3, 2]}
    )
    colors = {"lorentzian": "tab:blue", "yukawa": "tab:green", "step": "tab:red"}

    rows_arr = np.array(rows, dtype=object)
    for kernel_name in kernel_names:
        mask = rows_arr[:, 0] == kernel_name
        kc = rows_arr[mask, 1].astype(float)
        s8_vals = rows_arr[mask, 4].astype(float)
        ax1.semilogx(kc, s8_vals, color=colors[kernel_name], lw=2.0, label=kernel_name.capitalize())
    ax1.axhline(args.s8_target, color="black", ls="--", lw=1.2, label=rf"Target $S_8={args.s8_target:.3f}$")
    ax1.axhline(args.s8_ref, color="0.5", ls=":", lw=1.0, label=rf"Reference $S_8={args.s8_ref:.2f}$")
    ax1.scatter([float(best["k_c"])], [float(best["s8_lss"])], color="gold", edgecolor="black", zorder=4, s=80)
    ax1.set_xlabel(r"Transition scale $k_c$ [$h\,\mathrm{Mpc}^{-1}$]")
    ax1.set_ylabel(r"$S_8$ on LSS branch")
    ax1.set_title("Kernel refinement for the k-dependent MCGT rescue law")
    ax1.grid(True, alpha=0.25)
    ax1.legend(frameon=False, loc="best")

    k_plot = np.logspace(-5, 3, 400)
    q_plot = np.array(
        [
            q0star_of_k(
                str(best["kernel"]),
                k_val,
                args.q0star_safe,
                args.q0star_max,
                float(best["k_c"]),
            )
            for k_val in k_plot
        ]
    )
    ax2.semilogx(k_plot, q_plot, color=colors[str(best["kernel"])], lw=2.4)
    ax2.axhline(args.q0star_safe, color="tab:red", ls="--", lw=1.0, label=r"LIGO-safe floor")
    ax2.axhline(args.q0star_max, color="tab:blue", ls=":", lw=1.0, label=r"LSS target floor")
    ax2.text(
        0.03,
        0.96,
        "\n".join(
            [
                rf"Best law: {str(best['kernel']).capitalize()}",
                rf"$k_c \approx {float(best['k_c']):.3g}$",
                rf"$S_8 \approx {float(best['s8_lss']):.4f}$",
                rf"$q_0^*(k_{{GW}}) \approx {float(best['q_gw']):.2e}$",
            ]
        ),
        transform=ax2.transAxes,
        va="top",
        fontsize=9,
    )
    ax2.set_xlabel(r"Wavenumber $k$ [$h\,\mathrm{Mpc}^{-1}$]")
    ax2.set_ylabel(r"$q_0^*(k)$")
    ax2.set_title("The Perfect Law")
    ax2.grid(True, alpha=0.25)
    ax2.legend(frameon=False, loc="lower left")
    fig.subplots_adjust(left=0.12, right=0.98, bottom=0.08, top=0.93, hspace=0.28)

    out_fig = Path(args.out)
    out_fig.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(out_fig, dpi=180)

    print(
        f"Best kernel -> law={best['kernel']}, k_c={float(best['k_c']):.6g}, "
        f"S8_LSS~{float(best['s8_lss']):.6f}, q0_GW={float(best['q_gw']):.6e}, "
        f"S8_GW~{float(best['s8_gw']):.6f}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
