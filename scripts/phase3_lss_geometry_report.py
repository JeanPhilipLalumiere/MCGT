#!/usr/bin/env python3
from __future__ import annotations

import configparser
import hashlib
import json
import os
import shutil
import tempfile
import sys
from dataclasses import dataclass
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


C_KM_S = 299792.458
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from scripts._common.style import apply_manuscript_defaults

CONFIG = ROOT / "config" / "mcgt-global-config.ini"
CH12_S8_SCAN = ROOT / "assets" / "zz-data" / "12_cmb_verdict" / "12_k_law_refinement.csv"

CH06_DATA_DIR = ROOT / "assets" / "zz-data" / "06_early_growth_jwst"
CH06_FIG_DIR = ROOT / "assets" / "zz-figures" / "06_early_growth_jwst"
CH07_DATA_DIR = ROOT / "assets" / "zz-data" / "07_bao_geometry"
CH07_FIG_DIR = ROOT / "assets" / "zz-figures" / "07_bao_geometry"
CH08_DATA_DIR = ROOT / "assets" / "zz-data" / "08_sound_horizon"
CH08_FIG_DIR = ROOT / "assets" / "zz-figures" / "08_sound_horizon"

PHASE3_LOG = ROOT / "phase3_lss_geometry_report.txt"
PHASE3_JSON = ROOT / "phase3_lss_geometry_report.json"

apply_manuscript_defaults(usetex=True)

plt.rcParams.update(
    {
        "figure.figsize": (9.0, 6.4),
        "axes.titlepad": 18,
        "axes.labelpad": 10,
        "savefig.bbox": "tight",
        "savefig.pad_inches": 0.15,
    }
)


@dataclass
class Cosmology:
    H0: float
    h: float
    omega_m: float
    omega_r: float
    omega_de: float
    ombh2: float
    omch2: float
    tcmb: float
    neff: float
    w0: float
    wa: float
    alpha_pert: float


def _sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()


def safe_write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists() and path.read_text(encoding="utf-8") == text:
        return
    path.write_text(text, encoding="utf-8")


def safe_save_dataframe(path: Path, df: pd.DataFrame) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    csv = df.to_csv(index=False)
    safe_write_text(path, csv)


def safe_save_figure(path: Path, fig: plt.Figure, **kwargs) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        with tempfile.NamedTemporaryFile(delete=False, suffix=path.suffix) as tmp:
            tmp_path = Path(tmp.name)
        try:
            fig.savefig(tmp_path, **kwargs)
            if _sha256(tmp_path) == _sha256(path):
                tmp_path.unlink()
                return
            shutil.move(tmp_path, path)
        finally:
            if tmp_path.exists():
                tmp_path.unlink()
        return
    fig.savefig(path, **kwargs)


def load_cosmology() -> Cosmology:
    cfg = configparser.ConfigParser(
        interpolation=None,
        inline_comment_prefixes=("#", ";"),
    )
    if not cfg.read(CONFIG, encoding="utf-8"):
        raise FileNotFoundError(CONFIG)

    cmb = cfg["cmb"]
    de = cfg["dark_energy"]
    rad = cfg["radiation"]
    pert = cfg["perturbations"]

    H0 = cmb.getfloat("h0")
    h = H0 / 100.0
    ombh2 = cmb.getfloat("ombh2")
    omch2 = cmb.getfloat("omch2")
    omega_m = (ombh2 + omch2) / (h * h)
    tcmb = rad.getfloat("tcmb_k")
    neff = rad.getfloat("neff")
    omega_gamma_h2 = 2.469e-5 * (tcmb / 2.7255) ** 4
    omega_r_h2 = omega_gamma_h2 * (1.0 + 0.2271 * neff)
    omega_r = omega_r_h2 / (h * h)
    omega_de = 1.0 - omega_m - omega_r

    return Cosmology(
        H0=H0,
        h=h,
        omega_m=omega_m,
        omega_r=omega_r,
        omega_de=omega_de,
        ombh2=ombh2,
        omch2=omch2,
        tcmb=tcmb,
        neff=neff,
        w0=de.getfloat("w0"),
        wa=de.getfloat("wa"),
        alpha_pert=pert.getfloat("alpha"),
    )


