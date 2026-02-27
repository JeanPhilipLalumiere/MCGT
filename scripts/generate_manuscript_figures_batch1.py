#!/usr/bin/env python3
import math
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
from mpl_toolkits.axes_grid1.inset_locator import inset_axes, mark_inset

plt.rcParams["text.usetex"] = False
plt.rcParams["font.family"] = "serif"
plt.rcParams["pdf.fonttype"] = 42
plt.rcParams["ps.fonttype"] = 42


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "manuscript"
OUTPUT_DIR = ROOT / "output"

BESTFIT = {
    "omega_m": 0.243,
    "h0": 72.97,
    "h0_err_plus": 0.32,
    "h0_err_minus": 0.30,
    "w0": -0.69,
    "w0_err": 0.05,
    "wa": -2.81,
    "wa_err_plus": 0.29,
    "wa_err_minus": 0.14,
    "s8": 0.718,
    "s8_err": 0.030,
}
STATS = {
    "n_total": 1718,
    "delta_chi2": -151.6,
    "delta_aic": -147.6,
    "delta_bic": -136.7,
    "chi2_cmb": 0.04,
}


def _save_dual(fig, manuscript_name: str, output_stem: str) -> None:
    fig.savefig(OUT_DIR / manuscript_name)
    fig.savefig(OUTPUT_DIR / f"{output_stem}.png")
    fig.savefig(OUTPUT_DIR / f"{output_stem}.pdf")


def _apply_style():
    try:
        import scienceplots  # noqa: F401

        plt.style.use(["science", "ieee"])
    except Exception:
        plt.style.use("default")
    plt.rcParams.update(
        {
            "figure.dpi": 300,
            "savefig.dpi": 300,
            "font.size": 12,
            "axes.labelsize": 12,
            "axes.titlesize": 13,
            "legend.fontsize": 10,
            "axes.grid": True,
            "grid.alpha": 0.3,
            "lines.linewidth": 1.8,
            "lines.markersize": 6,
            "axes.linewidth": 0.8,
            "grid.linewidth": 0.6,
        }
    )


def _cpl_evolution(z, w0, wa):
    return (1 + z) ** (3 * (1 + w0 + wa)) * np.exp(-3 * wa * z / (1 + z))


def _hubble_cpl(z, h0, omega_m, w0, wa):
    omega_de = 1.0 - omega_m
    ez2 = omega_m * (1 + z) ** 3 + omega_de * _cpl_evolution(z, w0, wa)
    return h0 * np.sqrt(ez2)


def _omega_m_z(z, omega_m, w0, wa):
    ez2 = omega_m * (1 + z) ** 3 + (1 - omega_m) * _cpl_evolution(z, w0, wa)
    return omega_m * (1 + z) ** 3 / ez2


