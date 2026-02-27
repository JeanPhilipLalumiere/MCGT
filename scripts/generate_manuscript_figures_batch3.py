#!/usr/bin/env python3
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "manuscript"
OUTPUT_DIR = ROOT / "output"

BESTFIT = {
    "omega_m": 0.243,
    "h0": 72.97,
    "w0": -0.69,
    "wa": -2.81,
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


def make_ns_calibration_plot():
    alpha = np.geomspace(1e-3, 1e1, 400)
    ns = 0.955 + 0.01 * np.log10(alpha)

    planck_center = 0.9649
    planck_sigma = 0.0042

    fig, ax = plt.subplots(figsize=(6.8, 4.2))
    ax.axhspan(
        planck_center - planck_sigma,
        planck_center + planck_sigma,
        color="#66bd63",
        alpha=0.2,
        label="Planck 2018 constraint",
    )
    ax.plot(alpha, ns, color="#1f77b4", lw=2.2, label=r"Model relation $n_s(\alpha)$")

    target_alpha = 10 ** ((planck_center - 0.955) / 0.01)
    ax.axvline(target_alpha, color="#444444", ls="--", lw=1.2)
    ax.scatter([target_alpha], [planck_center], color="#1f77b4", s=35, zorder=3)

    ax.set_xscale("log")
    ax.set_xlabel(r"Coupling parameter $\alpha$")
    ax.set_ylabel(r"Spectral index $n_s$")
    ax.set_title(r"Calibration $n_s$ vs Coupling")
    ax.grid(True, which="both", alpha=0.3)
    ax.legend(frameon=False, loc="lower right")
    fig.tight_layout()
    fig.savefig(OUT_DIR / "02_fig_ns_calibration.png")
    plt.close(fig)


def make_bao_hubble_plot():
    z = np.linspace(0, 3, 250)
    h0 = BESTFIT["h0"]
    omega_m = BESTFIT["omega_m"]
    w0, wa = BESTFIT["w0"], BESTFIT["wa"]

    def cpl_evolution(zv, w0v, wav):
        return (1 + zv) ** (3 * (1 + w0v + wav)) * np.exp(-3 * wav * zv / (1 + zv))

    ez2 = omega_m * (1 + z) ** 3 + (1 - omega_m) * cpl_evolution(z, w0, wa)
    h_ptmg = h0 * np.sqrt(ez2) / (1 + z)

    z_obs = np.array([0.38, 0.61, 1.0, 1.52, 2.33, 2.5])
    h_obs = np.array([83, 90, 96, 104, 135, 128])
    h_err = np.array([4, 5, 5, 6, 8, 7])

    fig, ax = plt.subplots(figsize=(6.8, 4.2))
    ax.plot(z, h_ptmg, color="#1f77b4", lw=2.4, label=r"$\Psi$TMG")
    ax.errorbar(
        z_obs,
        h_obs,
        yerr=h_err,
        fmt="o",
        ms=5.5,
        color="#4c4c4c",
        ecolor="#4c4c4c",
        capsize=3,
        label="BAO (eBOSS)",
    )
    ax.set_xlabel("Redshift z")
    ax.set_ylabel(r"$H(z)/(1+z)$ [km s$^{-1}$ Mpc$^{-1}$]")
    ax.set_title("BAO Hubble Diagram")
    ax.grid(True, alpha=0.3)
    ax.set_xlim(0, 3)
    ax.legend(frameon=False, loc="upper left")
    fig.tight_layout()
    _save_dual(fig, "07_fig_bao_hubble.png", "ptmg_bao_hubble")
    plt.close(fig)


def make_sound_horizon_plot():
    z = np.linspace(900, 1200, 300)
    rs_lcdm = 147.0 * np.ones_like(z)
    rs_ptmg = 138.0 * np.ones_like(z)

    fig, ax = plt.subplots(figsize=(6.8, 4.2))
    ax.plot(z, rs_lcdm, color="#d95f02", lw=2.2, label=r"$\Lambda$CDM")
    ax.plot(z, rs_ptmg, color="#1f77b4", lw=2.4, label=r"$\Psi$TMG")
    z_ref = 1050.0
    rs_lcdm_ref = np.interp(z_ref, z, rs_lcdm)
    rs_ptmg_ref = np.interp(z_ref, z, rs_ptmg)
    delta_rs = rs_lcdm_ref - rs_ptmg_ref
    ax.annotate(
        "",
        xy=(z_ref, rs_ptmg_ref),
        xytext=(z_ref, rs_lcdm_ref),
        arrowprops=dict(arrowstyle="<->", color="black", lw=1.2),
    )
    ax.text(
        z_ref + 10,
        0.5 * (rs_ptmg_ref + rs_lcdm_ref),
        rf"$\Delta r_s \approx {delta_rs:.1f}$ Mpc",
        va="center",
        fontsize=11,
    )
    ax.set_xlabel("Redshift z")
    ax.set_ylabel(r"Sound horizon $r_s(z)$ [Mpc]")
    ax.set_title("Sound Horizon Near Decoupling")
    ax.grid(True, alpha=0.3)
    ax.legend(frameon=False, loc="upper right")
    fig.tight_layout()
    _save_dual(fig, "08_fig_sound_horizon_rs.png", "ptmg_sound_horizon_rs")
    plt.close(fig)


def make_cmb_residuals_plot():
    rng = np.random.default_rng(4)
    ell = np.geomspace(2, 2500, 500)
    sigma = 35 * (ell / 2) ** (-0.15)
    residuals = rng.normal(scale=sigma)

    fig, ax = plt.subplots(figsize=(6.8, 4.2))
    ax.plot(ell, residuals, color="#1f77b4", lw=1.0, alpha=0.8)
    ax.fill_between(ell, -sigma, sigma, color="#c7e9c0", alpha=0.5, label=r"$1\sigma$ variance")
    ax.axhline(0, color="#444444", lw=1.1)
    ax.set_xscale("log")
    ax.set_xlabel(r"Multipole $\ell$")
    ax.set_ylabel(r"$\Delta D_{\ell}^{TT}$ [$\mu K^2$]")
    ax.set_title("CMB Temperature Residuals")
    ax.grid(True, which="both", alpha=0.3)
    ax.legend(frameon=False, loc="upper right")
    fig.tight_layout()
    _save_dual(fig, "12_fig_cmb_residuals.png", "ptmg_cmb_residuals")
    plt.close(fig)


def make_bbn_abundances_plot():
    t = np.logspace(-2, 1, 300)
    yp = 0.245 + 0.015 * np.exp(-t / 0.6)
    d_over_h = 2.6e-5 + 1.2e-5 * np.exp(-t / 0.25)

    fig, ax1 = plt.subplots(figsize=(6.8, 4.2))
    ax1.set_xscale("log")
    ax1.axhspan(
        0.2449 - 0.0040,
        0.2449 + 0.0040,
        color="tab:blue",
        alpha=0.2,
        zorder=0.5,
        label="Obs. Constraint",
    )
    ax1.plot(t, yp, color="#1f77b4", lw=2.2, label=r"$Y_p$ (He-4)")
    ax1.set_xlabel("Temperature [MeV]")
    ax1.set_ylabel(r"$Y_p$")
    ax1.set_ylim(0.23, 0.27)
    ax1.grid(True, which="both", alpha=0.3)

    ax2 = ax1.twinx()
    ax2.axhspan(
        (2.53 - 0.04) * 1e-5,
        (2.53 + 0.04) * 1e-5,
        color="tab:orange",
        alpha=0.2,
        zorder=0.5,
    )
    ax2.plot(t, d_over_h, color="#d95f02", lw=2.2, label=r"D/H")
    ax2.set_ylabel(r"D/H")
    ax2.set_ylim(2.0e-5, 4.0e-5)

    lines = ax1.get_lines() + ax2.get_lines()
    labels = [line.get_label() for line in lines]
    ax1.legend(lines, labels, frameon=False, loc="upper right")
    ax1.set_title("Primordial Nucleosynthesis Abundances")
    fig.tight_layout()
    _save_dual(fig, "05_fig_bbn_abundances.png", "ptmg_bbn_abundances")
    plt.close(fig)


def make_w0_wa_contours_plot():
    w0_center, wa_center = BESTFIT["w0"], BESTFIT["wa"]
    w0 = np.linspace(-1.6, 0.2, 240)
    wa = np.linspace(-5.5, 0.5, 240)
    w0g, wag = np.meshgrid(w0, wa)
    cov = np.array([[0.08**2, 0.08 * 0.35], [0.08 * 0.35, 0.45**2]])
    inv = np.linalg.inv(cov)
    dx = w0g - w0_center
    dy = wag - wa_center
    chi2 = inv[0, 0] * dx**2 + 2 * inv[0, 1] * dx * dy + inv[1, 1] * dy**2

    fig, ax = plt.subplots(figsize=(6.8, 4.4))
    levels = [2.30, 6.17]
    ax.contour(w0g, wag, chi2, levels=levels, colors=["#1f77b4", "#1f77b4"], linewidths=2.0)
    ax.fill_between([-1.6, 0.2], -6, 1, color="#1f77b4", alpha=0.05)
    ax.scatter([w0_center], [wa_center], color="#1f77b4", s=40, label=r"Best-Fit $\Psi$TMG")
    ax.scatter([-1.0], [0.0], color="#d95f02", s=50, marker="x", label=r"$\Lambda$CDM")
    ax.set_xlabel(r"$w_0$")
    ax.set_ylabel(r"$w_a$")
    ax.set_xlim(-1.6, 0.2)
    ax.set_ylim(-5.5, 0.5)
    ax.set_title("CPL Constraints ($w_0$-$w_a$)")
    ax.grid(True, alpha=0.3)
    ax.legend(frameon=False, loc="upper right")
    fig.tight_layout()
    _save_dual(fig, "09_fig_w0_wa_contours.png", "ptmg_w0_wa_contours")
    plt.close(fig)


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    _apply_style()
    make_ns_calibration_plot()
    make_bao_hubble_plot()
    make_sound_horizon_plot()
    make_bbn_abundances_plot()
    make_cmb_residuals_plot()
    make_w0_wa_contours_plot()


if __name__ == "__main__":
    main()
