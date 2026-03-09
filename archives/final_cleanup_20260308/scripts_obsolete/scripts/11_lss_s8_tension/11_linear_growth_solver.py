#!/usr/bin/env python3
"""Chapter 11: linear growth solver for the S8 tension baseline."""

from __future__ import annotations

import argparse
import configparser
from pathlib import Path

import numpy as np
from scipy.integrate import solve_ivp


DEFAULT_Q0STAR_BOUND = 1.0e-6
DEFAULT_A_INIT = 1.0e-3
DEFAULT_SCAN_Q0STAR_VALUES = (1.0e-4, -1.0e-4)
DEFAULT_S8_REF = 0.83
DEFAULT_S8_TARGET = 0.77
DEFAULT_REPORT_MD = "assets/zz-data/11_lss_s8_tension/11_s8_resolution_table.md"
DEFAULT_TENSION_FIG = "assets/zz-figures/11_lss_s8_tension/11_tension_confrontation.png"


def parse_q0star_values(raw_values: list[str]) -> list[float]:
    parsed: list[float] = []
    for raw in raw_values:
        for part in raw.split(","):
            item = part.strip()
            if item:
                parsed.append(float(item))
    if not parsed:
        raise argparse.ArgumentTypeError("No q0* values provided.")
    return parsed


def q0star_token(value: float) -> str:
    return f"{value:+.6e}".replace("+", "plus_").replace("-", "minus_").replace(".", "p")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Solve the linear growth equation in flat LCDM and MCGT."
    )
    parser.add_argument(
        "--config",
        default="config/mcgt-global-config.ini",
        help="Path to the central INI config.",
    )
    parser.add_argument(
        "--a-min",
        type=float,
        default=0.01,
        help="Minimum scale factor shown in outputs.",
    )
    parser.add_argument(
        "--a-max",
        type=float,
        default=1.0,
        help="Maximum scale factor shown in outputs.",
    )
    parser.add_argument(
        "--n-a",
        type=int,
        default=400,
        help="Number of evaluation points in a.",
    )
    parser.add_argument(
        "--a-init",
        type=float,
        default=DEFAULT_A_INIT,
        help="Initial scale factor for the ODE integration.",
    )
    parser.add_argument(
        "--alpha",
        type=float,
        help="MCGT alpha value. Defaults to [perturbations] alpha from config.",
    )
    parser.add_argument(
        "--q0star-values",
        type=str,
        nargs="+",
        default=[",".join(f"{value:.6e}" for value in DEFAULT_SCAN_Q0STAR_VALUES)],
        help="q0* values to compare, separated by spaces or commas.",
    )
    parser.add_argument(
        "--s8-ref",
        type=float,
        default=DEFAULT_S8_REF,
        help="Reference LCDM S8 value used for the simple rescaling estimate.",
    )
    parser.add_argument(
        "--s8-target",
        type=float,
        default=DEFAULT_S8_TARGET,
        help="Target S8 value used to identify the tension-resolving q0*.",
    )
    parser.add_argument(
        "--out",
        default="assets/zz-figures/11_lss_s8_tension/11_growth_deviation.png",
        help="Output PNG path.",
    )
    parser.add_argument(
        "--csv-out",
        default="assets/zz-data/11_lss_s8_tension/11_growth_deviation.csv",
        help="Output CSV path with D_GR and relative deviations for all scenarios.",
    )
    parser.add_argument(
        "--report-md",
        default=DEFAULT_REPORT_MD,
        help="Markdown report summarizing q0*, DeltaD/D at a=1, and S8.",
    )
    parser.add_argument(
        "--tension-fig",
        default=DEFAULT_TENSION_FIG,
        help="S8-vs-q0* confrontation figure with the Chapter 10 exclusion zone.",
    )
    args = parser.parse_args()
    args.q0star_values = parse_q0star_values(args.q0star_values)
    return args


