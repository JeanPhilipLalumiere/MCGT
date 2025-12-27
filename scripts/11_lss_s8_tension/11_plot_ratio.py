#!/usr/bin/env python3
"""Plot ratio P_CPL / P_LCDM from chapter11 outputs."""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Plot CPL/LCDM power ratio.")
    parser.add_argument(
        "--cpl",
        default="assets/zz-data/11_lss_s8_tension/11_matter_power_cpl.csv",
        help="CPL power spectrum CSV.",
    )
    parser.add_argument(
        "--lcdm",
        default="assets/zz-data/11_lss_s8_tension/11_matter_power_lcdm.csv",
        help="LCDM power spectrum CSV.",
    )
    parser.add_argument(
        "--out",
        default="assets/zz-figures/11_lss_s8_tension/11_power_ratio.png",
        help="Output PNG path.",
    )
    return parser.parse_args()


def load_power(path: Path) -> tuple[np.ndarray, np.ndarray]:
    data = np.loadtxt(path, delimiter=",", skiprows=1)
    if data.ndim == 1:
        data = data.reshape(1, -1)
    k = data[:, 0]
    p_m = data[:, 2]
    return k, p_m


def main() -> int:
    args = parse_args()
    cpl_path = Path(args.cpl)
    lcdm_path = Path(args.lcdm)
    out_path = Path(args.out)

    if not cpl_path.exists() or not lcdm_path.exists():
        raise FileNotFoundError("Missing CPL or LCDM power spectrum CSV")

    k_cpl, p_cpl = load_power(cpl_path)
    k_lcdm, p_lcdm = load_power(lcdm_path)

    if k_cpl.shape != k_lcdm.shape or not np.allclose(k_cpl, k_lcdm, rtol=0, atol=0):
        raise ValueError("k grids do not match between CPL and LCDM inputs")

    ratio = p_cpl / p_lcdm

    try:
        import matplotlib.pyplot as plt
    except ImportError as exc:
        raise SystemExit(f"matplotlib missing: {exc}") from exc

    out_path.parent.mkdir(parents=True, exist_ok=True)

    fig, ax = plt.subplots(figsize=(6.8, 4.2))
    ax.semilogx(k_cpl, ratio, lw=2.0)
    ax.axhline(1.0, color="0.4", ls="--", lw=1.0)
    ax.set_xlabel(r"k [h Mpc$^{-1}$]")
    ax.set_ylabel("R(k) = P_CPL / P_LCDM")
    ax.grid(True, which="both", alpha=0.25)
    fig.tight_layout()
    fig.savefig(out_path, dpi=180)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