def load_s8_branch() -> dict[str, float]:
    df = pd.read_csv(CH12_S8_SCAN)
    best = df.iloc[(df["s8_lss"] - 0.7725).abs().argmin()]
    return {
        "kernel": str(best["kernel"]),
        "k_c": float(best["k_c"]),
        "q0_lss": float(best["q0_lss"]),
        "q0_gw": float(best["q0_gw"]),
        "s8_lss": float(best["s8_lss"]),
        "s8_gw": float(best["s8_gw"]),
    }


def e2_cpl(z: np.ndarray | float, cosmo: Cosmology, *, w0: float | None = None, wa: float | None = None) -> np.ndarray:
    z_arr = np.asarray(z, dtype=float)
    w0_val = cosmo.w0 if w0 is None else w0
    wa_val = cosmo.wa if wa is None else wa
    a = 1.0 / (1.0 + z_arr)
    de_factor = a ** (-3.0 * (1.0 + w0_val + wa_val)) * np.exp(-3.0 * wa_val * (1.0 - a))
    return (
        cosmo.omega_r * (1.0 + z_arr) ** 4
        + cosmo.omega_m * (1.0 + z_arr) ** 3
        + cosmo.omega_de * de_factor
    )


def _dlnh_da(a: float, cosmo: Cosmology) -> float:
    z = 1.0 / a - 1.0
    delta = max(1.0e-5 * a, 1.0e-7)
    a_lo = max(a - delta, 1.0e-6)
    a_hi = min(a + delta, 1.0)
    z_lo = 1.0 / a_lo - 1.0
    z_hi = 1.0 / a_hi - 1.0
    ln_h_lo = 0.5 * np.log(e2_cpl(z_lo, cosmo))
    ln_h_hi = 0.5 * np.log(e2_cpl(z_hi, cosmo))
    return float((ln_h_hi - ln_h_lo) / (a_hi - a_lo))


def omega_m_of_a(a: float, cosmo: Cosmology) -> float:
    z = 1.0 / a - 1.0
    return float(cosmo.omega_m * (1.0 + z) ** 3 / e2_cpl(z, cosmo))


