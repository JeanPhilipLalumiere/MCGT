#!/usr/bin/env python3
"""Generate Chapter 11 power spectrum comparison figure (300 DPI)."""

from __future__ import annotations

import argparse
import configparser
from pathlib import Path

import numpy as np


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Plot P(k) CPL vs LCDM.")
    parser.add_argument(
        "--config",
        default="config/mcgt-global-config.ini",
        help="Path to central INI config.",
    )
    parser.add_argument(
        "--cpl",
        default="assets/zz-data/chapter11/11_matter_power_cpl.csv",
        help="CPL power spectrum CSV.",
    )
    parser.add_argument(
        "--lcdm",
        default="assets/zz-data/chapter11/11_matter_power_lcdm.csv",
        help="LCDM power spectrum CSV.",
    )
    parser.add_argument(
        "--out",
        default="assets/zz-figures/chapter11/11_fig_01_power_comparison.png",
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


def load_h(config_path: Path) -> float:
    cfg = configparser.ConfigParser(
        interpolation=None, inline_comment_prefixes=("#", ";")
    )
    if not cfg.read(config_path, encoding="utf-8"):
        raise FileNotFoundError(f"Cannot read config: {config_path}")
    H0 = cfg["cmb"].getfloat("H0")
    return H0 / 100.0


def main() -> int:
    args = parse_args()
    cpl_path = Path(args.cpl)
    lcdm_path = Path(args.lcdm)
    out_path = Path(args.out)

    if not cpl_path.exists() or not lcdm_path.exists():
        raise FileNotFoundError("Missing CPL or LCDM power spectrum CSV")

    h = load_h(Path(args.config))

    k_cpl, p_cpl = load_power(cpl_path)
    k_lcdm, p_lcdm = load_power(lcdm_path)

    if k_cpl.shape != k_lcdm.shape or not np.allclose(k_cpl, k_lcdm, rtol=0, atol=0):
        raise ValueError("k grids do not match between CPL and LCDM inputs")

    try:
        import matplotlib.pyplot as plt
    except ImportError as exc:
        raise SystemExit(f"matplotlib missing: {exc}") from exc

    k_h = k_cpl / h
    p_cpl_h = p_cpl * h ** 3
    p_lcdm_h = p_lcdm * h ** 3

    out_path.parent.mkdir(parents=True, exist_ok=True)

    fig, ax = plt.subplots(figsize=(6.8, 4.2))
    ax.loglog(k_h, p_cpl_h, label="CPL (best-fit)", lw=2.0)
    ax.loglog(k_h, p_lcdm_h, label="LCDM (w=-1)", lw=2.0, ls="--")
    ax.set_xlabel(r"k [h Mpc$^{-1}$]")
    ax.set_ylabel(r"P(k) [h$^{-3}$ Mpc$^{3}$]")
    ax.grid(True, which="both", alpha=0.25)
    ax.legend(frameon=False)
    fig.tight_layout()
    fig.savefig(out_path, dpi=300)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
