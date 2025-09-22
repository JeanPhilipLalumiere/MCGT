#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
plot_fig01_iso_p95_maps.py

"""

from __future__ import annotations
import argparse
import warnings
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.tri as tri
from matplotlib import colors
import sys

# ---------- utilities ----------


def detect_p95_column(df: pd.DataFrame, hint: str | None):
    """Try to find the p95 column using hint or sensible defaults."""
    if hint and hint in df.columns:
        return hint
    candidates = [
        "p95_20_300_recalc",
        "p95_20_300_circ",
        "p95_20_300",
        "p95_circ",
        "p95_recalc",
        "p95",
    ]
    for c in candidates:
        if c in df.columns:
            return c
    for c in df.columns:
        if "p95" in c.lower():
            return c
    raise KeyError("Aucune colonne 'p95' détectée dans le fichier results.")


def read_and_validate(path, m1_col, m2_col, p95_col):
    """Read CSV and validate presence of required columns. Return trimmed DataFrame."""
    try:
        df = pd.read_csv(path)
    except Exception as e:
        raise SystemExit(f"Erreur lecture CSV '{path}': {e}")
    for col in (m1_col, m2_col, p95_col):
        if col not in df.columns:
            raise KeyError(f"Colonne attendue absente: {col}")
    # drop missing and cast to float
    df = df[[m1_col, m2_col, p95_col]].dropna().astype(float)
    if df.shape[0] == 0:
        raise ValueError("Aucune donnée valide après suppression des NaN.")
    return df


def make_triangulation_and_mask(x, y):
    """
    Build a triangulation for scattered (x,y). Return triang and a simple
    mask that removes zero-area triangles.
    """
    triang = tri.Triangulation(x, y)
    try:
        tris = triang.triangles
        x1 = x[tris[:, 0]]
        x2 = x[tris[:, 1]]
        x3 = x[tris[:, 2]]
        y1 = y[tris[:, 0]]
        y2 = y[tris[:, 1]]
        y3 = y[tris[:, 2]]
        areas = 0.5 * np.abs((x2 - x1) * (y3 - y1) - (x3 - x1) * (y2 - y1))
        mask = areas <= 0.0
        # triang.set_mask expects boolean mask with same length as triangles
        triang.set_mask(mask)
    except Exception:
        # if something fails, just return triang without extra masking
        pass
    return triang


# ---------- main ----------


def main():
    ap = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    ap.add_argument("--results", required=True, help="CSV results (must contain m1,m2 and p95).")
    ap.add_argument("--p95-col", default=None, help="p95 column name (auto detect if omitted)")
    ap.add_argument("--m1-col", default="m1", help="column name for m1")
    ap.add_argument("--m2-col", default="m2", help="column name for m2")
    ap.add_argument(
        "--out", default="zz-figures/chapter10/fig_01_iso_map_p95.png", help="output PNG file"
    )
    ap.add_argument("--levels", type=int, default=16, help="number of contour levels")
    ap.add_argument("--cmap", default="viridis", help="colormap")
    ap.add_argument("--dpi", type=int, default=150, help="png dpi")
    ap.add_argument("--title", default="Carte iso de p95 (m1 vs m2)", help="figure title")
    ap.add_argument(
        "--no-clip",
        action="store_true",
        help="do not clip color scale to percentiles (show full range)",
    )
    args = ap.parse_args()

    # Read & detect columns
    try:
        df_all = pd.read_csv(args.results)
    except Exception as e:
        print(f"[ERROR] Cannot read results CSV '{args.results}': {e}", file=sys.stderr)
        sys.exit(2)

    try:
        p95_col = detect_p95_column(df_all, args.p95_col)
    except KeyError as e:
        print(f"[ERROR] {e}", file=sys.stderr)
        sys.exit(2)

    try:
        df = read_and_validate(args.results, args.m1_col, args.m2_col, p95_col)
    except Exception as e:
        print(f"[ERROR] {e}", file=sys.stderr)
        sys.exit(2)

    x = df[args.m1_col].values
    y = df[args.m2_col].values
    z = df[p95_col].values

    # triangulation for scattered contour
    triang = make_triangulation_and_mask(x, y)

    # compute contour levels and color scaling
    zmin, zmax = float(np.nanmin(z)), float(np.nanmax(z))
    if zmax - zmin < 1e-8:
        zmax = zmin + 1e-6
    levels = np.linspace(zmin, zmax, args.levels)

    vmin = zmin
    vmax = zmax
    clipped = False
    if not args.no_clip:
        # compute percentiles for clipping
        try:
            p_lo, p_hi = np.percentile(z, [0.1, 99.9])
        except Exception:
            p_lo, p_hi = zmin, zmax
        # only clip if it reduces range significantly
        if p_hi - p_lo > 1e-8 and (p_lo > zmin or p_hi < zmax):
            vmin, vmax = float(p_lo), float(p_hi)
            clipped = True
            warnings.warn(
                f"Detected extreme p95 values: display clipped to [{vmin:.4g}, {vmax:.4g}] "
                "(0.1% - 99.9% percentiles) to avoid burning the colormap."
            )

    norm = colors.Normalize(vmin=vmin, vmax=vmax, clip=True)

    # plot
    plt.style.use("classic")
    fig, ax = plt.subplots(figsize=(10, 8))

    # tricontourf with normalization
    cf = ax.tricontourf(triang, z, levels=levels, cmap=args.cmap, alpha=0.95, norm=norm)
    _cs = ax.tricontour(triang, z, levels=levels, colors="k", linewidths=0.45, alpha=0.5)

    # scatter overlay (points) - smaller, semi-transparent
    ax.scatter(x, y, c="k", s=3, alpha=0.5, edgecolors="none", label="échantillons", zorder=5)

    # colorbar (respect the norm)
    cbar = fig.colorbar(cf, ax=ax, shrink=0.8)
    cbar.set_label(f"{p95_col} [rad]")

    ax.set_xlabel(args.m1_col)
    ax.set_ylabel(args.m2_col)

    # title size 15 exactly
    ax.set_title(args.title, fontsize=15)

    # bounding box for full data (small margin)
    xmin, xmax = float(np.min(x)), float(np.max(x))
    ymin, ymax = float(np.min(y)), float(np.max(y))
    xpad = 0.02 * (xmax - xmin) if xmax > xmin else 0.5
    ypad = 0.02 * (ymax - ymin) if ymax > ymin else 0.5
    ax.set_xlim(xmin - xpad, xmax + xpad)
    ax.set_ylim(ymin - ypad, ymax + ypad)

    # small legend
    leg = ax.legend(loc="upper right", frameon=True, fontsize=9)
    leg.set_zorder(20)

    # tight layout and save
    with warnings.catch_warnings():
        warnings.simplefilter("ignore")
        plt.tight_layout()

    try:
        fig.savefig(args.out, dpi=args.dpi)
        print(f"Wrote: {args.out}")
        if clipped:
            print(
                "Note: color scaling was clipped to percentiles (0.1%/99.9%). Use --no-clip to disable clipping."
            )
    except Exception as e:
        print(f"[ERROR] cannot write output file '{args.out}': {e}", file=sys.stderr)
        sys.exit(2)


if __name__ == "__main__":
    main()
