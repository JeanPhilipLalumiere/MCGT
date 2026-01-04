#!/usr/bin/env python3
import math
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "manuscript"


def _apply_style():
    try:
        import scienceplots  # noqa: F401

        plt.style.use(["science", "ieee"])
    except Exception:
        plt.style.use("default")
        plt.rcParams.update(
            {
                "figure.dpi": 200,
                "savefig.dpi": 300,
                "font.size": 11,
                "axes.labelsize": 12,
                "axes.titlesize": 13,
                "legend.fontsize": 10,
                "axes.grid": True,
                "grid.alpha": 0.3,
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
    h_mcgt = _hubble_cpl(z, 73.2, 0.301, -0.8, -0.5)

    fig, ax = plt.subplots(figsize=(6.8, 4.2))
    ax.plot(z, h_lcdm, color="#d95f02", lw=2.2, label=r"$\Lambda$CDM")
    ax.plot(z, h_mcgt, color="#1f77b4", lw=2.4, label="MCGT")

    z_obs = np.array([0.01, 0.38, 0.51, 0.61, 2.33])
    h_obs = np.array([73.0, 81.5, 90.0, 97.0, 224.0])
    h_err = np.array([1.5, 2.5, 2.8, 3.0, 8.0])
    ax.errorbar(
        z_obs,
        h_obs,
        yerr=h_err,
        fmt="o",
        ms=5.5,
        color="#4c4c4c",
        ecolor="#4c4c4c",
        capsize=3,
        label="SH0ES/BAO",
    )

    ax.set_xscale("log")
    ax.set_xlim(0.01, 2.5)
    ax.set_xlabel("Redshift z")
    ax.set_ylabel(r"$H(z)$ [km/s/Mpc]")
    ax.set_title("Hubble Parameter Evolution")
    ax.grid(True, alpha=0.3, which="both")
    ax.legend(frameon=False, loc="upper left")
    fig.tight_layout()
    fig.savefig(OUT_DIR / "04_fig_hubble_parameter.png")
    plt.close(fig)


def make_growth_factor_plot():
    z = np.linspace(0, 15, 300)
    z_safe = np.where(z == 0, 1e-3, z)

    omega_m_lcdm = _omega_m_z(z_safe, 0.315, -1.0, 0.0)
    omega_m_mcgt = _omega_m_z(z_safe, 0.301, -0.8, -0.5)

    f_lcdm = omega_m_lcdm ** 0.55
    boost = 1.0 + 0.15 * np.exp(-0.5 * ((z - 10.0) / 2.4) ** 2)
    f_mcgt = (omega_m_mcgt ** 0.52) * boost

    fig, ax = plt.subplots(figsize=(6.8, 4.2))
    ax.plot(z, f_lcdm, color="#d95f02", lw=2.2, label=r"$\Lambda$CDM")
    ax.plot(z, f_mcgt, color="#1f77b4", lw=2.4, label="MCGT (boost)")
    ax.set_xlabel("Redshift z")
    ax.set_ylabel(r"Growth rate $f(z)$")
    ax.set_ylim(0.2, 1.4)
    ax.set_title("Structure Growth Factor")
    ax.grid(True, alpha=0.3)
    ax.legend(frameon=False, loc="upper right")
    fig.tight_layout()
    fig.savefig(OUT_DIR / "06_fig_growth_factor.png")
    plt.close(fig)


def make_eos_evolution_plot():
    z = np.linspace(0, 2.0, 240)
    w0, wa = -0.2433, -2.9981
    w_z = w0 + wa * z / (1 + z)

    fig, ax = plt.subplots(figsize=(6.8, 4.2))
    ax.axhline(-1.0, color="#444444", lw=1.4, ls="--")
    ax.fill_between(z, -2.5, -1.0, color="#d73027", alpha=0.12, label="Phantom")
    ax.fill_between(z, -1.0, 0.5, color="#4575b4", alpha=0.08, label="Quintessence")
    ax.plot(z, w_z, color="#1f77b4", lw=2.4, label="CPL Best-Fit")
    ax.set_xlabel("Redshift z")
    ax.set_ylabel(r"$w(z)$")
    ax.set_ylim(-2.5, 0.5)
    ax.set_title("Equation of State Evolution")
    ax.grid(True, alpha=0.3)
    ax.legend(frameon=False, loc="lower left")
    fig.tight_layout()
    fig.savefig(OUT_DIR / "09_fig_eos_evolution.png")
    plt.close(fig)


def make_tensions_summary_plot():
    labels = ["Planck (CMB)", "SH0ES (Local)", "MCGT (Prediction)"]
    values = [67.4, 73.04, 73.2]
    errors = [0.5, 1.04, 0.8]
    colors = ["#2ca25f", "#d7301f", "#3182bd"]

    y_positions = np.arange(len(labels))[::-1]
    fig, ax = plt.subplots(figsize=(6.4, 3.6))
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

    ax.set_yticks(y_positions)
    ax.set_yticklabels(labels)
    ax.set_xlabel(r"$H_0$ [km/s/Mpc]")
    ax.set_xlim(64, 76)
    ax.set_title("Tensions Summary")
    ax.grid(True, axis="x", alpha=0.3)
    ax.legend(frameon=False, loc="lower right")
    fig.tight_layout()
    fig.savefig(OUT_DIR / "13_fig_tensions_summary.png")
    plt.close(fig)


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    _apply_style()
    make_hubble_parameter_plot()
    make_growth_factor_plot()
    make_eos_evolution_plot()
    make_tensions_summary_plot()


if __name__ == "__main__":
    main()
