#!/usr/bin/env python3
"""Chapter 11: screened MCGT growth solver for the S8-vs-LIGO tension."""

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
DEFAULT_DELTA_A = 0.08
DEFAULT_K_TRANS = 0.2
DEFAULT_K_LSS = 0.02
DEFAULT_K_GW = 100.0
DEFAULT_MAX_ABS_Q0EFF = 1.0e-2


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Solve screened linear growth for the Chapter 11 tension test."
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
    parser.add_argument("--delta-a", type=float, default=DEFAULT_DELTA_A)
    parser.add_argument("--k-trans", type=float, default=DEFAULT_K_TRANS)
    parser.add_argument("--k-lss", type=float, default=DEFAULT_K_LSS)
    parser.add_argument("--k-gw", type=float, default=DEFAULT_K_GW)
    parser.add_argument("--screening-power", type=float, default=4.0)
    parser.add_argument("--max-abs-q0eff", type=float, default=DEFAULT_MAX_ABS_Q0EFF)
    parser.add_argument("--s8-ref", type=float, default=DEFAULT_S8_REF)
    parser.add_argument("--s8-target", type=float, default=DEFAULT_S8_TARGET)
    parser.add_argument(
        "--out",
        default="assets/zz-figures/11_lss_s8_tension/11_screened_growth_success.png",
    )
    parser.add_argument(
        "--csv-out",
        default="assets/zz-data/11_lss_s8_tension/11_screening_dynamics.csv",
    )
    parser.add_argument(
        "--mechanism-fig",
        default="assets/zz-figures/11_lss_s8_tension/11_screening_mechanism.png",
    )
    parser.add_argument(
        "--note-out",
        default="assets/zz-data/11_lss_s8_tension/11_screening_note.md",
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

    h0 = cmb.getfloat("h0")
    h = h0 / 100.0
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
    e2 = e2_lcdm(a, omega_m0, omega_de0)
    return 0.5 * (-3.0 * omega_m0 * a ** -4) / e2


def omega_m_of_a(a: float, omega_m0: float, omega_de0: float) -> float:
    return omega_m0 * a ** -3 / e2_lcdm(a, omega_m0, omega_de0)


def smooth_step_tanh(x: float) -> float:
    return 0.5 * (1.0 + np.tanh(x))


def scale_screening(k_mode: float, k_trans: float, power: float) -> float:
    return 1.0 / (1.0 + (k_mode / k_trans) ** power)


def activation_prefactor(
    a: float,
    k_mode: float,
    a_trans: float,
    delta_a: float,
    k_trans: float,
    screening_power: float,
    time_renorm: float,
    contrast_gain: float,
) -> float:
    time_weight = smooth_step_tanh((a - a_trans) / delta_a)
    scale_weight = scale_screening(k_mode, k_trans, screening_power)
    return contrast_gain * time_weight * time_renorm * scale_weight


def q0star_screened(
    a: float,
    k_mode: float,
    q0star_ligo: float,
    q0star_cosmo: float,
    a_trans: float,
    delta_a: float,
    k_trans: float,
    screening_power: float,
    time_renorm: float,
    contrast_gain: float,
    max_abs_q0eff: float | None = None,
) -> float:
    activation = activation_prefactor(
        a,
        k_mode,
        a_trans,
        delta_a,
        k_trans,
        screening_power,
        time_renorm,
        contrast_gain,
    )
    q0_eff = q0star_ligo + activation * (q0star_cosmo - q0star_ligo)
    if max_abs_q0eff is not None:
        q0_eff = float(np.clip(q0_eff, -max_abs_q0eff, max_abs_q0eff))
    return q0_eff


def g_eff_unscreened(a: float, q0star: float, alpha: float) -> float:
    alpha_eff = max(alpha, 0.0)
    beta_eff = alpha * q0star * a ** (-alpha_eff)
    return float(np.exp(2.0 * beta_eff))


def g_eff_screened(
    a: float,
    k_mode: float,
    q0star_ligo: float,
    q0star_cosmo: float,
    alpha: float,
    a_trans: float,
    delta_a: float,
    k_trans: float,
    screening_power: float,
    time_renorm: float,
    contrast_gain: float,
    max_abs_q0eff: float | None = None,
) -> float:
    q0_eff = q0star_screened(
        a,
        k_mode,
        q0star_ligo,
        q0star_cosmo,
        a_trans,
        delta_a,
        k_trans,
        screening_power,
        time_renorm,
        contrast_gain,
        max_abs_q0eff,
    )
    return g_eff_unscreened(a, q0_eff, alpha)


def growth_rhs(
    a: float,
    y: np.ndarray,
    omega_m0: float,
    omega_de0: float,
    mu_fn,
) -> np.ndarray:
    growth, growth_prime = y
    friction = 3.0 / a + dlnh_da(a, omega_m0, omega_de0)
    source = 1.5 * omega_m_of_a(a, omega_m0, omega_de0) / (a * a)
    return np.array([growth_prime, -friction * growth_prime + source * mu_fn(a) * growth])


def solve_growth(a_eval: np.ndarray, omega_m0: float, omega_de0: float, mu_fn) -> np.ndarray:
    solution = solve_ivp(
        growth_rhs,
        t_span=(float(a_eval[0]), float(a_eval[-1])),
        y0=np.array([a_eval[0], 1.0]),
        t_eval=a_eval,
        method="RK45",
        rtol=1.0e-8,
        atol=1.0e-10,
        args=(omega_m0, omega_de0, mu_fn),
    )
    if not solution.success:
        raise RuntimeError(f"Growth integration failed: {solution.message}")
    return solution.y[0]


def estimate_s8(s8_ref: float, d_gr_today: float, d_model_today: float) -> float:
    return s8_ref * d_model_today / d_gr_today


def compute_time_renorm(a_eval: np.ndarray, a_trans: float, delta_a: float) -> float:
    time_kernel = smooth_step_tanh((a_eval - a_trans) / delta_a)
    mean_kernel = float(np.mean(time_kernel))
    if mean_kernel <= 0.0:
        return 1.0
    return 1.0 / mean_kernel


def bounded_contrast_gain(
    args: argparse.Namespace,
    time_renorm: float,
) -> float:
    today_activation = activation_prefactor(
        1.0,
        args.k_lss,
        args.a_trans,
        args.delta_a,
        args.k_trans,
        args.screening_power,
        time_renorm,
        1.0,
    )
    delta_q0 = abs(args.q0star_cosmo - args.q0star_ligo)
    headroom = max(args.max_abs_q0eff - abs(args.q0star_ligo), 0.0)
    if today_activation <= 0.0 or delta_q0 <= 0.0:
        return 1.0
    return headroom / (today_activation * delta_q0)


def make_plot(
    a_out: np.ndarray,
    d_gr: np.ndarray,
    d_screened: np.ndarray,
    d_unscreened: np.ndarray,
    q0_lss: np.ndarray,
    q0_gw: np.ndarray,
    geff_lss: np.ndarray,
    geff_gw: np.ndarray,
    s8_screened: float,
    s8_unscreened: float,
    contrast_gain: float,
    args: argparse.Namespace,
    out_path: Path,
) -> None:
    try:
        import matplotlib.pyplot as plt
    except ImportError as exc:
        raise SystemExit(f"matplotlib missing: {exc}") from exc

    out_path.parent.mkdir(parents=True, exist_ok=True)
    deviation_screened = 100.0 * (d_screened - d_gr) / d_gr
    deviation_unscreened = 100.0 * (d_unscreened - d_gr) / d_gr

    fig, (ax1, ax2) = plt.subplots(
        2, 1, figsize=(7.2, 6.8), sharex=True, gridspec_kw={"height_ratios": [3, 2]}
    )

    ax1.plot(a_out, deviation_screened, lw=2.2, color="tab:blue", label="MCGT Screened (LSS mode)")
    ax1.plot(
        a_out,
        deviation_unscreened,
        lw=2.0,
        color="tab:orange",
        ls="--",
        label=r"MCGT Unscreened ($q_0^*=-10^{-6}$)",
    )
    ax1.axhline(0.0, color="0.5", ls="--", lw=1.0, label=r"GR / $\Lambda$CDM")
    ax1.axvline(args.a_trans, color="0.3", ls=":", lw=1.0)
    ax1.text(
        args.a_trans + 0.015,
        0.04,
        rf"$a_{{trans}}={args.a_trans:.2f}$",
        transform=ax1.get_xaxis_transform(),
        fontsize=9,
    )
    ax1.text(
        0.02,
        0.96,
        "\n".join(
            [
                rf"$S_8^{{screened}} \approx {s8_screened:.3f}$",
                rf"$S_8^{{unscreened}} \approx {s8_unscreened:.3f}$",
                rf"Target $S_8 \approx {args.s8_target:.3f}$",
                rf"$|q_{{0,eff}}^*| \leq {args.max_abs_q0eff:.0e}$, gain={contrast_gain:.2f}",
            ]
        ),
        transform=ax1.transAxes,
        va="top",
        fontsize=9,
    )
    ax1.set_ylabel(r"$100 \times (D-D_{\rm GR}) / D_{\rm GR}$ [%]")
    ax1.set_title("Screened MCGT: late-time activation for the S8 tension")
    ax1.grid(True, alpha=0.25)
    ax1.legend(frameon=False, loc="lower left")

    ax2.plot(a_out, q0_lss, color="tab:blue", lw=2.2, label=rf"LSS mode $k={args.k_lss:.2g}$")
    ax2.plot(a_out, q0_gw, color="tab:red", lw=2.0, ls="--", label=rf"GW mode $k={args.k_gw:.2g}$")
    ax2.axhline(args.q0star_ligo, color="tab:red", ls=":", lw=1.0, label=r"LIGO-safe $q_0^*=-10^{-6}$")
    ax2.axhline(args.q0star_cosmo, color="tab:blue", ls=":", lw=1.0, label=r"LSS target $q_0^*=-2.09\times10^{-3}$")
    ax2.axvline(args.a_trans, color="0.3", ls=":", lw=1.0)
    ax2.set_xlabel("Scale factor a")
    ax2.set_ylabel(r"Effective $q_0^*(a,k)$")
    ax2.grid(True, alpha=0.25)
    ax2.legend(frameon=False, loc="center right")

    fig.subplots_adjust(left=0.12, right=0.98, bottom=0.10, top=0.93, hspace=0.10)
    fig.savefig(out_path, dpi=180)


def make_mechanism_plot(
    a_out: np.ndarray,
    q0_lss: np.ndarray,
    q0_gw: np.ndarray,
    args: argparse.Namespace,
    out_path: Path,
) -> None:
    try:
        import matplotlib.pyplot as plt
    except ImportError as exc:
        raise SystemExit(f"matplotlib missing: {exc}") from exc

    out_path.parent.mkdir(parents=True, exist_ok=True)
    fig, ax = plt.subplots(figsize=(7.0, 4.6))
    ax.plot(a_out, q0_lss, color="tab:blue", lw=2.2, label=rf"LSS mode $k={args.k_lss:.2g}$")
    ax.plot(a_out, q0_gw, color="tab:red", lw=2.0, ls="--", label=rf"GW mode $k={args.k_gw:.2g}$")
    ax.axhline(args.q0star_ligo, color="tab:red", ls=":", lw=1.0)
    ax.axhline(-args.max_abs_q0eff, color="0.4", ls=":", lw=1.0, label=rf"Bound $-\,{args.max_abs_q0eff:.0e}$")
    ax.axvline(args.a_trans, color="0.3", ls=":", lw=1.0, label=rf"$a_{{trans}}={args.a_trans:.2f}$")
    ax.set_xlabel("Scale factor a")
    ax.set_ylabel(r"Effective $q_{0,\mathrm{eff}}^*(a)$")
    ax.set_title("Screening mechanism: late-time split between GW and LSS modes")
    ax.grid(True, alpha=0.25)
    ax.legend(frameon=False, loc="lower left")
    fig.subplots_adjust(left=0.13, right=0.98, bottom=0.14, top=0.90)
    fig.savefig(out_path, dpi=180)


def export_diagnostics_csv(
    path: Path,
    a_out: np.ndarray,
    q0_lss: np.ndarray,
    q0_gw: np.ndarray,
    geff_lss: np.ndarray,
    geff_gw: np.ndarray,
) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    data = np.column_stack([a_out, q0_lss, q0_gw, geff_lss, geff_gw])
    np.savetxt(
        path,
        data,
        delimiter=",",
        header="a,q0eff_lss,q0eff_gw,geff_over_g_lss,geff_over_g_gw",
        comments="",
    )


def write_note(
    path: Path,
    s8_screened: float,
    s8_target: float,
    contrast_gain: float,
    args: argparse.Namespace,
    q0_lss_today: float,
    q0_gw_today: float,
) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        "# Screening note",
        "",
        f"Bounded screening run with `|q0_eff| <= {args.max_abs_q0eff:.0e}`.",
        f"Resulting screened value: `S8 = {s8_screened:.6f}` for target `S8 = {s8_target:.3f}`.",
        f"Contrast gain used: `{contrast_gain:.3f}`.",
        f"Today, the effective coupling is `q0eff_LSS(a=1) = {q0_lss_today:.6e}` and `q0eff_GW(a=1) = {q0_gw_today:.6e}`.",
        "",
        "Assessment:",
        "- Inference: this prototype is not directly compatible with standard chameleon screening, because the transition is imposed in scale factor and wavenumber rather than emerging from a density-dependent effective mass.",
        "- Inference: it is also not a standard Vainshtein realization, because the suppression is not generated by nonlinear derivative interactions around sources.",
        "- The bounded run remains close to the GW-safe branch but misses the full S8 target, which indicates that a classical screening picture would need additional dynamics beyond this phenomenological kernel.",
        "",
        "Reference points:",
        "- Khoury & Weltman (2004), chameleon cosmology: https://doi.org/10.1103/PhysRevD.69.044026",
        "- Brax et al. (2004), cosmological chameleon: https://doi.org/10.1103/PhysRevD.70.123518",
        "- Babichev, Deffayet & Esposito-Farese (2011), Vainshtein and time variation of G: https://doi.org/10.1103/PhysRevLett.107.251102",
        "- Joyce, Jain, Khoury & Trodden (2015), screening review: https://doi.org/10.1016/j.physrep.2014.12.002",
        "",
    ]
    path.write_text("\n".join(lines), encoding="utf-8")


