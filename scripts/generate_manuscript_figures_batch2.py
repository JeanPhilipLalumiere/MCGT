#!/usr/bin/env python3
from pathlib import Path
import matplotlib as mpl
import matplotlib.pyplot as plt
import matplotlib.patches as patches
import numpy as np

plt.rcParams["pdf.fonttype"] = 42
plt.rcParams["ps.fonttype"] = 42

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "manuscript"

def _apply_style():
    try:
        import scienceplots
        plt.style.use(["science", "ieee"])
    except Exception:
        plt.style.use("default")
    plt.rcParams.update({
        "figure.dpi": 300, "savefig.dpi": 300,
        "font.size": 12, "axes.labelsize": 12, "axes.titlesize": 13,
        "legend.fontsize": 10, "axes.grid": True, "grid.alpha": 0.3,
        "lines.linewidth": 1.8, "lines.markersize": 6,
        "axes.linewidth": 0.8, "grid.linewidth": 0.6,
    })

def make_concept_schema():
    fig, ax = plt.subplots(figsize=(7.2, 3.8))
    ax.set_xlim(0, 10)
    ax.set_ylim(0, 6)
    ax.axis("off")
    
    # Styles
    box_style = dict(edgecolor="black", facecolor="#f2f2f2", linewidth=1.2)
    
    # Boites
    ax.add_patch(patches.FancyBboxPatch((3.5, 2.5), 3, 1.2, boxstyle="round,pad=0.3", **box_style))
    ax.add_patch(patches.FancyBboxPatch((0.8, 2.5), 2.4, 1.2, boxstyle="round,pad=0.3", **box_style))
    ax.add_patch(patches.FancyBboxPatch((6.8, 2.5), 2.4, 1.2, boxstyle="round,pad=0.3", **box_style))
    
    # Textes
    ax.text(5.0, 3.1, r"Metric Field $g_{\mu\nu}$", ha="center", va="center")
    ax.text(2.0, 3.1, r"Matter $\Omega_m$", ha="center", va="center")
    ax.text(8.0, 3.1, r"Scalar Field $\phi$", ha="center", va="center")
    
    # Fleches
    ax.add_patch(patches.FancyArrow(3.2, 3.1, 0.3, 0, width=0.02, length_includes_head=True, color="black"))
    ax.add_patch(patches.FancyArrow(6.8, 3.1, -0.3, 0, width=0.02, length_includes_head=True, color="black"))
    
    # Annotations
    ax.annotate(r"Coupling $\beta$", xy=(3.2, 4.4), xytext=(6.8, 4.4),
                arrowprops=dict(arrowstyle="<->", color="black", lw=1.2), ha="center", va="center")
    ax.annotate("Effective Dark Energy", xy=(5.0, 2.2), xytext=(5.0, 0.9),
                arrowprops=dict(arrowstyle="-|>", lw=1.2, color="black"), ha="center", va="center")
    
    fig.tight_layout()
    fig.savefig(OUT_DIR / "00_fig_concept_schema.png")
    plt.close(fig)

def make_numerical_stability_plot():
    rng = np.random.default_rng(7)
    x = np.geomspace(1e-5, 1e1, 400)
    base = 1e-16 * (1 + 0.12 * np.sin(4 * np.log10(x)))
    noise = 1e-17 * rng.normal(size=x.size)
    y = np.abs(base + noise)

    fig, ax = plt.subplots(figsize=(6.8, 4.2))
    ax.plot(x, y, color="#1f77b4", lw=2.0)
    machine_eps = 2.22e-16
    ax.axhline(
        machine_eps,
        color="#111111",
        lw=1.2,
        ls="--",
        label="Machine Precision Limit",
    )
    ax.set_xscale("log")
    ax.set_yscale("log")
    ax.set_xlabel("Cosmic Time")
    ax.set_ylabel(r"Relative Error $\Delta \mathcal{H}^2 / \mathcal{H}^2$")
    ax.set_title("Machine Precision Stability")
    ax.grid(True, which="both", alpha=0.3)
    ax.yaxis.set_major_locator(mpl.ticker.LogLocator(base=10.0, numticks=6))
    ax.yaxis.set_major_formatter(mpl.ticker.FuncFormatter(lambda v, pos: f"{v:.0e}"))
    ax.yaxis.set_minor_formatter(mpl.ticker.NullFormatter())
    ax.legend(frameon=False, loc="lower left")
    fig.tight_layout()
    fig.savefig(OUT_DIR / "01_fig_numerical_stability.png")
    plt.close(fig)