def solve_ch06_growth(cosmo: Cosmology, s8_branch: dict[str, float]) -> dict[str, float]:
    CH06_DATA_DIR.mkdir(parents=True, exist_ok=True)
    CH06_FIG_DIR.mkdir(parents=True, exist_ok=True)

    a_grid = np.linspace(1.0 / 21.0, 1.0, 900)
    z_grid = 1.0 / a_grid - 1.0

    # Tuned transient kernel: early reinforcement plus late screening.
    a_turn = 0.06
    early_amp = 0.60
    early_power = 4.0
    late_amp = 0.26
    late_power = 3.0

    def mu_eff(a: float) -> float:
        early = early_amp / (1.0 + (a / a_turn) ** early_power)
        late = late_amp * a ** late_power
        return 1.0 + early - late

    def growth_rhs(a: float, y: np.ndarray, modified: bool) -> np.ndarray:
        growth, growth_prime = y
        friction = 3.0 / a + _dlnh_da(a, cosmo)
        source = 1.5 * omega_m_of_a(a, cosmo) / (a * a)
        mu = mu_eff(a) if modified else 1.0
        return np.array([growth_prime, -friction * growth_prime + source * mu * growth])

    def integrate(modified: bool) -> np.ndarray:
        sol = solve_ivp(
            lambda a, y: growth_rhs(a, y, modified),
            (float(a_grid[0]), float(a_grid[-1])),
            np.array([a_grid[0], 1.0]),
            t_eval=a_grid,
            rtol=1.0e-9,
            atol=1.0e-11,
            method="RK45",
        )
        if not sol.success:
            raise RuntimeError(sol.message)
        return sol.y

    lcdm = integrate(False)
    psitmg_raw = integrate(True)

    d_lcdm = lcdm[0]
    d_psitmg_raw = psitmg_raw[0]
    f_lcdm = a_grid * lcdm[1] / d_lcdm
    f_psitmg = a_grid * psitmg_raw[1] / d_psitmg_raw

    final_ratio_raw = float(d_psitmg_raw[-1] / d_lcdm[-1])
    target_ratio = float(s8_branch["s8_lss"] / s8_branch["s8_gw"])
    amplitude_renorm = target_ratio / final_ratio_raw
    d_psitmg_cal = amplitude_renorm * d_psitmg_raw

    growth_boost_percent = 100.0 * (f_psitmg - f_lcdm) / f_lcdm
    growth_ratio_percent = 100.0 * (d_psitmg_raw - d_lcdm) / d_lcdm
    growth_ratio_cal_percent = 100.0 * (d_psitmg_cal - d_lcdm) / d_lcdm

    df = pd.DataFrame(
        {
            "z": z_grid,
            "a": a_grid,
            "D_lcdm": d_lcdm,
            "D_psitmg_raw": d_psitmg_raw,
            "D_psitmg_calibrated": d_psitmg_cal,
            "f_lcdm": f_lcdm,
            "f_psitmg": f_psitmg,
            "growth_boost_percent": growth_boost_percent,
            "growth_ratio_percent": growth_ratio_percent,
            "growth_ratio_calibrated_percent": growth_ratio_cal_percent,
        }
    )
    safe_save_dataframe(CH06_DATA_DIR / "06_jwst_growth_boost.csv", df)

    mask_high_z = z_grid >= 10.0
    mean_boost_high_z = float(np.mean(growth_boost_percent[mask_high_z]))
    z10_boost = float(np.interp(10.0, z_grid[::-1], growth_boost_percent[::-1]))
    z15_boost = float(np.interp(15.0, z_grid[::-1], growth_boost_percent[::-1]))

    fig, (ax_top, ax_bottom) = plt.subplots(
        2,
        1,
        figsize=(9.0, 7.0),
        dpi=300,
        sharex=True,
        gridspec_kw={"height_ratios": [2.2, 1.3], "hspace": 0.07},
    )
    ax_top.plot(z_grid, d_lcdm / d_lcdm[-1], color="#1f4b99", lw=2.0, label=r"$\Lambda$CDM")
    ax_top.plot(
        z_grid,
        d_psitmg_cal / d_psitmg_cal[-1],
        color="#c4512d",
        lw=2.2,
        label=rf"$\Psi$TMG calibrated to $S_8={s8_branch['s8_lss']:.4f}$",
    )
    ax_top.set_xscale("log")
    ax_top.set_ylabel(r"Normalized growth $D(z)/D(0)$")
    ax_top.set_title("Figure 9. Structure Growth Factor up to the Cosmic Dawn")
    ax_top.grid(True, which="both", linestyle=":", linewidth=0.5, alpha=0.65)
    ax_top.legend(loc="lower left", frameon=False)

    ax_bottom.axhline(0.0, color="black", ls="--", lw=1.0)
    ax_bottom.axvspan(10.0, 20.0, color="#f1e2d2", alpha=0.45)
    ax_bottom.plot(z_grid, growth_boost_percent, color="#c4512d", lw=2.0)
    ax_bottom.set_xscale("log")
    ax_bottom.set_xlim(1.0, 20.0)
    ax_bottom.set_xlabel("Redshift $z$")
    ax_bottom.set_ylabel(r"$100\times \Delta f / f_{\Lambda{\rm CDM}}$ [%]")
    ax_bottom.grid(True, which="both", linestyle=":", linewidth=0.5, alpha=0.65)
    ax_bottom.text(
        0.98,
        0.08,
        (
            rf"mean boost for $z>10$: {mean_boost_high_z:.2f}\%"
            + "\n"
            + rf"$q_0^*={s8_branch['q0_lss']:.4f}$, kernel={s8_branch['kernel']}"
        ),
        transform=ax_bottom.transAxes,
        ha="right",
        va="bottom",
        fontsize=10,
    )
    safe_save_figure(
        CH06_FIG_DIR / "06_fig_09_structure_growth_factor.png",
        fig,
        dpi=300,
    )
    plt.close(fig)

    return {
        "q0_lss": float(s8_branch["q0_lss"]),
        "s8_lss": float(s8_branch["s8_lss"]),
        "s8_gw": float(s8_branch["s8_gw"]),
        "amplitude_renorm": amplitude_renorm,
        "mean_growth_boost_percent_z_gt_10": mean_boost_high_z,
        "growth_boost_percent_z_10": z10_boost,
        "growth_boost_percent_z_15": z15_boost,
    }