def main() -> int:
    args = parse_args()
    config = load_cosmology(Path(args.config))
    alpha = config["alpha"] if args.alpha is None else args.alpha

    a_out = np.linspace(args.a_min, args.a_max, args.n_a)
    a_grid = np.concatenate(([args.a_init], a_out)) if args.a_init < args.a_min else a_out
    time_renorm = compute_time_renorm(a_grid, args.a_trans, args.delta_a)

    mu_gr = lambda a: 1.0
    mu_unscreened = lambda a: g_eff_unscreened(a, args.q0star_ligo, alpha)
    d_gr = solve_growth(a_grid, config["omega_m0"], config["omega_de0"], mu_gr)[-len(a_out) :]
    d_unscreened = solve_growth(
        a_grid, config["omega_m0"], config["omega_de0"], mu_unscreened
    )[-len(a_out) :]
    contrast_gain = bounded_contrast_gain(args, time_renorm)
    mu_screened_lss = lambda a: g_eff_screened(
        a,
        args.k_lss,
        args.q0star_ligo,
        args.q0star_cosmo,
        alpha,
        args.a_trans,
        args.delta_a,
        args.k_trans,
        args.screening_power,
        time_renorm,
        contrast_gain,
        args.max_abs_q0eff,
    )
    d_screened = solve_growth(
        a_grid, config["omega_m0"], config["omega_de0"], mu_screened_lss
    )[-len(a_out) :]
    s8_screened = estimate_s8(args.s8_ref, d_gr[-1], d_screened[-1])

    q0_lss = np.array(
        [
            q0star_screened(
                a,
                args.k_lss,
                args.q0star_ligo,
                args.q0star_cosmo,
                args.a_trans,
                args.delta_a,
                args.k_trans,
                args.screening_power,
                time_renorm,
                contrast_gain,
                args.max_abs_q0eff,
            )
            for a in a_out
        ]
    )
    q0_gw = np.array(
        [
            q0star_screened(
                a,
                args.k_gw,
                args.q0star_ligo,
                args.q0star_cosmo,
                args.a_trans,
                args.delta_a,
                args.k_trans,
                args.screening_power,
                time_renorm,
                contrast_gain,
                args.max_abs_q0eff,
            )
            for a in a_out
        ]
    )
    geff_lss = np.array([g_eff_unscreened(a, q0_val, alpha) for a, q0_val in zip(a_out, q0_lss)])
    geff_gw = np.array([g_eff_unscreened(a, q0_val, alpha) for a, q0_val in zip(a_out, q0_gw)])

    s8_unscreened = estimate_s8(args.s8_ref, d_gr[-1], d_unscreened[-1])

    print(f"Screened LSS mode -> S8~{s8_screened:.6f}")
    print(f"Unscreened LIGO-safe mode -> S8~{s8_unscreened:.6f}")
    print(
        "Effective q0* today: "
        f"LSS={q0_lss[-1]:.6e}, GW={q0_gw[-1]:.6e}, "
        f"k_trans={args.k_trans:.3g}, renorm={time_renorm:.3f}, gain={contrast_gain:.3f}"
    )
    print(
        f"Bounded-screening offset from target: DeltaS8={s8_screened - args.s8_target:+.6f}"
    )

    make_plot(
        a_out,
        d_gr,
        d_screened,
        d_unscreened,
        q0_lss,
        q0_gw,
        geff_lss,
        geff_gw,
        s8_screened,
        s8_unscreened,
        contrast_gain,
        args,
        Path(args.out),
    )
    make_mechanism_plot(a_out, q0_lss, q0_gw, args, Path(args.mechanism_fig))
    export_diagnostics_csv(Path(args.csv_out), a_out, q0_lss, q0_gw, geff_lss, geff_gw)
    write_note(
        Path(args.note_out),
        s8_screened,
        args.s8_target,
        contrast_gain,
        args,
        q0_lss[-1],
        q0_gw[-1],
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
