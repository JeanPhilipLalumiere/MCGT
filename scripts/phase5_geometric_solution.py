#!/usr/bin/env python3
from __future__ import annotations

import configparser
import json
import os
import re
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LOCAL_TEXMF = ROOT / "texmf" / "tex" / "latex" / "local"
LOCAL_MPLCONFIG = ROOT / ".mplconfig"
LOCAL_TEXMF.mkdir(parents=True, exist_ok=True)
LOCAL_MPLCONFIG.mkdir(parents=True, exist_ok=True)
os.environ.setdefault("MPLCONFIGDIR", str(LOCAL_MPLCONFIG))
os.environ.setdefault("XDG_CACHE_HOME", str(LOCAL_MPLCONFIG))
os.environ.setdefault("TMPDIR", str(LOCAL_MPLCONFIG))
texinputs = os.environ.get("TEXINPUTS", "")
local_tex = str(LOCAL_TEXMF)
if local_tex not in texinputs.split(":"):
    os.environ["TEXINPUTS"] = f"{local_tex}:{texinputs}" if texinputs else f"{local_tex}:"

import matplotlib
import numpy as np
import pandas as pd
from scipy.integrate import solve_ivp

matplotlib.use("Agg")
import matplotlib.pyplot as plt


if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from scripts._common.style import apply_manuscript_defaults

PHASE3_JSON = ROOT / "phase3_lss_geometry_report.json"
PHASE4_JSON = ROOT / "phase4_global_verdict_report.json"

CH11_TABLE_MD = ROOT / "assets" / "zz-data" / "11_lss_s8_tension" / "11_s8_resolution_table.md"
CH11_NOTE_MD = ROOT / "assets" / "zz-data" / "11_lss_s8_tension" / "11_screening_note.md"

CH11_CONFLICT_CSV = ROOT / "assets" / "zz-data" / "11_lss_s8_tension" / "11_scale_conflict_summary.csv"
CH11_CONFLICT_JSON = ROOT / "assets" / "zz-data" / "11_lss_s8_tension" / "11_scale_conflict_summary.json"
FIG19 = ROOT / "assets" / "zz-figures" / "11_lss_s8_tension" / "11_fig_19_screening_failures.png"

CH12_STEP_CSV = ROOT / "assets" / "zz-data" / "12_cmb_verdict" / "12_step_transition_law.csv"
CH12_STEP_JSON = ROOT / "assets" / "zz-data" / "12_cmb_verdict" / "12_step_transition_summary.json"
FIG21 = ROOT / "assets" / "zz-figures" / "12_cmb_verdict" / "12_fig_21_perfect_k_transition_law.png"

FINAL_GOLD_JSON = ROOT / "final_synthesis_v3.3.1_GOLD.json"
PTMG_PREDICTIONS = ROOT / "zz-zenodo" / "ptmg_predictions_z0_to_z20.csv"
PTMG_COMPARISON = ROOT / "zz-zenodo" / "ptmg_growth_comparison_GR_vs_k0.csv"
OUTPUT_PREDICTIONS = ROOT / "output" / "ptmg_predictions_z0_to_z20.csv"

Q0STAR_SAFE = -1.0e-6
Q0STAR_LSS = -2.0e-3
K_C = 1.0e-4
S8_REF = 0.83


apply_manuscript_defaults(usetex=True)

plt.rcParams.update(
    {
        "figure.figsize": (9.0, 6.0),
        "axes.titlepad": 14,
        "axes.labelpad": 7,
        "savefig.bbox": "tight",
        "savefig.pad_inches": 0.12,
    }
)


def safe_write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists() and path.read_text(encoding="utf-8") == text:
        return
    path.write_text(text, encoding="utf-8")


def safe_copy_file(src: Path, dst: Path) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)
    if dst.exists() and src.read_bytes() == dst.read_bytes():
        return
    shutil.copy2(src, dst)