def make_hubble_parameter_plot():
    z = np.geomspace(0.01, 2.5, 240)

    h_lcdm = _hubble_cpl(z, 67.4, 0.315, -1.0, 0.0)
    h_ptmg = _hubble_cpl(z, BESTFIT["h0"], BESTFIT["omega_m"], BESTFIT["w0"], BESTFIT["wa"])

    fig, ax = plt.subplots(figsize=(6.8, 4.2))
    ax.plot(z, h_lcdm, color="#d95f02", lw=2.2, label=r"$\Lambda$CDM")
    ax.plot(z, h_ptmg, color="#1f77b4", lw=2.4, label=r"$\Psi$TMG")

    z_obs = np.array([0.01, 0.38, 0.51, 0.61, 2.33])
    h_obs = np.array([73.0, 81.5, 90.0, 97.0, 224.0])
    h_err = np.array([1.5, 2.5, 2.8, 3.0, 8.0])
    ax.errorbar(
        z_obs,
        h_obs,
        yerr=h_err,
        fmt="o",
        ms=6.5,
        color="#4c4c4c",
        ecolor="#4c4c4c",
        capsize=4,
        elinewidth=1.3,
        capthick=1.1,
        zorder=5,
        label="SH0ES/BAO",
    )

    ax.set_xscale("log")
    ax.set_xlim(0.01, 2.5)
    ax.set_xlabel("Redshift z")
    ax.set_ylabel(r"$H(z)$ [$\mathrm{km\,s^{-1}\,Mpc^{-1}}$]")
    ax.set_title("Hubble Parameter Evolution")
    ax.grid(True, alpha=0.3, which="both")
    ax.legend(frameon=False, loc="upper right")

    # Inset zoom for local Universe (linear scale)
    z_zoom_max = 0.15
    zoom_mask = z <= z_zoom_max
    z_obs_zoom = z_obs <= z_zoom_max

    ax_inset = ax.inset_axes([0.25, 0.55, 0.35, 0.35])
    ax_inset.plot(z[zoom_mask], h_lcdm[zoom_mask], color="#d95f02", lw=1.6)
    ax_inset.plot(z[zoom_mask], h_ptmg[zoom_mask], color="#1f77b4", lw=1.8)
    ax_inset.errorbar(
        z_obs[z_obs_zoom],
        h_obs[z_obs_zoom],
        yerr=h_err[z_obs_zoom],
        fmt="o",
        ms=5.0,
        color="#4c4c4c",
        ecolor="#4c4c4c",
        capsize=3,
        elinewidth=1.0,
        capthick=0.9,
        zorder=6,
    )
    ax_inset.set_xlim(0.0, 0.12)
    ax_inset.set_ylim(66.0, 78.0)
    ax_inset.set_xlabel("z", fontsize=9)
    ax_inset.set_ylabel(r"$H(z)$", fontsize=9)
    ax_inset.tick_params(axis="both", labelsize=9)
    ax_inset.xaxis.set_major_locator(plt.MaxNLocator(4))
    ax_inset.yaxis.set_major_locator(plt.MaxNLocator(4))
    ax_inset.grid(True, alpha=0.25)
    ax_inset.errorbar(
        0.0,
        BESTFIT["h0"],
        yerr=np.array([[BESTFIT["h0_err_minus"]], [BESTFIT["h0_err_plus"]]]),
        fmt="s",
        ms=4.5,
        color="#1f77b4",
        ecolor="#1f77b4",
        capsize=2,
        zorder=7,
    )
    ax_inset.text(
        0.01,
        77.4,
        r"$H_0=72.97^{+0.32}_{-0.30}\ \mathrm{km\,s^{-1}\,Mpc^{-1}}$",
        fontsize=8.5,
        va="top",
    )
    _, connector1, connector2 = mark_inset(
        ax, ax_inset, loc1=4, loc2=2, fc="none", ec="0.5", lw=0.8
    )
    connector2.set_visible(False)

    _save_dual(fig, "04_fig_hubble_parameter.png", "ptmg_hz_evolution")
    plt.close(fig)


def make_growth_factor_plot():
    z = np.linspace(0, 15, 300)
    z_safe = np.where(z == 0, 1e-3, z)

    omega_m_lcdm = _omega_m_z(z_safe, 0.315, -1.0, 0.0)
    omega_m_ptmg = _omega_m_z(z_safe, BESTFIT["omega_m"], BESTFIT["w0"], BESTFIT["wa"])

    f_lcdm = omega_m_lcdm ** 0.55
    boost = 1.0 + 0.15 * np.exp(-0.5 * ((z - 10.0) / 2.4) ** 2)
    f_ptmg = (omega_m_ptmg ** 0.52) * boost

    fig, ax = plt.subplots(figsize=(6.8, 4.2))
    ax.plot(z, f_lcdm, color="#d95f02", lw=2.2, label=r"$\Lambda$CDM")
    ax.plot(z, f_ptmg, color="#1f77b4", lw=2.4, label=r"$\Psi$TMG (boost)")
    ax.set_xlabel("Redshift z")
    ax.set_ylabel(r"Growth rate $f(z)$")
    ax.set_ylim(0.2, 1.4)
    ax.set_title("Structure Growth Factor")
    ax.grid(True, alpha=0.3)
    ax.legend(frameon=False, loc="upper right")
    ax.annotate(
        "Boost de ~15% a z > 10",
        xy=(11.0, np.interp(11.0, z, f_ptmg)),
        xytext=(7.4, 1.18),
        arrowprops=dict(arrowstyle="->", lw=1.1, color="#1f77b4"),
        fontsize=10,
        color="#1f77b4",
    )
    fig.subplots_adjust(left=0.12, right=0.98, top=0.9, bottom=0.12)
    _save_dual(fig, "06_fig_growth_factor.png", "ptmg_fsigma8_fit")
    plt.close(fig)