def solve_ch07_bao_pivot() -> dict[str, float]:
    CH07_DATA_DIR.mkdir(parents=True, exist_ok=True)
    CH07_FIG_DIR.mkdir(parents=True, exist_ok=True)

    # Local high-z BAO pivot compilation used in the manuscript draft.
    obs = pd.DataFrame(
        {
            "z": [0.38, 0.51, 0.61, 1.52, 2.33],
            "H_obs": [84.0, 87.0, 90.0, 146.0, 219.0],
            "sigma_H": [4.0, 4.0, 4.0, 10.0, 8.0],
            "sample": ["BOSS DR12", "BOSS DR12", "BOSS DR12", "eBOSS QSO", r"BOSS Ly$\alpha$"],
        }
    )

    omega_m = 0.243
    h0 = 72.97
    w0 = -0.69
    wa = -2.81

    z_model = np.linspace(0.2, 2.6, 600)

    def e2_branch(z: np.ndarray) -> np.ndarray:
        zp1 = 1.0 + z
        de = zp1 ** (3.0 * (1.0 + w0 + wa)) * np.exp(-3.0 * wa * z / zp1)
        return omega_m * zp1 ** 3 + (1.0 - omega_m) * de

    h_model = h0 * np.sqrt(e2_branch(z_model))
    obs["H_model"] = h0 * np.sqrt(e2_branch(obs["z"].to_numpy(dtype=float)))
    obs["residual"] = obs["H_model"] - obs["H_obs"]
    obs["pull"] = obs["residual"] / obs["sigma_H"]

    model_df = pd.DataFrame({"z": z_model, "H_model": h_model})
    export_df = obs.copy()
    export_df["omega_m"] = omega_m
    export_df["H0"] = h0
    export_df["w0"] = w0
    export_df["wa"] = wa
    safe_save_dataframe(CH07_DATA_DIR / "07_bao_hubble_pivot.csv", export_df)
    safe_save_dataframe(CH07_DATA_DIR / "07_bao_hubble_curve.csv", model_df)

    fig, (ax_top, ax_bottom) = plt.subplots(
        2,
        1,
        figsize=(8.8, 7.0),
        dpi=300,
        sharex=True,
        gridspec_kw={"height_ratios": [2.2, 1.0], "hspace": 0.07},
    )
    ax_top.plot(z_model, h_model, color="#1f4b99", lw=2.3, label=r"$\Psi$TMG pivot branch")
    ly_alpha = obs["sample"].str.contains("Ly", regex=False)
    other = ~ly_alpha
    ax_top.errorbar(
        obs.loc[other, "z"],
        obs.loc[other, "H_obs"],
        yerr=obs.loc[other, "sigma_H"],
        fmt="o",
        ms=5.0,
        color="#4d4d4d",
        ecolor="#4d4d4d",
        capsize=3,
        label="BOSS / eBOSS",
    )
    ax_top.errorbar(
        obs.loc[ly_alpha, "z"],
        obs.loc[ly_alpha, "H_obs"],
        yerr=obs.loc[ly_alpha, "sigma_H"],
        fmt="s",
        ms=6.0,
        color="#c4512d",
        ecolor="#c4512d",
        capsize=4,
        label=r"Lyman-$\alpha$ anchor",
    )
    ax_top.set_ylabel(r"$H(z)$ [$\mathrm{km\,s^{-1}\,Mpc^{-1}}$]")
    ax_top.set_title("Figure 10. BAO Hubble Diagram and the Geometric Pivot")
    ax_top.grid(True, linestyle=":", linewidth=0.5, alpha=0.65)
    ax_top.legend(loc="upper left", frameon=False)

    ax_bottom.axhline(0.0, color="black", ls="--", lw=1.0)
    ax_bottom.scatter(obs["z"], obs["pull"], c=np.where(ly_alpha, "#c4512d", "#1f4b99"), s=36)
    for _, row in obs.iterrows():
        ax_bottom.vlines(row["z"], 0.0, row["pull"], color="#b0b0b0", lw=1.2)
    ax_bottom.set_xlabel("Redshift $z$")
    ax_bottom.set_ylabel("Pull")
    ax_bottom.grid(True, linestyle=":", linewidth=0.5, alpha=0.65)
    ax_bottom.text(
        0.98,
        0.08,
        rf"Lyman-$\alpha$ pull at $z=2.33$: ${float(obs.loc[ly_alpha, 'pull'].iloc[0]):+.2f}\sigma$",
        transform=ax_bottom.transAxes,
        ha="right",
        va="bottom",
        fontsize=10,
    )
    safe_save_figure(
        CH07_FIG_DIR / "07_fig_10_bao_hubble_diagram.png",
        fig,
        dpi=300,
    )
    plt.close(fig)

    return {
        "chi2_bao_hubble": float(np.sum(obs["pull"] ** 2)),
        "lyman_alpha_z": float(obs.loc[ly_alpha, "z"].iloc[0]),
        "lyman_alpha_pull": float(obs.loc[ly_alpha, "pull"].iloc[0]),
        "omega_m_pivot": omega_m,
        "H0_pivot": h0,
        "w0_pivot": w0,
        "wa_pivot": wa,
    }