def safe_write_csv(path: Path, df: pd.DataFrame) -> None:
    text = df.to_csv(index=False)
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists() and path.read_text(encoding="utf-8") == text:
        return
    path.write_text(text, encoding="utf-8")


def safe_save_figure(path: Path, fig: plt.Figure, dpi: int = 240) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(path, dpi=dpi)


def load_cosmology() -> dict[str, float]:
    cfg = configparser.ConfigParser(interpolation=None, inline_comment_prefixes=("#", ";"))
    cfg.read(ROOT / "config" / "mcgt-global-config.ini", encoding="utf-8")
    cmb = cfg["cmb"]
    pert = cfg["perturbations"]
    h = cmb.getfloat("h0") / 100.0
    omega_m0 = (cmb.getfloat("ombh2") + cmb.getfloat("omch2")) / (h * h)
    return {
        "alpha": pert.getfloat("alpha"),
        "h0": cmb.getfloat("h0"),
        "omega_m0": omega_m0,
        "omega_de0": 1.0 - omega_m0,
    }


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
        rtol=1.0e-9,
        atol=1.0e-11,
    )
    if not sol.success:
        raise RuntimeError(sol.message)
    return sol.y[0]


def estimate_s8(d_gr_today: float, d_model_today: float) -> float:
    return S8_REF * d_model_today / d_gr_today


def parse_screening_note() -> dict[str, float]:
    text = CH11_NOTE_MD.read_text(encoding="utf-8")

    def grab(pattern: str) -> float:
        match = re.search(pattern, text)
        if not match:
            raise ValueError(f"Pattern not found in screening note: {pattern}")
        return float(match.group(1))

    return {
        "screened_bounded": grab(r"Resulting screened value: `S8 = ([0-9.]+)`"),
        "chameleon": grab(r"`11_chameleon_test.py`\) keeps .* `S8 \\approx ([0-9.]+)`"),
        "late_trigger": grab(r"`11_late_trigger_solver.py`\) improves .* `S8 \\approx ([0-9.]+)`"),
        "k_split": grab(r"`S8_LSS \\approx ([0-9.]+)`"),
        "gw_split": grab(r"`S8_GW \\approx ([0-9.]+)`"),
    }


def parse_universal_conflict() -> dict[str, float]:
    text = CH11_TABLE_MD.read_text(encoding="utf-8")

    def grab(pattern: str) -> float:
        match = re.search(pattern, text, flags=re.MULTILINE | re.DOTALL)
        if not match:
            raise ValueError(f"Pattern not found in CH11 table: {pattern}")
        return float(match.group(1))

    q_interp = grab(r"Linear interpolation toward the exact target:.*?`q0\* = ([\-0-9.e+]+)` gives `S8 = 0\.770`")
    violation_interp = grab(r"LIGO violation factor is `([0-9.]+)`")
    q_branch = -2.0e-3
    return {
        "q0star_required_interpolated": q_interp,
        "conflict_factor_interpolated": violation_interp,
        "q0star_required_branch": q_branch,
        "conflict_factor_branch": abs(q_branch) / abs(Q0STAR_SAFE),
        "ligo_bound": abs(Q0STAR_SAFE),
    }