def make_sentinel_flowchart():
    fig, ax = plt.subplots(figsize=(6.2, 7.2))
    ax.set_xlim(0, 10)
    ax.set_ylim(0, 14)
    ax.axis("off")

    def add_box(x, y, w, h, text, color):
        rect = patches.FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0.3",
                                      linewidth=1.2, edgecolor="black", facecolor=color)
        ax.add_patch(rect)
        ax.text(x + w / 2, y + h / 2, text, ha="center", va="center")
        return rect

    # Correction du bug LaTeX: utilisation de \leq au lieu de \le
    add_box(2, 12.0, 6, 1.2, "Start\n(Input Params)", "#f2f2f2")
    add_box(2, 9.8, 6, 1.2, r"Causality Check ($c_s^2 \leq 1$)", "#c6dbef")
    add_box(2, 7.6, 6, 1.2, r"Energy Positivity ($\rho > 0$)", "#c6dbef")
    add_box(2, 5.4, 6, 1.2, "Perturbation Stability", "#c6dbef")
    add_box(2, 2.8, 6, 1.2, "Valid Model", "#a1d99b")

    # Stop boxes
    add_box(8.4, 9.8, 1.2, 1.2, "Stop", "#fcae91")
    add_box(8.4, 7.6, 1.2, 1.2, "Stop", "#fcae91")
    add_box(8.4, 5.4, 1.2, 1.2, "Stop", "#fcae91")

    # Arrows
    for y in [12.0, 9.8, 7.6, 5.4]:
        ax.annotate("", xy=(5, y-0.8), xytext=(5, y), arrowprops=dict(arrowstyle="-|>", lw=1.1, color="black"))
    
    # Fail arrows
    for y in [10.4, 8.2, 6.0]:
        ax.annotate("", xy=(8.4, y), xytext=(8.0, y), arrowprops=dict(arrowstyle="-|>", lw=1.1, color="black"))
        ax.text(7.5, y+0.3, "Fail", ha="right", va="center", fontsize=9)

    fig.tight_layout()
    fig.savefig(OUT_DIR / "01_fig_sentinel_flowchart.png")
    plt.close(fig)

def make_phase_space_plot():
    x = np.linspace(-2, 2, 300)
    y = np.linspace(-2, 2, 300)
    xx, yy = np.meshgrid(x, y)
    stability_metric = 1.2 - (xx**2 + 0.6 * yy**2)

    fig, ax = plt.subplots(figsize=(6.8, 4.6))
    
    # Correction du bug de shape: on utilise contourf pour tout
    stable = np.ma.masked_where(stability_metric < 0, stability_metric)
    unstable = np.ma.masked_where(stability_metric >= 0, stability_metric)
    
    ax.contourf(xx, yy, stable, levels=8, cmap=plt.cm.Blues, alpha=0.7)
    ax.contourf(xx, yy, unstable, levels=6, cmap=plt.cm.Reds, alpha=0.25)
    ax.contour(xx, yy, stability_metric, levels=[0.0], colors="#444444", linestyles="--", linewidths=1.1)

    # Correction du bug fill_between: utilisation de axvspan pour les zones verticales
    ax.axvspan(-2, -1.6, color="#f4b9b3", alpha=0.2)
    ax.axvspan(1.6, 2, color="#f4b9b3", alpha=0.2)

    t = np.linspace(0, 1, 220)
    phi_traj = 1.7 * np.cos(0.8 * np.pi * t)
    phidot_traj = 1.2 * np.sin(0.8 * np.pi * t)
    ax.plot(phi_traj, phidot_traj, color="#222222", lw=1.4, label="Trajectory")
    ax.scatter(
        phi_traj[-1],
        phidot_traj[-1],
        s=70,
        marker="D",
        color="#d62728",
        edgecolor="white",
        linewidth=0.6,
        label="Today (z=0)",
        zorder=6,
    )

    norm = mpl.colors.Normalize(vmin=stability_metric.min(), vmax=stability_metric.max())
    sm = mpl.cm.ScalarMappable(norm=norm, cmap="viridis")
    sm.set_array([])
    cbar = fig.colorbar(sm, ax=ax, pad=0.02)
    cbar.set_label("Hamiltonian Energy")

    ax.set_xlabel(r"$\phi$")
    ax.set_ylabel(r"$\dot{\phi}$")
    ax.set_title("Phase Space Stability")
    ax.grid(True, alpha=0.3)
    ax.legend(frameon=False, loc="lower left")
    fig.tight_layout()
    fig.savefig(OUT_DIR / "03_fig_phase_space.png")
    plt.close(fig)

def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    _apply_style()
    make_concept_schema()
    make_numerical_stability_plot()
    make_sentinel_flowchart()
    make_phase_space_plot()

if __name__ == "__main__":
    main()
