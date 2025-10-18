#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import logging
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.patches import FancyArrowPatch
from scipy.signal import savgol_filter


# --- Répertoires ---
ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = ROOT / "zz-data" / "chapter05"


def load_series():
    """Charge χ²(T) et dχ²/dT depuis les CSV, aligne les grilles, lisse la dérivée.
    Retourne (T, chi2, sigma, dchi_scaled).
    """
    # 1) χ²(T)
    chi2_file = DATA_DIR / "05_chi2_bbn_vs_T.csv"
    chi2_df = pd.read_csv(chi2_file)

    # auto-détection de la colonne χ² (contient "chi2" mais pas "d"/"deriv")
    chi2_col = next(
        c for c in chi2_df.columns
        if "chi2" in c.lower() and not any(k in c.lower() for k in ("d", "deriv"))
    )

    chi2_df["T_Gyr"] = pd.to_numeric(chi2_df["T_Gyr"], errors="coerce")
    chi2_df[chi2_col] = pd.to_numeric(chi2_df[chi2_col], errors="coerce")
    chi2_df = chi2_df.dropna(subset=["T_Gyr", chi2_col])
    T = chi2_df["T_Gyr"].to_numpy()
    chi2 = chi2_df[chi2_col].to_numpy()

    # incertitude : colonne 'chi2_err' si présente, sinon ±10 %
    if "chi2_err" in chi2_df.columns:
        sigma = pd.to_numeric(chi2_df["chi2_err"], errors="coerce").to_numpy()
    else:
        sigma = 0.10 * chi2

    # 2) dχ²/dT
    dchi_file = DATA_DIR / "05_dchi2_vs_T.csv"
    dchi_df = pd.read_csv(dchi_file)

    # colonne dérivée (contient "chi2" et "d"/"deriv"/"smooth")
    dchi_col = next(
        c for c in dchi_df.columns
        if "chi2" in c.lower() and any(k in c.lower() for k in ("d", "deriv", "smooth"))
    )
    dchi_df["T_Gyr"] = pd.to_numeric(dchi_df["T_Gyr"], errors="coerce")
    dchi_df[dchi_col] = pd.to_numeric(dchi_df[dchi_col], errors="coerce")
    dchi_df = dchi_df.dropna(subset=["T_Gyr", dchi_col])
    Td = dchi_df["T_Gyr"].to_numpy()
    dchi_raw = dchi_df[dchi_col].to_numpy()

    # 3) Alignement + lissage
    if dchi_raw.size == 0:
        dchi = np.zeros_like(chi2)
    else:
        if not np.allclose(Td, T):
            dchi = np.interp(np.log10(T), np.log10(Td), dchi_raw, left=np.nan, right=np.nan)
        else:
            dchi = dchi_raw.copy()
        # lissage Savitzky-Golay (fenêtre impaire ≤ 7)
        if len(dchi) >= 5:
            win = min(7, (len(dchi) // 2) * 2 + 1)
            dchi = savgol_filter(dchi, window_length=win, polyorder=3, mode="interp")

    # échelle réduite pour lisibilité
    dchi_scaled = dchi / 1e4

    return T, chi2, sigma, dchi_scaled


def make_figure(T, chi2, sigma, dchi_scaled):
    plt.rcParams.update({"font.size": 11})
    fig, ax1 = plt.subplots(figsize=(6.5, 4.5))

    ax1.set_xscale("log")
    ax1.set_xlabel(r"$T\,[\mathrm{Gyr}]$")
    ax1.set_ylabel(r"$\chi^2$", color="tab:blue")
    ax1.tick_params(axis="y", labelcolor="tab:blue")
    ax1.grid(which="both", ls=":", lw=0.5, alpha=0.5)

    # bande ±1σ
    ax1.fill_between(T, chi2 - sigma, chi2 + sigma, color="tab:blue", alpha=0.12, label=r"$\pm1\sigma$")
    # courbe χ²
    (l1,) = ax1.plot(T, chi2, lw=2, color="tab:blue", label=r"$\chi^2$")

    # axe secondaire pour la dérivée
    ax2 = ax1.twinx()
    ax2.set_ylabel(r"$\mathrm{d}\chi^2/\mathrm{d}T$ (×$10^{-4}$)", color="tab:orange")
    ax2.tick_params(axis="y", labelcolor="tab:orange")
    (l2,) = ax2.plot(T, dchi_scaled, lw=2, color="tab:orange", label=r"$\mathrm{d}\chi^2/\mathrm{d}T/10^{4}$")

    # minimum de χ²
    imin = int(np.nanargmin(chi2))
    Tmin = T[imin]
    chi2_min = chi2[imin]
    ax1.scatter(Tmin, chi2_min, s=60, color="k", zorder=4)
    start = (Tmin * 0.2, chi2_min * 0.8)
    arrow = FancyArrowPatch(start, (Tmin, chi2_min), arrowstyle="->", mutation_scale=12,
                            connectionstyle="arc3,rad=-0.35", color="k")
    ax1.add_patch(arrow)
    ax1.annotate(
        rf"Min $\chi^2={chi2_min:.1f}$\n$T={Tmin:.2f}$\,Gyr",
        xy=(Tmin, chi2_min), xytext=start, ha="left", va="center", fontsize=10,
    )

    # légende combinée
    ax1.legend(handles=[l1, l2], labels=[r"$\chi^2$", r"$\mathrm{d}\chi^2/\mathrm{d}T/10^4$"], loc="upper right")

    fig.subplots_adjust(left=0.04, right=0.98, bottom=0.06, top=0.96)
    return fig


def main(argv=None) -> int:
    p = argparse.ArgumentParser(description="Fig. 04 — χ²(T) et dχ²/dT (Chapitre 5)")
    p.add_argument("--outdir", default="zz-figures/chapter05", help="Dossier de sortie")
    p.add_argument("--format", "--fmt", dest="format", choices=["png", "pdf", "svg"], default="png",
                   help="Format de sortie")
    p.add_argument("--dpi", type=int, default=300, help="DPI de sortie")
    p.add_argument("--transparent", action="store_true", help="Fond transparent")
    p.add_argument("-v", "--verbose", action="count", default=0, help="Verbosité cumulable")
    args = p.parse_args(argv)

    # Logging
    level = logging.WARNING if args.verbose == 0 else (logging.INFO if args.verbose == 1 else logging.DEBUG)
    logging.basicConfig(level=level, format="[%(levelname)s] %(message)s")

    T, chi2, sigma, dchi_scaled = load_series()
    fig = make_figure(T, chi2, sigma, dchi_scaled)

    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)
    out_png = outdir / f"fig_04_chi2_vs_T.{args.format}"
    fig.savefig(out_png, dpi=args.dpi, transparent=args.transparent)

    try:
        rel = out_png.resolve().relative_to(ROOT)
    except Exception:
        rel = out_png
    print(f"✓ {rel} généré.")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