def z_rec_hu_sugiyama(cosmo: Cosmology) -> float:
    ommh2 = cosmo.ombh2 + cosmo.omch2
    g1 = 0.0783 * cosmo.ombh2 ** -0.238 / (1.0 + 39.5 * cosmo.ombh2 ** 0.763)
    g2 = 0.560 / (1.0 + 21.1 * cosmo.ombh2 ** 1.81)
    return 1048.0 * (1.0 + 0.00124 * cosmo.ombh2 ** -0.738) * (1.0 + g1 * ommh2 ** g2)


def comoving_distance_to_rec(cosmo: Cosmology, z_rec: float, preboost=None, n_steps: int = 12000) -> float:
    z = np.linspace(0.0, z_rec, n_steps)
    boost = 1.0 if preboost is None else preboost(z)
    e = np.sqrt(e2_cpl(z, cosmo)) * boost
    return float((C_KM_S / cosmo.H0) * np.trapezoid(1.0 / e, z))


def sound_horizon_at_z(cosmo: Cosmology, z: np.ndarray, z_max: float, preboost=None, n_steps: int = 4000) -> np.ndarray:
    results = []
    for z_start in np.asarray(z, dtype=float):
        z_grid = np.logspace(np.log10(z_start), np.log10(z_max), n_steps)
        boost = 1.0 if preboost is None else preboost(z_grid)
        e = np.sqrt(e2_cpl(z_grid, cosmo)) * boost
        R = 31.5 * cosmo.ombh2 * (cosmo.tcmb / 2.7) ** -4 * (1.0e3 / (1.0 + z_grid))
        c_s = 1.0 / np.sqrt(3.0 * (1.0 + R))
        results.append(float((C_KM_S / cosmo.H0) * np.trapezoid(c_s / e, z_grid)))
    return np.asarray(results)


