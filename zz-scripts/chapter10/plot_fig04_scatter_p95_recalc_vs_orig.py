#!/usr/bin/env python3
"""
plot_fig04_scatter_p95_recalc_vs_orig.py

"""

from __future__ import annotations

import argparse

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from mpl_toolkits.axes_grid1.inset_locator import inset_axes, mark_inset


def detect_column(df: pd.DataFrame, hint: str | None, candidates: list[str]) -> str:
    if hint and hint in df.columns:
        return hint
    for c in candidates:
        if c in df.columns:
            return c
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
    exp = int(np.floor(np.log10(abs(v))))
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
        "--out",
        default="zz-figures/chapter10/10_fig_04_scatter_p95_recalc_vs_orig.png",
        help="Output PNG",
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

    df = pd.read_csv(args.results)
    orig_col = detect_column(df, args.orig_col, [args.orig_col])
    recalc_col = detect_column(df, args.recalc_col, [args.recalc_col])

    sub = df[[orig_col, recalc_col]].dropna().astype(float).copy()
    x = sub[orig_col].values
    y = sub[recalc_col].values
    if x.size == 0:
        raise SystemExit("Aucun point non-NA trouvé.")

    delta = y - x
    abs_delta = np.abs(delta)

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

    plt.style.use("classic")
    fig, ax = plt.subplots(figsize=(10, 10))

    if abs_delta.size == 0:
        vmax = 1.0
    else:
        vmax = float(np.percentile(abs_delta, 99.9))
        if vmax <= 0.0:
            vmax = float(np.max(abs_delta))
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

    lo = min(np.min(x), np.min(y))
    hi = max(np.max(x), np.max(y))
    ax.plot([lo, hi], [lo, hi], color="gray", linestyle="--", linewidth=1.0, zorder=1)

    ax.set_xlabel(f"{orig_col} [rad]")
    ax.set_ylabel(f"{recalc_col} [rad]")
    ax.set_title(args.title, fontsize=15)

    extend = "max" if np.max(abs_delta) > vmax else "neither"
    cbar = fig.colorbar(sc, ax=ax, extend=extend, pad=0.02)
    cbar.set_label(r"$|\Delta p95|$ [rad]")

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

    hist_base_w = 0.18
    hist_base_h = 0.14
    hist_w = hist_base_w * args.hist_scale
    hist_h = hist_base_h * args.hist_scale
    hist_x = args.hist_x
    hist_y = args.hist_y
    hist_ax = inset_axes(
        ax,
        width=f"{hist_w * 100}%",
        height=f"{hist_h * 100}%",
        bbox_to_anchor=(hist_x, hist_y, hist_w, hist_h),
        bbox_transform=fig.transFigure,
        loc="lower left",
        borderpad=1.0,
    )

    max_abs = float(np.max(abs_delta)) if abs_delta.size else 0.0
    if max_abs <= 0.0:
        scale = 1.0
        exp = 0
    else:
        exp = int(np.floor(np.log10(max_abs)))
        scale = 10.0**exp
        if max_abs / scale < 1.0:
            exp -= 1
            scale = 10.0**exp

    hist_vals = abs_delta / scale
    hist_ax.hist(hist_vals, bins=args.bins, color="tab:blue", edgecolor="black")
    hist_ax.axvline(0.0, color="red", linewidth=2.0)
    hist_ax.set_title("Histogramme |Δp95|", fontsize=9)
    hist_ax.set_xlabel(f"$\\times 10^{{{exp}}}$", fontsize=8)
    hist_ax.tick_params(axis="both", which="major", labelsize=8)

    if args.with_zoom:
        if args.zoom_center_x is None:
            zx_center = 3.0 if (np.max(x) > 3.0) else 0.5 * (lo + hi)
        else:
            zx_center = args.zoom_center_x
        if args.zoom_center_y is None:
            zy_center = zx_center
        else:
            zy_center = args.zoom_center_y
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