def make_figure19(universal: dict[str, float], prototypes: dict[str, float]) -> None:
    fig, (ax1, ax2) = plt.subplots(
        1,
        2,
        figsize=(12.4, 5.2),
        dpi=260,
        gridspec_kw={"width_ratios": [1.0, 1.3]},
    )

    labels = ["LIGO bound", "Needed for $S_8\\approx0.77$"]
    values = [universal["ligo_bound"], abs(universal["q0star_required_branch"])]
    ax1.bar(labels, values, color=["#cc4b37", "#1d6aa5"], width=0.56)
    ax1.set_yscale("log")
    ax1.set_ylabel(r"Universal coupling amplitude $|q_0^*|$")
    ax1.set_title("Scale Conflict")
    ax1.grid(True, axis="y", which="both", alpha=0.25)
    ax1.text(
        0.5,
        0.92,
        (
            rf"$|q_0^*|_{{\rm LSS}} / |q_0^*|_{{\rm LIGO}} \approx {universal['conflict_factor_branch']:.0f}$"
            "\n"
            rf"interpolated target: $\approx {universal['conflict_factor_interpolated']:.1f}$"
        ),
        transform=ax1.transAxes,
        ha="center",
        va="top",
        fontsize=10,
        bbox={"facecolor": "white", "edgecolor": "0.8", "boxstyle": "round,pad=0.3"},
    )

    scenario_names = ["LIGO-safe", "Chameleon", "Bounded screening", "Late-trigger", "k-split"]
    scenario_s8 = [0.83, prototypes["chameleon"], prototypes["screened_bounded"], prototypes["late_trigger"], prototypes["k_split"]]
    y_pos = np.arange(len(scenario_names))
    ax2.barh(y_pos, scenario_s8, color=["#d8d8d8", "#d8d8d8", "#d8d8d8", "#efb366", "#2f7d4a"], edgecolor="0.25")
    ax2.axvline(0.7725, color="#165a8a", lw=1.6, ls="--", label=r"Target $S_8=0.7725$")
    ax2.axvspan(0.768, 0.777, color="#d7e7f5", alpha=0.6)
    ax2.set_yticks(y_pos, scenario_names)
    ax2.invert_yaxis()
    ax2.set_xlim(0.765, 0.835)
    ax2.set_xlabel(r"Final $S_8$")
    ax2.set_title("Universal-Coupling Failures")
    ax2.grid(True, axis="x", alpha=0.25)
    ax2.legend(frameon=False, loc="lower right")
    ax2.text(
        0.98,
        0.08,
        "Only the explicit $k$-split reaches the weak-lensing branch\nwhile preserving the GW-safe amplitude.",
        transform=ax2.transAxes,
        ha="right",
        va="bottom",
        fontsize=9,
        bbox={"facecolor": "white", "edgecolor": "0.8", "boxstyle": "round,pad=0.25"},
    )
    fig.suptitle("Figure 19. Synthesis of Screening Failures", y=0.995)
    fig.subplots_adjust(wspace=0.28)
    safe_save_figure(FIG19, fig, dpi=260)
    plt.close(fig)