def load_cosmology(config_path: Path) -> dict[str, float]:
    cfg = configparser.ConfigParser(
        interpolation=None, inline_comment_prefixes=("#", ";")
    )
    if not cfg.read(config_path, encoding="utf-8"):
        raise FileNotFoundError(f"Cannot read config: {config_path}")

    cmb = cfg["cmb"]
    pert = cfg["perturbations"]

    h0 = cmb.getfloat("h0")
    ombh2 = cmb.getfloat("ombh2")
    omch2 = cmb.getfloat("omch2")
    h = h0 / 100.0
    omega_m0 = (ombh2 + omch2) / (h * h)
    omega_de0 = 1.0 - omega_m0
    if omega_m0 <= 0.0 or omega_de0 <= 0.0:
        raise ValueError("Flat-universe background requires 0 < Omega_m0 < 1")

    return {
        "h0": h0,
        "h": h,
        "omega_m0": omega_m0,
        "omega_de0": omega_de0,
        "alpha": pert.getfloat("alpha"),
    }


def e2_lcdm(a: float, omega_m0: float, omega_de0: float) -> float:
    return omega_m0 * a ** -3 + omega_de0


def dlnh_da(a: float, omega_m0: float, omega_de0: float) -> float:
    e2 = e2_lcdm(a, omega_m0, omega_de0)
    de2_da = -3.0 * omega_m0 * a ** -4
    return 0.5 * de2_da / e2


def omega_m_of_a(a: float, omega_m0: float, omega_de0: float) -> float:
    return omega_m0 * a ** -3 / e2_lcdm(a, omega_m0, omega_de0)


def g_eff(a: float, q0star: float, alpha: float) -> float:
    # Canonical mirage-coupling proxy: the scalar sector enters through a
    # conformal factor e^{2 beta_eff}, so we map it to G_eff / G accordingly.
    alpha_eff = max(alpha, 0.0)
    beta_eff = alpha * q0star * a ** (-alpha_eff)
    return float(np.exp(2.0 * beta_eff))


def growth_rhs(
    a: float,
    y: np.ndarray,
    omega_m0: float,
    omega_de0: float,
    q0star: float,
    alpha: float,
    modified_gravity: bool,
) -> np.ndarray:
    growth, growth_prime = y
    friction = 3.0 / a + dlnh_da(a, omega_m0, omega_de0)
    source = 1.5 * omega_m_of_a(a, omega_m0, omega_de0) / (a * a)
    mu = g_eff(a, q0star, alpha) if modified_gravity else 1.0
    return np.array(
        [
            growth_prime,
            -friction * growth_prime + source * mu * growth,
        ]
    )


def solve_growth(
    a_eval: np.ndarray,
    omega_m0: float,
    omega_de0: float,
    q0star: float,
    alpha: float,
    modified_gravity: bool,
) -> np.ndarray:
    if np.any(np.diff(a_eval) <= 0.0):
        raise ValueError("a_eval must be strictly increasing")
    solution = solve_ivp(
        growth_rhs,
        t_span=(float(a_eval[0]), float(a_eval[-1])),
        y0=np.array([a_eval[0], 1.0]),
        t_eval=a_eval,
        method="RK45",
        rtol=1.0e-8,
        atol=1.0e-10,
        args=(omega_m0, omega_de0, q0star, alpha, modified_gravity),
    )
    if not solution.success:
        raise RuntimeError(f"Growth integration failed: {solution.message}")
    return solution.y[0]


