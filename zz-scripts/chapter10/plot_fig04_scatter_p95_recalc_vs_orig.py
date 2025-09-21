#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
tracer_fig04_scatter_p95_recalc_vs_orig.py

Compare p95_orig vs p95_recalc : scatter coloré par |Δp95|, encart histogramme,
optionnel encart zoom (--with-zoom). Title fontsize=15.

Usage example (recommended):
python zz-scripts/chapter10/tracer_fig04_scatter_p95_recalc_vs_orig.py \
  --results zz-data/chapter10/10_mc_results.circ.csv \
  --orig-col p95_20_300 --recalc-col p95_20_300_recalc \
  --out zz-figures/chapter10/fig_04_scatter_p95_recalc_vs_orig.png \
  --dpi 300 \
  --point-size 10 --alpha 0.7 --cmap viridis \
  --change-eps 1e-6 \
  --hist-x 0.60 --hist-y 0.18 --hist-scale 3.0 --bins 50
"""

from __future__ import annotations
import argparse
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from mpl_toolkits.axes_grid1.inset_locator import inset_axes, mark_inset


def detect_column(df: pd.DataFrame, hint: str | None, candidates: list[str]) -> str:
    if hint and hint in df.columns:
        return hint
    for c in candidates:
        if c in df.columns:
            return c
    # fallback substring match (case-insensitive)
    lowcols = [c.lower() for c in df.columns]
    for cand in candidates:
        lc = cand.lower()
        for i, col in enumerate(lowcols):
            if lc in col:
                return df.columns[i]
    raise KeyError(f"Aucune colonne trouvée parmi : {candidates} (hint={hint})")


def fmt_sci_power(v: float) -> tuple[float, int]:
    """Return (scaled_value, exponent) where scaled_value = v / 10**exp and exp is power of ten."""
    if v == 0:
        return 0.0, 0
    exp = int(
        np.floor(np.log10(abs(v)))
    )  # so  v ≈ scaled*10**exp  with scaled in [1,10)
    scale = 10.0**exp
    return v / scale, exp


def main():
    p = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    p.add_argument(
        "--results",
        required=True,
        help="CSV results (must contain orig/recalc columns)",
    )
    p.add_argument("--orig-col", default="p95_20_300", help="Original p95 column")
    p.add_argument(
        "--recalc-col", default="p95_20_300_recalc", help="Recalculated p95 column"
    )
    p.add_argument(
        "--out", default="fig_04_scatter_p95_recalc_vs_orig.png", help="Output PNG"
    )
    p.add_argument("--dpi", type=int, default=300, help="PNG dpi")
    p.add_argument("--point-size", type=float, default=10.0, help="scatter marker size")
    p.add_argument("--alpha", type=float, default=0.7, help="scatter alpha")
    p.add_argument("--cmap", default="viridis", help="colormap")
    p.add_argument(
        "--change-eps",
        type=float,
        default=1e-6,
        help="threshold for 'changed' count (abs Δ > eps)",
    )
    p.add_argument(
        "--with-zoom",
        action="store_true",
        help="Enable inset zoom box (disabled by default)",
    )
    p.add_argument(
        "--zoom-center-x",
        type=float,
        default=None,
        help="Zoom center (x) in data units",
    )
    p.add_argument(
        "--zoom-center-y",
        type=float,
        default=None,
        help="Zoom center (y) in data units",
    )
    p.add_argument(
        "--zoom-w", type=float, default=0.45, help="Inset zoom width (fraction fig)"
    )
    p.add_argument(
        "--zoom-h", type=float, default=0.10, help="Inset zoom height (fraction fig)"
    )

    # histogram placement & size (keep your requested defaults)
    p.add_argument(
        "--hist-x",
        type=float,
        default=0.60,
        help="X (figure coords) de l’histogramme (réduit → plus à gauche)",
    )
    p.add_argument(
        "--hist-y",
        type=float,
        default=0.18,
        help="Y (figure coords) de l’histogramme (augmenté → plus haut)",
    )
    p.add_argument(
        "--hist-scale",
        type=float,
        default=3.0,
        help="Scale factor for histogram inset size (1.0 = base size; >1 = larger)",
    )
    p.add_argument("--bins", type=int, default=50, help="Histogram bins")
    p.add_argument(
        "--title",
        default="Comparaison de p95_20_300 : original vs recalculé (métrique linéaire)",
        help="Figure title (fontsize=15)",
    )
    args = p.parse_args()

    # Read data
    df = pd.read_csv(args.results)
    orig_col = detect_column(df, args.orig_col, [args.orig_col])
    recalc_col = detect_column(df, args.recalc_col, [args.recalc_col])

    # Extract arrays and drop NaN
    sub = df[[orig_col, recalc_col]].dropna().astype(float).copy()
    x = sub[orig_col].values  # original
    y = sub[recalc_col].values  # recalculated
    if x.size == 0:
        raise SystemExit("Aucun point non-NA trouvé.")

    # Delta
    delta = y - x
    abs_delta = np.abs(delta)

    # Basic stats
    N = len(x)
    mean_x = float(np.mean(x))
    mean_y = float(np.mean(y))
    mean_delta = float(np.mean(delta))
    med_delta = float(np.median(delta))
    std_delta = float(np.std(delta, ddof=0))
    p95_abs = float(np.percentile(abs_delta, 95))
    max_abs = float(np.max(abs_delta))
    n_changed = int(np.sum(abs_delta > args.change_eps))
    frac_changed = 100.0 * n_changed / N

    # Prepare figure
    plt.style.use("classic")
    fig, ax = plt.subplots(figsize=(10, 10))

    # Color scaling: use percentile to avoid color burn; show 'extend' for outliers
    # choose vmax robustly
    if abs_delta.size == 0:
        vmax = 1.0
    else:
        vmax = float(np.percentile(abs_delta, 99.9))
        if vmax <= 0.0:
            vmax = float(np.max(abs_delta))
    # avoid exactly 0
    if vmax <= 0.0:
        vmax = 1.0

    sc = ax.scatter(
        x,
        y,
        c=abs_delta,
        s=args.point_size,
        alpha=args.alpha,
        cmap=args.cmap,
        edgecolor="none",
        vmin=0.0,
        vmax=vmax,
        zorder=2,
    )

    # diagonal reference
    lo = min(np.min(x), np.min(y))
    hi = max(np.max(x), np.max(y))
    ax.plot([lo, hi], [lo, hi], color="gray", linestyle="--", linewidth=1.0, zorder=1)

    # Axes labels & title
    ax.set_xlabel(f"{orig_col} [rad]")
    ax.set_ylabel(f"{recalc_col} [rad]")
    ax.set_title(args.title, fontsize=15)

    # colorbar with extend if any outliers > vmax
    extend = "max" if np.max(abs_delta) > vmax else "neither"
    cbar = fig.colorbar(sc, ax=ax, extend=extend, pad=0.02)
    cbar.set_label(r"$|\Delta p95|$ [rad]")

    # If vmax very small use scientific ticks on colorbar
    # Add ticks at 0 and vmax/2 and vmax maybe -> but keep default. Optionally could set ticks.

    # Statistics text box (top-left)
    stats = [
        f"N = {N}",
        f"mean(orig) = {mean_x:.3f} rad",
        f"mean(recalc) = {mean_y:.3f} rad",
        f"Δ = recalc - orig : mean = {mean_delta:.3e}, median = {med_delta:.3e}, std = {std_delta:.3e}",
        f"p95(|Δ|) = {p95_abs:.3e} rad, max |Δ| = {max_abs:.3e} rad",
        f"N_changed (|Δ| > {args.change_eps}) = {n_changed} ({frac_changed:.2f}%)",
    ]
    stats_text = "\n".join(stats)
    bbox = dict(boxstyle="round", fc="white", ec="black", lw=1, alpha=0.95)
    ax.text(
        0.02,
        0.98,
        stats_text,
        transform=ax.transAxes,
        fontsize=9,
        va="top",
        ha="left",
        bbox=bbox,
        zorder=10,
    )

    # Histogram inset placement and sizing (figure coords)
    hist_base_w = 0.18
    hist_base_h = 0.14
    hist_w = hist_base_w * args.hist_scale
    hist_h = hist_base_h * args.hist_scale
    hist_x = args.hist_x
    hist_y = args.hist_y
    # Create inset axes for histogram using figure coords
    hist_ax = inset_axes(
        ax,
        width=f"{hist_w * 100}%",
        height=f"{hist_h * 100}%",
        bbox_to_anchor=(hist_x, hist_y, hist_w, hist_h),
        bbox_transform=fig.transFigure,
        loc="lower left",
        borderpad=1.0,
    )

    # Choose scale for histogram x-axis (to display readable numbers)
    max_abs = float(np.max(abs_delta)) if abs_delta.size else 0.0
    if max_abs <= 0.0:
        scale = 1.0
        exp = 0
    else:
        exp = int(np.floor(np.log10(max_abs)))
        scale = 10.0**exp
        # if scaled max is <1, go one magnitude lower to have nicer tick range
        if max_abs / scale < 1.0:
            exp -= 1
            scale = 10.0**exp

    # plot histogram using scaled units
    hist_vals = abs_delta / scale
    hist_ax.hist(hist_vals, bins=args.bins, color="tab:blue", edgecolor="black")
    # vertical line at zero
    hist_ax.axvline(0.0, color="red", linewidth=2.0)
    hist_ax.set_title("Histogramme |Δp95|", fontsize=9)
    # x-label with multiplier
    hist_ax.set_xlabel(f"$\\times 10^{{{exp}}}$", fontsize=8)
    hist_ax.tick_params(axis="both", which="major", labelsize=8)

    # Optionally draw zoom inset (disabled by default)
    if args.with_zoom:
        # determine zoom window (centered near middle if not provided)
        if args.zoom_center_x is None:
            zx_center = 3.0 if (np.max(x) > 3.0) else 0.5 * (lo + hi)
        else:
            zx_center = args.zoom_center_x
        if args.zoom_center_y is None:
            zy_center = zx_center
        else:
            zy_center = args.zoom_center_y
        # small window width ~0.3 of range or fixed
        dx = 0.06 * (hi - lo) if (hi - lo) > 0 else 0.1
        dy = dx
        zx0, zx1 = zx_center - dx / 2.0, zx_center + dx / 2.0
        zy0, zy1 = zy_center - dy / 2.0, zy_center + dy / 2.0

        inset_w = args.zoom_w
        inset_h = args.zoom_h
        inz = inset_axes(
            ax,
            width=f"{inset_w * 100}%",
            height=f"{inset_h * 100}%",
            bbox_to_anchor=(0.48, 0.58, inset_w, inset_h),
            bbox_transform=fig.transFigure,
            loc="lower left",
            borderpad=1.0,
        )
        # plot points in inset
        inz.scatter(
            x,
            y,
            c=abs_delta,
            s=max(1.0, args.point_size / 2.0),
            alpha=min(1.0, args.alpha + 0.1),
            cmap=args.cmap,
            edgecolor="none",
            vmin=0.0,
            vmax=vmax,
        )
        inz.plot([zx0, zx1], [zx0, zx1], color="gray", linestyle="--", linewidth=0.8)
        inz.set_xlim(zx0, zx1)
        inz.set_ylim(zy0, zy1)
        inz.set_title("zoom", fontsize=8)
        mark_inset(ax, inz, loc1=2, loc2=4, fc="none", ec="0.5", lw=0.8)

    # Footnote
    foot = (
        r"$\Delta p95 = p95_{recalc} - p95_{orig}$. Couleur = $|\Delta p95|$. "
        "Zoom optionnel (--with-zoom). Histogramme déplacé (place & taille paramétrables)."
    )
    fig.text(0.5, 0.02, foot, ha="center", fontsize=9)

    plt.tight_layout(rect=[0, 0.04, 1, 0.98])
    fig.savefig(args.out, dpi=args.dpi)
    print(f"Wrote: {args.out}")


if __name__ == "__main__":
    main()