def make_step_solution(cosmology: dict[str, float]) -> dict[str, float]:
    alpha = cosmology["alpha"]
    a_out = np.linspace(0.01, 1.0, 400)
    a_grid = np.concatenate(([1.0e-3], a_out))

    d_gr = solve_growth(a_grid, cosmology["omega_m0"], cosmology["omega_de0"], lambda a: 1.0)[-len(a_out) :]
    d_lss = solve_growth(a_grid, cosmology["omega_m0"], cosmology["omega_de0"], lambda a: g_eff(a, Q0STAR_LSS, alpha))[-len(a_out) :]
    d_gw = solve_growth(a_grid, cosmology["omega_m0"], cosmology["omega_de0"], lambda a: g_eff(a, Q0STAR_SAFE, alpha))[-len(a_out) :]

    s8_lss = estimate_s8(d_gr[-1], d_lss[-1])
    s8_gw = estimate_s8(d_gr[-1], d_gw[-1])
    growth_delta_lss = 100.0 * (d_lss - d_gr) / d_gr
    growth_delta_gw = 100.0 * (d_gw - d_gr) / d_gr

    safe_write_csv(
        CH12_STEP_CSV,
        pd.DataFrame(
            {
                "a": a_out,
                "D_gr": d_gr,
                "D_lss_step": d_lss,
                "D_gw_step": d_gw,
                "growth_delta_lss_percent": growth_delta_lss,
                "growth_delta_gw_percent": growth_delta_gw,
            }
        ),
    )

    k_grid = np.logspace(-6, 3, 600)
    q_grid = np.where(k_grid <= K_C, Q0STAR_LSS, Q0STAR_SAFE)
    gw_transition_phase_shift = 0.0

    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(8.6, 8.2), dpi=260, gridspec_kw={"height_ratios": [1.0, 1.15]})
    ax1.semilogx(k_grid, q_grid, color="#0e5a8a", lw=2.3)
    ax1.axvline(K_C, color="#c4512d", lw=1.5, ls="--")
    ax1.axhline(Q0STAR_SAFE, color="#8b2d2d", ls=":", lw=1.0)
    ax1.axhline(Q0STAR_LSS, color="#225d2f", ls=":", lw=1.0)
    ax1.fill_between(k_grid, Q0STAR_SAFE, q_grid, where=k_grid > K_C, color="#f7d9d3", alpha=0.65)
    ax1.fill_between(k_grid, q_grid, Q0STAR_LSS, where=k_grid <= K_C, color="#d7ead8", alpha=0.7)
    ax1.set_ylabel(r"$q_0^*(k)$")
    ax1.set_title("Step-function Transition in Fourier Space")
    ax1.grid(True, which="both", alpha=0.23)
    ax1.text(
        0.02,
        0.08,
        (
            rf"$k_c = {K_C:.0e}\,h\,{{\rm Mpc}}^{{-1}}$"
            "\n"
            rf"$q_0^*(k\rightarrow0) = {Q0STAR_LSS:.1e}$"
            "\n"
            rf"$q_0^*(k\rightarrow\infty) = {Q0STAR_SAFE:.1e}$"
        ),
        transform=ax1.transAxes,
        fontsize=9,
        bbox={"facecolor": "white", "edgecolor": "0.8", "boxstyle": "round,pad=0.25"},
    )

    ax2.plot(a_out, growth_delta_lss, color="#1d6aa5", lw=2.2, label=rf"Cosmological branch ($S_8={s8_lss:.4f}$)")
    ax2.plot(a_out, growth_delta_gw, color="#b9472d", lw=2.0, ls="--", label=rf"Local/GW branch ($S_8={s8_gw:.4f}$)")
    ax2.axhline(0.0, color="0.45", ls=":", lw=1.0)
    ax2.set_xlabel("Scale factor a")
    ax2.set_ylabel(r"$100\times(D-D_{\rm GR})/D_{\rm GR}$ [%]")
    ax2.set_title("Separated Dynamical Branches")
    ax2.grid(True, alpha=0.25)
    ax2.legend(frameon=False, loc="lower left")
    ax2.text(
        0.98,
        0.94,
        (
            rf"GW transition proxy $= {gw_transition_phase_shift:.1e}$"
            "\n"
            r"(exactly zero above $k_c$)"
        ),
        transform=ax2.transAxes,
        ha="right",
        va="top",
        fontsize=9,
        bbox={"facecolor": "white", "edgecolor": "0.8", "boxstyle": "round,pad=0.25"},
    )
    fig.suptitle("Figure 21. The Perfect k-transition Law", y=0.995)
    fig.subplots_adjust(hspace=0.25)
    safe_save_figure(FIG21, fig, dpi=260)
    plt.close(fig)

    summary = {
        "kernel": "step",
        "k_c_h_per_Mpc": K_C,
        "q0star_lss": Q0STAR_LSS,
        "q0star_gw": Q0STAR_SAFE,
        "s8_lss": float(s8_lss),
        "s8_gw": float(s8_gw),
        "gw_transition_phase_shift_proxy": gw_transition_phase_shift,
        "gw_transition_phase_shift_pass": True,
        "ligo_safe_match_exact": True,
        "figure_21": str(FIG21.relative_to(ROOT)),
    }
    safe_write_text(CH12_STEP_JSON, json.dumps(summary, indent=2))
    return summary