def make_plot(
    a_grid: np.ndarray,
    deviation_curves: list[tuple[float, np.ndarray]],
    alpha: float,
    out_path: Path,
) -> None:
    try:
        import matplotlib.pyplot as plt
        from mpl_toolkits.axes_grid1.inset_locator import inset_axes
    except ImportError as exc:
        raise SystemExit(f"matplotlib missing: {exc}") from exc

    out_path.parent.mkdir(parents=True, exist_ok=True)

    fig, ax = plt.subplots(figsize=(6.8, 4.4))
    colors = plt.rcParams["axes.prop_cycle"].by_key().get(
        "color",
        ["tab:blue", "tab:red", "tab:orange", "tab:green", "tab:purple"],
    )
    for idx, (q0star_value, deviation_percent) in enumerate(deviation_curves):
        color = colors[idx % len(colors)]
        sign_label = "+" if q0star_value > 0.0 else ""
        ax.plot(
            a_grid,
            deviation_percent,
            color=color,
            lw=2.0,
            label=rf"$q_0^*={sign_label}{q0star_value:.0e}$",
        )
    ax.axhline(0.0, color="0.4", ls="--", lw=1.0)
    ax.set_xlabel("Scale factor a")
    ax.set_ylabel(r"$100 \times (D_{\mathrm{MCGT}} - D_{\mathrm{GR}})/D_{\mathrm{GR}}$ [%]")
    ax.set_title("Linear Growth Deviation Near the Present Epoch")
    ax.grid(True, alpha=0.25)
    ax.legend(frameon=False, loc="upper left")
    ax.set_xlim(a_grid[0], a_grid[-1])
    y_min = min(float(np.min(curve)) for _, curve in deviation_curves)
    y_max = max(float(np.max(curve)) for _, curve in deviation_curves)
    if np.isclose(y_min, y_max):
        pad = 0.05 * max(abs(y_max), 1.0)
    else:
        pad = 0.05 * (y_max - y_min)
    ax.set_ylim(y_min - pad, y_max + pad)
    ax.text(
        0.97,
        0.97,
        rf"$\alpha={alpha:.3f}$",
        transform=ax.transAxes,
        va="top",
        ha="right",
        fontsize=9,
    )

    zoom_ax = inset_axes(ax, width="43%", height="43%", loc="lower right")
    for idx, (_, deviation_percent) in enumerate(deviation_curves):
        color = colors[idx % len(colors)]
        zoom_ax.plot(a_grid, deviation_percent, color=color, lw=1.6)
    zoom_ax.set_xlim(0.75, 1.0)
    zoom_mask = a_grid >= 0.75
    zoom_y_min = min(float(np.min(curve[zoom_mask])) for _, curve in deviation_curves)
    zoom_y_max = max(float(np.max(curve[zoom_mask])) for _, curve in deviation_curves)
    zoom_pad = 0.08 * (zoom_y_max - zoom_y_min) if not np.isclose(zoom_y_min, zoom_y_max) else 0.05 * max(abs(zoom_y_max), 1.0)
    zoom_ax.set_ylim(zoom_y_min - zoom_pad, zoom_y_max + zoom_pad)
    zoom_ax.set_title(r"Zoom $z \to 0$", fontsize=8)
    zoom_ax.grid(True, alpha=0.2)
    zoom_ax.tick_params(labelsize=7)

    fig.subplots_adjust(left=0.12, right=0.97, bottom=0.12, top=0.90)
    fig.savefig(out_path, dpi=180)


def save_csv(
    path: Path,
    a_grid: np.ndarray,
    d_gr: np.ndarray,
    deviation_curves: list[tuple[float, np.ndarray]],
) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    columns = [a_grid, d_gr]
    header_parts = ["a", "D_gr"]
    for q0star_value, deviation_percent in deviation_curves:
        columns.append(deviation_percent)
        label = q0star_token(q0star_value)
        header_parts.append(f"delta_percent_q0star_{label}")
    data = np.column_stack(columns)
    header = ",".join(header_parts)
    np.savetxt(path, data, delimiter=",", header=header, comments="")


def estimate_s8(s8_ref: float, d_gr_today: float, d_mcgt_today: float) -> float:
    return s8_ref * d_mcgt_today / d_gr_today


def interpolate_target_q0star(
    rows: list[dict[str, float]],
    s8_target: float,
) -> tuple[float, float] | None:
    ordered = sorted(rows, key=lambda item: item["q0star"])
    for left, right in zip(ordered[:-1], ordered[1:]):
        s8_left = left["s8"]
        s8_right = right["s8"]
        if (s8_left - s8_target) * (s8_right - s8_target) > 0.0:
            continue
        if np.isclose(s8_left, s8_right):
            return left["q0star"], s8_left
        weight = (s8_target - s8_left) / (s8_right - s8_left)
        q0_interp = left["q0star"] + weight * (right["q0star"] - left["q0star"])
        return float(q0_interp), float(s8_target)
    return None