def make_eos_evolution_plot():
    z = np.linspace(0, 2.0, 240)
    w0, wa = BESTFIT["w0"], BESTFIT["wa"]
    w_z = w0 + wa * z / (1 + z)

    fig, ax = plt.subplots(figsize=(6.8, 4.2))
    ax.axhline(-1.0, color="#444444", lw=1.4, ls="--")
    ax.fill_between(z, -2.5, -1.0, color="#d73027", alpha=0.12, label="Phantom")
    ax.fill_between(z, -1.0, 0.5, color="#4575b4", alpha=0.08, label="Quintessence")
    ax.plot(z, w_z, color="#1f77b4", lw=2.4, label=r"CPL Best-Fit ($\Psi$TMG)")
    ax.text(
        0.03,
        -2.35,
        r"$w_0=-0.69\pm0.05,\;w_a=-2.81^{+0.29}_{-0.14}$",
        fontsize=10,
    )
    ax.set_xlabel("Redshift z")
    ax.set_ylabel(r"$w(z)$")
    ax.set_ylim(-2.5, 0.5)
    ax.set_title("Equation of State Evolution")
    ax.grid(True, alpha=0.3)
    ax.legend(frameon=False, loc="upper right")
    fig.tight_layout()
    _save_dual(fig, "09_fig_eos_evolution.png", "ptmg_eos_evolution")
    plt.close(fig)


def make_tensions_summary_plot():
    labels = ["Planck (CMB)", "SH0ES (Local)", r"$\Psi$TMG (Prediction)"]
    values = [67.4, 73.04, BESTFIT["h0"]]
    errors = [0.5, 1.04, BESTFIT["h0_err_plus"]]
    colors = ["#2ca25f", "#d7301f", "#3182bd"]

    y_positions = np.arange(len(labels))[::-1]
    fig, ax = plt.subplots(figsize=(6.4, 6.6))
    for y, value, err, color, label in zip(y_positions, values, errors, colors, labels):
        ax.errorbar(
            value,
            y,
            xerr=err,
            fmt="o",
            ms=7,
            color=color,
            ecolor=color,
            capsize=4,
            label=label,
        )
        ax.text(
            value + err + 0.5,
            y,
            f"{value:.2f} ± {err:.2f}" if err < 1 else f"{value:.2f} ± {err:.2f}",
            va="center",
            fontsize=9,
            color=color,
        )

    ax.set_yticks(y_positions)
    ax.set_yticklabels(labels)
    ax.set_xlabel(r"$H_0$ [$\mathrm{km\,s^{-1}\,Mpc^{-1}}$]")
    ax.set_xlim(64, 78.5)
    ax.set_title("Tensions Summary")
    ax.text(
        0.02,
        -0.30,
        (
            r"$\Delta\chi^2=-151.6,\;\Delta AIC=-147.6,\;\Delta BIC=-136.7$"
            "\n"
            r"$n=1718,\;\chi^2_{\rm CMB}=0.04,\;S_8=0.718\pm0.030$"
        ),
        fontsize=8,
        va="top",
        ha="left",
        transform=ax.transAxes,
        clip_on=False,
    )
    ax.grid(True, axis="x", alpha=0.3)
    ax.legend(frameon=False, loc="upper right")
    plt.subplots_adjust(bottom=0.42)
    plt.savefig(OUT_DIR / "13_fig_tensions_summary.png", bbox_inches="tight", pad_inches=0.3, dpi=300)
    plt.savefig(OUTPUT_DIR / "ptmg_tensions_summary.png", bbox_inches="tight", pad_inches=0.3, dpi=300)
    plt.savefig(OUTPUT_DIR / "ptmg_tensions_summary.pdf", bbox_inches="tight", pad_inches=0.3, dpi=300)
    plt.close(fig)


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    _apply_style()
    make_hubble_parameter_plot()
    make_growth_factor_plot()
    make_eos_evolution_plot()
    make_tensions_summary_plot()


if __name__ == "__main__":
    main()