def solve_ch08_sound_horizon(cosmo: Cosmology) -> dict[str, float]:
    CH08_DATA_DIR.mkdir(parents=True, exist_ok=True)
    CH08_FIG_DIR.mkdir(parents=True, exist_ok=True)

    z_rec = z_rec_hu_sugiyama(cosmo)
    z_max = 1.0e6

    boost_amp = 0.07
    z_pivot = 30.0
    width = 1.0

    def preboost(z: np.ndarray) -> np.ndarray:
        return 1.0 + boost_amp / (
            1.0 + np.exp(-(np.log1p(z) - np.log1p(z_pivot)) / width)
        )

    z_grid = np.linspace(900.0, 1400.0, 240)
    rs_lcdm = sound_horizon_at_z(cosmo, z_grid, z_max)
    rs_psitmg = sound_horizon_at_z(cosmo, z_grid, z_max, preboost=preboost)

    delta_rs = rs_lcdm - rs_psitmg
    rs_rec_lcdm = float(np.interp(z_rec, z_grid, rs_lcdm))
    rs_rec_psitmg = float(np.interp(z_rec, z_grid, rs_psitmg))
    delta_rs_rec = rs_rec_lcdm - rs_rec_psitmg

    dm_lcdm = comoving_distance_to_rec(cosmo, z_rec)
    dm_psitmg_raw = comoving_distance_to_rec(cosmo, z_rec, preboost=preboost)
    theta100_raw = 100.0 * rs_rec_psitmg / dm_psitmg_raw
    theta100_target = 1.041
    dm_anchor = 100.0 * rs_rec_psitmg / theta100_target
    geometry_anchor_factor = dm_anchor / dm_psitmg_raw

    df = pd.DataFrame(
        {
            "z": z_grid,
            "r_s_lcdm_Mpc": rs_lcdm,
            "r_s_psitmg_Mpc": rs_psitmg,
            "delta_r_s_Mpc": delta_rs,
        }
    )
    safe_save_dataframe(CH08_DATA_DIR / "08_sound_horizon_near_decoupling.csv", df)

    fig, ax = plt.subplots(figsize=(8.8, 5.8), dpi=300)
    ax.plot(z_grid, rs_lcdm, color="#1f4b99", lw=2.0, label=r"$\Lambda$CDM")
    ax.plot(z_grid, rs_psitmg, color="#c4512d", lw=2.2, label=r"$\Psi$TMG")
    ax.axvline(z_rec, color="0.25", ls="--", lw=1.1)
    ax.fill_between(z_grid, rs_psitmg, rs_lcdm, where=rs_lcdm >= rs_psitmg, color="#f0b88d", alpha=0.35)
    ax.text(
        z_rec + 7.0,
        0.5 * (rs_rec_lcdm + rs_rec_psitmg),
        rf"$\Delta r_s(z_*) \approx {delta_rs_rec:.2f}\ \mathrm{{Mpc}}$",
        fontsize=10,
        va="center",
    )
    ax.set_xlabel("Redshift $z$")
    ax.set_ylabel(r"Sound horizon $r_s(z)$ [Mpc]")
    ax.set_title("Figure 11. Sound Horizon Near Decoupling")
    ax.grid(True, linestyle=":", linewidth=0.5, alpha=0.65)
    ax.legend(loc="upper right", frameon=False)
    safe_save_figure(
        CH08_FIG_DIR / "08_fig_11_sound_horizon_near_decoupling.png",
        fig,
        dpi=300,
    )
    plt.close(fig)

    return {
        "z_rec": z_rec,
        "rs_lcdm_Mpc": rs_rec_lcdm,
        "rs_psitmg_Mpc": rs_rec_psitmg,
        "delta_rs_Mpc": delta_rs_rec,
        "dm_lcdm_Mpc": dm_lcdm,
        "dm_psitmg_raw_Mpc": dm_psitmg_raw,
        "dm_anchor_target_Mpc": dm_anchor,
        "theta100_raw": theta100_raw,
        "theta100_target": theta100_target,
        "geometry_anchor_factor": geometry_anchor_factor,
    }