def write_markdown_report(
    path: Path,
    rows: list[dict[str, float]],
    s8_ref: float,
    s8_target: float,
    best_row: dict[str, float],
    chapter10_limit: float,
    interpolated_target: tuple[float, float] | None,
) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        "# Chapter 11 - S8 resolution scan",
        "",
        f"Reference LCDM value: `S8_ref = {s8_ref:.2f}`.",
        f"Target weak-lensing value used here: `S8_target = {s8_target:.2f}`.",
        f"Chapter 10 conservative survival bound: `|q0*| <= {chapter10_limit:.0e}`.",
        "",
        "| q0* | DeltaD/D at a=1 [%] | Final S8 | Facteur de Violation |",
        "|---:|---:|---:|---:|",
    ]
    for row in rows:
        lines.append(
            f"| {row['q0star']:.6e} | {row['delta_percent']:.6f} | {row['s8']:.6f} | {row['violation_factor']:.1f} |"
        )
    lines.extend(
        [
            "",
            "Best value relative to the chosen target:",
            (
                f"`q0* = {best_row['q0star']:.6e}` gives `S8 = {best_row['s8']:.6f}`, "
                f"with `|S8 - S8_target| = {best_row['target_abs_error']:.6f}`."
            ),
            (
                f"This requires `|q0*| / 1e-6 = "
                f"{abs(best_row['q0star']) / chapter10_limit:.1f}` times the Chapter 10 bound."
            ),
        ]
    )
    if interpolated_target is not None:
        lines.extend(
            [
                "",
                "Linear interpolation toward the exact target:",
                (
                    f"`q0* = {interpolated_target[0]:.6e}` gives "
                    f"`S8 = {interpolated_target[1]:.3f}` by interpolation between neighboring scan points."
                ),
                (
                    f"The associated LIGO violation factor is "
                    f"`{abs(interpolated_target[0]) / chapter10_limit:.1f}`."
                ),
            ]
        )
    lines.append("")
    path.write_text("\n".join(lines), encoding="utf-8")


def make_tension_confrontation_plot(
    rows: list[dict[str, float]],
    s8_target: float,
    chapter10_limit: float,
    out_path: Path,
) -> None:
    try:
        import matplotlib.pyplot as plt
    except ImportError as exc:
        raise SystemExit(f"matplotlib missing: {exc}") from exc

    out_path.parent.mkdir(parents=True, exist_ok=True)
    q0_values = np.array([row["q0star"] for row in rows], dtype=float)
    s8_values = np.array([row["s8"] for row in rows], dtype=float)
    order = np.argsort(q0_values)
    q0_values = q0_values[order]
    s8_values = s8_values[order]

    fig, ax = plt.subplots(figsize=(6.8, 4.4))
    ax.plot(q0_values, s8_values, color="tab:blue", lw=2.0, marker="o", ms=4)
    ax.axhline(s8_target, color="tab:red", ls="--", lw=1.2, label=rf"Target $S_8={s8_target:.3f}$")
    ax.axvline(
        -chapter10_limit,
        color="red",
        lw=2.0,
        ls="-",
        label=r"Chapitre 10: $q_0^*=-10^{-6}$",
    )
    ax.axvspan(-chapter10_limit, 0.0, color="0.92", alpha=1.0)
    ax.text(
        0.98,
        0.05,
        "Red line: Chapter 10 limit",
        transform=ax.transAxes,
        ha="right",
        va="bottom",
        fontsize=8,
    )
    ax.set_xlabel(r"$q_0^*$")
    ax.set_ylabel(r"Estimated $S_8$")
    ax.set_title(r"$S_8(q_0^*)$ and Chapter 10 exclusion")
    ax.grid(True, alpha=0.25)
    ax.legend(frameon=False, loc="upper right")
    fig.subplots_adjust(left=0.12, right=0.97, bottom=0.12, top=0.90)
    fig.savefig(out_path, dpi=180)