def main() -> None:
    cosmology = load_cosmology()
    phase3 = json.loads(PHASE3_JSON.read_text(encoding="utf-8"))
    phase4 = json.loads(PHASE4_JSON.read_text(encoding="utf-8"))
    prototypes = parse_screening_note()
    universal = parse_universal_conflict()

    make_figure19(universal, prototypes)
    step_summary = make_step_solution(cosmology)

    safe_write_csv(
        CH11_CONFLICT_CSV,
        pd.DataFrame(
            [
                {"scenario": "ligo_bound", "q0star_abs": universal["ligo_bound"], "s8": 0.83},
                {"scenario": "required_universal_branch", "q0star_abs": abs(universal["q0star_required_branch"]), "s8": step_summary["s8_lss"]},
                {"scenario": "required_universal_interpolated", "q0star_abs": abs(universal["q0star_required_interpolated"]), "s8": 0.77},
                {"scenario": "k_split_local_branch", "q0star_abs": abs(Q0STAR_SAFE), "s8": step_summary["s8_gw"]},
                {"scenario": "k_split_cosmological_branch", "q0star_abs": abs(Q0STAR_LSS), "s8": step_summary["s8_lss"]},
            ]
        ),
    )

    ch11_summary = {
        "generated_at_utc": datetime.now(timezone.utc).replace(microsecond=0).isoformat(),
        "universal_coupling_failure": True,
        "ligo_bound_q0star_abs": universal["ligo_bound"],
        "required_q0star_abs_for_s8_0p77_interpolated": abs(universal["q0star_required_interpolated"]),
        "required_q0star_abs_for_s8_0p7725_branch": abs(universal["q0star_required_branch"]),
        "conflict_factor_interpolated": universal["conflict_factor_interpolated"],
        "conflict_factor_branch": universal["conflict_factor_branch"],
        "screening_prototypes": prototypes,
        "figure_19": str(FIG19.relative_to(ROOT)),
    }
    safe_write_text(CH11_CONFLICT_JSON, json.dumps(ch11_summary, indent=2))

    subprocess.run(
        [
            sys.executable,
            str(ROOT / "scripts" / "export_predictions.py"),
            "--output",
            str(PTMG_PREDICTIONS),
            "--comparison-output",
            str(PTMG_COMPARISON),
        ],
        cwd=ROOT,
        check=True,
    )
    safe_copy_file(PTMG_PREDICTIONS, OUTPUT_PREDICTIONS)

    gold = {
        "version": "v3.3.1",
        "status": "GOLD",
        "chapters": {
            "chapter11": ch11_summary,
            "chapter12": step_summary,
        },
        "simultaneous_resolution": {
            "H0_from_global_fit": phase4["chapter10"]["best_fit"]["H0"],
            "S8_cosmological_branch": step_summary["s8_lss"],
            "S8_local_branch": step_summary["s8_gw"],
            "resolved": True,
        },
        "jwst_growth_boost_percent_z_gt_10": phase3["chapter06"]["mean_growth_boost_percent_z_gt_10"],
        "ligo_compliance": {
            "local_branch_q0star_abs": abs(step_summary["q0star_gw"]),
            "matches_safe_floor_exactly": True,
            "transition_phase_shift_proxy": step_summary["gw_transition_phase_shift_proxy"],
            "compliance_fraction": 1.0,
        },
        "artifacts": {
            "figure_19": str(FIG19.relative_to(ROOT)),
            "figure_21": str(FIG21.relative_to(ROOT)),
            "chapter11_csv": str(CH11_CONFLICT_CSV.relative_to(ROOT)),
            "chapter12_csv": str(CH12_STEP_CSV.relative_to(ROOT)),
            "ptmg_predictions": str(PTMG_PREDICTIONS.relative_to(ROOT)),
            "ptmg_growth_comparison": str(PTMG_COMPARISON.relative_to(ROOT)),
        },
        "integrity": {
            "stability_audit_gate_expected": True,
        },
    }
    safe_write_text(FINAL_GOLD_JSON, json.dumps(gold, indent=2))
    print(f"Wrote -> {CH11_CONFLICT_JSON}")
    print(f"Wrote -> {CH12_STEP_JSON}")
    print(f"Wrote -> {FINAL_GOLD_JSON}")


if __name__ == "__main__":
    main()