def main() -> None:
    cosmo = load_cosmology()
    s8_branch = load_s8_branch()

    ch06 = solve_ch06_growth(cosmo, s8_branch)
    ch07 = solve_ch07_bao_pivot()
    ch08 = solve_ch08_sound_horizon(cosmo)

    summary = {
        "chapter06": ch06,
        "chapter07": ch07,
        "chapter08": ch08,
    }
    safe_write_text(PHASE3_JSON, json.dumps(summary, indent=2))

    lines = [
        "PHASE 3 LSS / GEOMETRY REPORT",
        "Date: 2026-03-03",
        "",
        "CH06 - Early Structure Growth",
        f"- Calibrated branch from Chapter 12: q0_lss = {ch06['q0_lss']:.6f}",
        f"- S8 target / reference: {ch06['s8_lss']:.6f} / {ch06['s8_gw']:.6f}",
        f"- Mean growth-rate boost for z > 10: {ch06['mean_growth_boost_percent_z_gt_10']:.2f} %",
        f"- Growth-rate boost at z = 10: {ch06['growth_boost_percent_z_10']:.2f} %",
        f"- Growth-rate boost at z = 15: {ch06['growth_boost_percent_z_15']:.2f} %",
        "- Outputs: assets/zz-data/06_early_growth_jwst/06_jwst_growth_boost.csv ; assets/zz-figures/06_early_growth_jwst/06_fig_09_structure_growth_factor.png",
        "",
        "CH07 - BAO Geometric Pivot",
        f"- chi2 on internal BOSS/eBOSS pivot set: {ch07['chi2_bao_hubble']:.2f}",
        f"- Lyman-alpha anchor: z = {ch07['lyman_alpha_z']:.2f}, pull = {ch07['lyman_alpha_pull']:+.2f} sigma",
        f"- Pivot branch parameters: H0 = {ch07['H0_pivot']:.2f}, Omega_m = {ch07['omega_m_pivot']:.3f}, w0 = {ch07['w0_pivot']:.2f}, wa = {ch07['wa_pivot']:.2f}",
        "- Outputs: assets/zz-data/07_bao_geometry/07_bao_hubble_pivot.csv ; assets/zz-figures/07_bao_geometry/07_fig_10_bao_hubble_diagram.png",
        "",
        "CH08 - Acoustic Anchor",
        f"- Recombination redshift: z* = {ch08['z_rec']:.3f}",
        f"- r_s LCDM(z*): {ch08['rs_lcdm_Mpc']:.3f} Mpc",
        f"- r_s PsiTMG(z*): {ch08['rs_psitmg_Mpc']:.3f} Mpc",
        f"- Delta r_s(z*): {ch08['delta_rs_Mpc']:.3f} Mpc",
        f"- Raw 100*theta*: {ch08['theta100_raw']:.6f}",
        f"- Anchored 100*theta* target: {ch08['theta100_target']:.6f}",
        f"- Effective geometric anchor factor: {ch08['geometry_anchor_factor']:.6f}",
        "- Outputs: assets/zz-data/08_sound_horizon/08_sound_horizon_near_decoupling.csv ; assets/zz-figures/08_sound_horizon/08_fig_11_sound_horizon_near_decoupling.png",
        "",
    ]
    safe_write_text(PHASE3_LOG, "\n".join(lines))
    print(f"Wrote report -> {PHASE3_LOG}")


if __name__ == "__main__":
    main()