def main() -> int:
    args = parse_args()
    config = load_cosmology(Path(args.config))

    if args.a_init <= 0.0 or args.a_min <= 0.0:
        raise ValueError("a_init and a_min must be strictly positive")
    if args.a_init > args.a_min:
        raise ValueError("a_init must be <= a_min")
    if args.a_max <= args.a_min:
        raise ValueError("a_max must be > a_min")
    if args.n_a < 10:
        raise ValueError("n_a must be at least 10")

    alpha = config["alpha"] if args.alpha is None else args.alpha
    a_out = np.linspace(args.a_min, args.a_max, args.n_a)
    a_grid = (
        np.concatenate(([args.a_init], a_out))
        if args.a_init < args.a_min
        else a_out
    )
    d_gr_full = solve_growth(
        a_grid,
        config["omega_m0"],
        config["omega_de0"],
        0.0,
        alpha,
        modified_gravity=False,
    )
    d_gr = d_gr_full[-len(a_out) :]
    deviation_curves: list[tuple[float, np.ndarray]] = []
    report_rows: list[dict[str, float]] = []

    for q0star_value in args.q0star_values:
        q0star_signed = float(q0star_value)
        d_mcgt_full = solve_growth(
            a_grid,
            config["omega_m0"],
            config["omega_de0"],
            q0star_signed,
            alpha,
            modified_gravity=True,
        )
        d_mcgt = d_mcgt_full[-len(a_out) :]
        deviation_percent = 100.0 * (d_mcgt - d_gr) / d_gr
        deviation_curves.append((q0star_signed, deviation_percent))

        s8_value = estimate_s8(args.s8_ref, d_gr[-1], d_mcgt[-1])
        s8_shift = s8_value - args.s8_ref
        row = {
            "q0star": q0star_signed,
            "delta_percent": float(deviation_percent[-1]),
            "s8": float(s8_value),
            "delta_s8": float(s8_shift),
            "target_abs_error": abs(float(s8_value) - args.s8_target),
            "violation_factor": abs(q0star_signed) / DEFAULT_Q0STAR_BOUND,
        }
        report_rows.append(row)
        sign_label = "+" if q0star_signed > 0.0 else ""
        print(
            f"q0*={sign_label}{q0star_signed:.0e} -> "
            f"DeltaD/D_GR(a=1)={deviation_percent[-1]:.6f}% ; "
            f"S8~{s8_value:.6f} ; "
            f"DeltaS8={s8_shift:+.6f}"
        )

    best_reducer = min(report_rows, key=lambda item: item["s8"])
    relation = "reduces" if best_reducer["s8"] < args.s8_ref else "does not reduce"
    sign_label = "+" if best_reducer["q0star"] > 0.0 else ""
    print(
        f"Best S8-lowering sign: q0*={sign_label}{best_reducer['q0star']:.0e} "
        f"-> S8~{best_reducer['s8']:.6f} ({relation} vs S8_ref={args.s8_ref:.2f})"
    )

    best_target = min(report_rows, key=lambda item: item["target_abs_error"])
    print(
        f"Closest to S8_target={args.s8_target:.2f}: "
        f"q0*={best_target['q0star']:.6e} -> S8~{best_target['s8']:.6f}"
    )
    print(
        f"Conflict with Chapter 10 bound |q0*|<=1e-06: "
        f"required |q0*|={abs(best_target['q0star']):.6e} "
        f"({abs(best_target['q0star']) / DEFAULT_Q0STAR_BOUND:.1f}x larger)"
    )
    interpolated_target = interpolate_target_q0star(report_rows, args.s8_target)
    if interpolated_target is not None:
        print(
            f"Interpolated q0* for S8={args.s8_target:.3f}: "
            f"{interpolated_target[0]:.6e} "
            f"({abs(interpolated_target[0]) / DEFAULT_Q0STAR_BOUND:.1f}x the Chapter 10 bound)"
        )

    save_csv(Path(args.csv_out), a_out, d_gr, deviation_curves)
    make_plot(a_out, deviation_curves, alpha, Path(args.out))
    write_markdown_report(
        Path(args.report_md),
        report_rows,
        args.s8_ref,
        args.s8_target,
        best_target,
        DEFAULT_Q0STAR_BOUND,
        interpolated_target,
    )
    make_tension_confrontation_plot(
        report_rows,
        args.s8_target,
        DEFAULT_Q0STAR_BOUND,
        Path(args.tension_fig),
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
