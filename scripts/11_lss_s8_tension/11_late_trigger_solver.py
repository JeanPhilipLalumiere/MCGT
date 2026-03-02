#!/usr/bin/env python3
"""Chapter 11: late-trigger MCGT solver for a sharp phase-transition test."""

from __future__ import annotations

import argparse
import configparser
from pathlib import Path

import numpy as np
from scipy.integrate import solve_ivp


DEFAULT_A_INIT = 1.0e-3
DEFAULT_Q0STAR_SAFE = -1.0e-6
DEFAULT_S8_REF = 0.83
DEFAULT_S8_TARGET = 0.77
DEFAULT_A_LOCK = 0.5
DEFAULT_A_TRIGGER = 2.0 / 3.0
DEFAULT_DELTA_A = 0.015
DEFAULT_Q0_MIN = -0.5
DEFAULT_Q0_MAX = -1.0e-3
DEFAULT_Q0_STEPS = 80


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Test a sharp late-time trigger for the Chapter 11 S8 tension."
    )
    parser.add_argument("--config", default="config/mcgt-global-config.ini")
    parser.add_argument("--a-min", type=float, default=0.01)
    parser.add_argument("--a-max", type=float, default=1.0)
    parser.add_argument("--a-init", type=float, default=DEFAULT_A_INIT)
    parser.add_argument("--n-a", type=int, default=500)
    parser.add_argument("--alpha", type=float, help="Override perturbation alpha.")
    parser.add_argument("--q0star-safe", type=float, default=DEFAULT_Q0STAR_SAFE)
    parser.add_argument("--q0-peak-min", type=float, default=DEFAULT_Q0_MIN)
    parser.add_argument("--q0-peak-max", type=float, default=DEFAULT_Q0_MAX)
    parser.add_argument("--q0-steps", type=int, default=DEFAULT_Q0_STEPS)
    parser.add_argument("--a-lock", type=float, default=DEFAULT_A_LOCK)
    parser.add_argument("--a-trigger", type=float, default=DEFAULT_A_TRIGGER)
    parser.add_argument("--delta-a", type=float, default=DEFAULT_DELTA_A)
    parser.add_argument("--s8-ref", type=float, default=DEFAULT_S8_REF)
    parser.add_argument("--s8-target", type=float, default=DEFAULT_S8_TARGET)
    parser.add_argument(
        "--out",
        default="assets/zz-figures/11_lss_s8_tension/11_late_trigger_success.png",
    )
    parser.add_argument(
        "--csv-out",
        default="assets/zz-data/11_lss_s8_tension/11_late_trigger_scan.csv",
    )
    parser.add_argument(
        "--table-out",
        default="assets/zz-data/11_lss_s8_tension/11_final_verdict_table.tex",
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
    turn_on = logistic_step(a, a_trigger, delta_a)
    return q0star_safe + turn_on * (q0star_peak - q0star_safe)


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


def save_scan_csv(path: Path, rows: np.ndarray) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    np.savetxt(
        path,
        rows,
        delimiter=",",
        header="q0_peak,s8,delta_percent_today,q0_early,q0_mid,q0_today",
        comments="",
    )


def make_plot(
    a_out: np.ndarray,
    d_gr: np.ndarray,
    d_safe: np.ndarray,
    d_best: np.ndarray,
    q0_best_curve: np.ndarray,
    best_q0_peak: float,
    s8_best: float,
    args: argparse.Namespace,
    out_path: Path,
) -> None:
    try:
        import matplotlib.pyplot as plt
    except ImportError as exc:
        raise SystemExit(f"matplotlib missing: {exc}") from exc

    out_path.parent.mkdir(parents=True, exist_ok=True)
    dev_safe = 100.0 * (d_safe - d_gr) / d_gr
    dev_best = 100.0 * (d_best - d_gr) / d_gr

    fig, (ax1, ax2) = plt.subplots(
        2, 1, figsize=(7.2, 6.4), sharex=True, gridspec_kw={"height_ratios": [3, 2]}
    )
    ax1.plot(a_out, dev_safe, color="tab:orange", ls="--", lw=2.0, label=r"MCGT LIGO-safe ($q_0^*=-10^{-6}$)")
    ax1.plot(
        a_out,
        dev_best,
        color="tab:blue",
        lw=2.2,
        label=rf"MCGT Late-Trigger (best $q_{{0,\max}}^*={best_q0_peak:.2e}$)",
    )
    ax1.axhline(0.0, color="0.4", ls="--", lw=1.0, label=r"GR / $\Lambda$CDM")
    ax1.axvline(args.a_lock, color="0.5", ls=":", lw=1.0)
    ax1.axvline(args.a_trigger, color="0.2", ls=":", lw=1.0)
    ax1.text(
        0.02,
        0.96,
        rf"$S_8^{{late-trigger}} \approx {s8_best:.3f}$" + "\n" + rf"Target $S_8={args.s8_target:.3f}$",
        transform=ax1.transAxes,
        va="top",
        fontsize=9,
    )
    ax1.set_ylabel(r"$100 \times (D-D_{\rm GR})/D_{\rm GR}$ [%]")
    ax1.set_title("Late-trigger phase transition: abrupt low-z departure from GR")
    ax1.grid(True, alpha=0.25)
    ax1.legend(frameon=False, loc="lower left")

    ax2.plot(a_out, q0_best_curve, color="tab:blue", lw=2.2)
    ax2.axhline(args.q0star_safe, color="tab:red", ls="--", lw=1.0, label=r"LIGO-safe floor")
    ax2.axvline(args.a_lock, color="0.5", ls=":", lw=1.0, label=rf"$a_{{lock}}={args.a_lock:.2f}$")
    ax2.axvline(args.a_trigger, color="0.2", ls=":", lw=1.0, label=rf"$a_{{trigger}}={args.a_trigger:.2f}$")
    ax2.set_xlabel("Scale factor a")
    ax2.set_ylabel(r"$q_0^*(a)$")
    ax2.grid(True, alpha=0.25)
    ax2.legend(frameon=False, loc="lower left")
    fig.subplots_adjust(left=0.12, right=0.98, bottom=0.10, top=0.93, hspace=0.08)
    fig.savefig(out_path, dpi=180)


def write_final_table(path: Path, s8_ligo_safe: float, s8_chameleon: float, best_q0_peak: float, s8_best: float) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    content = f"""\\begin{{table}}[htbp]
\\centering
\\caption{{Verdict final des tests de screening du Chapitre 11.}}
\\label{{tab:ch11_final_verdict}}
\\begin{{tabular}}{{llll}}
\\toprule
Scénario & Prescription & Statut local / cosmologique & $S_8$ final \\\\
\\midrule
$\\Lambda$CDM & GR standard & référence & $0.83$ \\\\
MCGT LIGO-Safe & $q_0^*=-10^{{-6}}$ constant & conforme à la borne GW, pas d'effet LSS & $\\approx {s8_ligo_safe:.3f}$ \\\\
MCGT Chameleon & $q_0^*(a) \\propto (\\rho_{{crit}}/\\rho_m)^n$ & borne précoce respectée, transition trop lente & $\\approx {s8_chameleon:.3f}$ \\\\
MCGT Late-Trigger & transition logistique tardive vers $q_{{0,\\max}}^*={best_q0_peak:.2e}$ & verrouillé longtemps puis activation brutale & $\\approx {s8_best:.3f}$ \\\\
\\bottomrule
\\end{{tabular}}
\\end{{table}}
"""
    path.write_text(content, encoding="utf-8")


def main() -> int:
    args = parse_args()
    config = load_cosmology(Path(args.config))
    alpha = config["alpha"] if args.alpha is None else args.alpha

    a_out = np.linspace(args.a_min, args.a_max, args.n_a)
    a_grid = np.concatenate(([args.a_init], a_out)) if args.a_init < args.a_min else a_out

    d_gr = solve_growth(a_grid, config["omega_m0"], config["omega_de0"], lambda a: 1.0)[-len(a_out) :]

    d_safe = solve_growth(
        a_grid,
        config["omega_m0"],
        config["omega_de0"],
        lambda a: g_eff(a, args.q0star_safe, alpha),
    )[-len(a_out) :]
    s8_safe = estimate_s8(args.s8_ref, d_gr[-1], d_safe[-1])

    q0_peaks = np.linspace(args.q0_peak_min, args.q0_peak_max, args.q0_steps)
    rows = []
    best_idx = 0
    best_error = float("inf")
    best_d = d_safe
    best_curve = np.full_like(a_out, args.q0star_safe)
    best_s8 = s8_safe

    for idx, q0_peak in enumerate(q0_peaks):
        q0_curve = np.array(
            [
                q0star_late_trigger(
                    a,
                    args.q0star_safe,
                    q0_peak,
                    args.a_lock,
                    args.a_trigger,
                    args.delta_a,
                )
                for a in a_out
            ]
        )
        mu_fn = lambda a, peak=q0_peak: g_eff(
            a,
            q0star_late_trigger(
                a,
                args.q0star_safe,
                peak,
                args.a_lock,
                args.a_trigger,
                args.delta_a,
            ),
            alpha,
        )
        d_model = solve_growth(a_grid, config["omega_m0"], config["omega_de0"], mu_fn)[-len(a_out) :]
        s8_model = estimate_s8(args.s8_ref, d_gr[-1], d_model[-1])
        delta_today = 100.0 * (d_model[-1] - d_gr[-1]) / d_gr[-1]
        q0_early = q0star_late_trigger(args.a_init, args.q0star_safe, q0_peak, args.a_lock, args.a_trigger, args.delta_a)
        q0_mid = q0star_late_trigger(0.6, args.q0star_safe, q0_peak, args.a_lock, args.a_trigger, args.delta_a)
        q0_today = q0star_late_trigger(1.0, args.q0star_safe, q0_peak, args.a_lock, args.a_trigger, args.delta_a)
        rows.append([q0_peak, s8_model, delta_today, q0_early, q0_mid, q0_today])

        error = abs(s8_model - args.s8_target)
        if error < best_error:
            best_error = error
            best_idx = idx
            best_d = d_model
            best_curve = q0_curve
            best_s8 = s8_model

    rows_arr = np.asarray(rows, dtype=float)
    best_q0_peak = float(q0_peaks[best_idx])

    print(
        f"Best late-trigger peak -> q0_peak={best_q0_peak:.6e}, "
        f"S8~{best_s8:.6f}, "
        f"q0early={rows_arr[best_idx, 3]:.6e}, q0today={rows_arr[best_idx, 5]:.6e}"
    )

    save_scan_csv(Path(args.csv_out), rows_arr)
    make_plot(a_out, d_gr, d_safe, best_d, best_curve, best_q0_peak, best_s8, args, Path(args.out))
    write_final_table(
        Path(args.table_out),
        s8_safe,
        0.829667,
        best_q0_peak,
        best_s8,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
