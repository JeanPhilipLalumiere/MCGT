#!/usr/bin/env python3
"""Generate paper Figure 03: H0 and S8 tension summary."""

from __future__ import annotations

import sys
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from scripts._common.release_v400 import (  # noqa: E402
    LCDM_S8_REF,
    PLANCK18_H0,
    PLANCK18_H0_ERR,
    PTMG_H0,
    PTMG_H0_ERR,
    PTMG_S8,
    PTMG_S8_ERR,
    SH0ES_H0,
    SH0ES_H0_ERR,
)
from scripts._common.style import apply_manuscript_defaults  # noqa: E402


FIGURES_DIR = ROOT / "paper" / "figures"
OUT_FIG = FIGURES_DIR / "03_fig_tensions_summary.pdf"

# 68% CL summary targets (publication values).
DES_KIDS_S8 = 0.776
DES_KIDS_S8_ERR = 0.017
PLANCK_S8_ERR = 0.016


def _plot_panel(
    ax: plt.Axes,
    title: str,
    xlabel: str,
    data: list[tuple[str, float, float, str]],
    xlim: tuple[float, float],
    planck_value: float,
) -> None:
    y = np.arange(len(data))[::-1]
    for yi, (label, value, err, color) in zip(y, data):
        ax.errorbar(value, yi, xerr=err, fmt="o", ms=6.5, color=color, ecolor=color, capsize=3)
        ax.text(value + err + 0.02 * (xlim[1] - xlim[0]), yi, f"{value:.3f} ± {err:.3f}", va="center", fontsize=9)
        ax.text(xlim[0] + 0.01 * (xlim[1] - xlim[0]), yi + 0.18, label, fontsize=9, color=color)

    ax.axvline(planck_value, color="gray", ls="--", lw=1.2, alpha=0.95)
    ax.set_yticks([])
    ax.set_xlim(*xlim)
    ax.set_title(title)
    ax.set_xlabel(xlabel, fontsize=13)
    ax.grid(True, axis="x", alpha=0.28)


def main() -> None:
    apply_manuscript_defaults(usetex=False)
    FIGURES_DIR.mkdir(parents=True, exist_ok=True)

    fig, (ax_h0, ax_s8) = plt.subplots(1, 2, figsize=(10.6, 4.4), constrained_layout=True)

    h0_data = [
        (r"$\Psi$TMG", PTMG_H0, PTMG_H0_ERR, "#1f77b4"),
        ("SH0ES", SH0ES_H0, SH0ES_H0_ERR, "#d62728"),
        ("Planck18", PLANCK18_H0, PLANCK18_H0_ERR, "#2ca25f"),
    ]
    s8_data = [
        (r"$\Psi$TMG", PTMG_S8, PTMG_S8_ERR, "#1f77b4"),
        ("DES/KiDS", DES_KIDS_S8, DES_KIDS_S8_ERR, "#d95f02"),
        ("Planck18", LCDM_S8_REF, PLANCK_S8_ERR, "#2ca25f"),
    ]

    _plot_panel(
        ax_h0,
        title=r"$H_0$ Tension",
        xlabel=r"$H_0$ [km s$^{-1}$ Mpc$^{-1}$]",
        data=h0_data,
        xlim=(66.0, 76.8),
        planck_value=PLANCK18_H0,
    )
    _plot_panel(
        ax_s8,
        title=r"$S_8$ Tension",
        xlabel=r"$S_8$",
        data=s8_data,
        xlim=(0.70, 0.85),
        planck_value=LCDM_S8_REF,
    )

    fig.savefig(OUT_FIG)
    print(f"[ok] Saved: {OUT_FIG}")


if __name__ == "__main__":
    main()
