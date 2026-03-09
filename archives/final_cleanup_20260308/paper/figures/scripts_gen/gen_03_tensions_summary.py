#!/usr/bin/env python3
"""Figure generator for ΨTMG Manuscript - arXiv Preprint Ready"""

from __future__ import annotations

import argparse
from pathlib import Path

import matplotlib.pyplot as plt

DEFAULT_OUT = Path(__file__).resolve().parents[1] / "03_fig_tensions_summary.pdf"


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="Generate the H0/S8 whisker summary figure.")
    p.add_argument("--out", type=Path, default=DEFAULT_OUT)
    return p


def main() -> int:
    args = build_parser().parse_args()
    args.out.parent.mkdir(parents=True, exist_ok=True)

    # Reference values used in the manuscript
    h0_data = [
        ("Planck18 ($\\Lambda$CDM)", 67.4, 0.5, "#666666"),
        ("SH0ES", 73.04, 1.04, "#b24c2b"),
        (r"$\Psi$TMG", 74.18, 0.82, "#1f77b4"),
    ]
    s8_data = [
        ("Planck18 ($\\Lambda$CDM)", 0.834, 0.016, "#666666"),
        ("DES/KiDS", 0.770, 0.020, "#b24c2b"),
        (r"$\Psi$TMG", 0.748, 0.021, "#1f77b4"),
    ]

    fig, axes = plt.subplots(2, 1, figsize=(8.6, 6.8), constrained_layout=True)
    planck_line_style = dict(color="#999999", ls="--", lw=1.2)

    # Panel H0
    ax = axes[0]
    for i, (label, mean, err, color) in enumerate(reversed(h0_data)):
        y = i + 1
        ax.errorbar(mean, y, xerr=err, fmt="o", color=color, lw=2, capsize=4, markersize=6)
        ax.text(mean + err + 0.15, y, label, va="center", fontsize=10)
        ax.text(mean + err + 0.15, y + 0.22, rf"${mean:.2f}\pm{err:.2f}$", va="bottom", fontsize=9, color=color)
    ax.axvline(67.4, **planck_line_style)
    ax.set_xlim(65.5, 76.8)
    ax.set_ylim(0.4, 3.6)
    ax.set_yticks([])
    ax.set_xlabel(r"$H_0$ [km s$^{-1}$ Mpc$^{-1}$]", fontsize=13)
    ax.tick_params(axis="x", labelsize=10)
    ax.set_title(r"$H_0$ tension summary")

    # Panel S8
    ax = axes[1]
    for i, (label, mean, err, color) in enumerate(reversed(s8_data)):
        y = i + 1
        ax.errorbar(mean, y, xerr=err, fmt="o", color=color, lw=2, capsize=4, markersize=6)
        ax.text(mean + err + 0.004, y, label, va="center", fontsize=10)
        ax.text(mean + err + 0.004, y + 0.22, rf"${mean:.3f}\pm{err:.3f}$", va="bottom", fontsize=9, color=color)
    ax.axvline(0.834, **planck_line_style)
    ax.set_xlim(0.70, 0.87)
    ax.set_ylim(0.4, 3.6)
    ax.set_yticks([])
    ax.set_xlabel(r"$S_8$", fontsize=13)
    ax.tick_params(axis="x", labelsize=10)
    ax.set_title(r"$S_8$ tension summary")

    fig.suptitle(
        r"$\Psi$TMG tension synthesis"
        "\n"
        r"Bayesian evidence: $\Delta \ln \mathcal{Z} = +40.3$ (includes Occam penalty)",
        fontsize=12,
    )

    fig.savefig(args.out, bbox_inches="tight")
    plt.close(fig)
    print(f"[ok] wrote {args.out}")
    print("[ok] stats embedded: H0=74.18±0.82, S8=0.748±0.021, ΔlnZ=+40.3")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
