#!/usr/bin/env python3
"""
plot_fig01_iso_p95_maps.py
Carte iso-valeurs d'un p95 (ou métrique équivalente) sur (m1, m2) à partir d'un CSV.
- Détection robuste de la colonne p95 (ou --p95-col)
- Tricontours + scatter des échantillons
"""

from __future__ import annotations

import argparse
import sys
import warnings

import matplotlib.pyplot as plt
import matplotlib.tri as tri
import numpy as np
import pandas as pd
from zz_tools import common_io as ci

from matplotlib import colors

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
        if "p95" in c.lower(): return c
    raise KeyError("Aucune colonne 'p95' détectée dans le fichier results.")


def read_and_validate(path, m1_col, m2_col, p95_col):
    """Read CSV and validate presence of required columns. Return trimmed DataFrame."""
    try:
        df = pd.read_csv(path)
        df = ci.ensure_fig02_cols(df)

    except Exception as e:
        raise SystemExit(f"Erreur lecture CSV '{path}': {e}")
    for col in (m1_col, m2_col, p95_col):
        if col not in df.columns: raise KeyError(f"Colonne attendue absente: {col}")
    df = df[[m1_col, m2_col, p95_col]].dropna().astype(float)
    if df.shape[0] == 0: raise ValueError("Aucune donnée valide après suppression des NaN.")
    return df


def make_triangulation_and_mask(x, y):
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
    ap.add_argument(
        "--results", required=True, help="CSV results (must contain m1,m2 and p95)."
    )
    ap.add_argument(
        "--p95-col", default=None, help="p95 column name (auto detect if omitted)"
    )
    ap.add_argument("--m1-col", default="m1", help="column name for m1")
    ap.add_argument("--m2-col", default="m2", help="column name for m2")
    ap.add_argument(
        "--out",
        default="zz-figures/chapter10/10_fig_01_iso_p95_maps.png",
        help="output PNG file",
    )
    ap.add_argument("--levels", type=int, default=16, help="number of contour levels")
    ap.add_argument("--cmap", default="viridis", help="colormap")
    ap.add_argument("--dpi", type=int, default=150, help="png dpi")
    ap.add_argument(
        "--title", default="Carte iso de p95 (m1 vs m2)", help="figure title"
    )
    ap.add_argument(
        "--no-clip",
        action="store_true",
        help="do not clip color scale to percentiles (show full range)",
    )
    args = ap.parse_args()
    try: df_all = pd.read_csv(args.results)
    except Exception as e: print(f"[ERROR] Cannot read '{args.results}': {e}", file=sys.stderr); sys.exit(2)
    try: p95_col = detect_p95_column(df_all, args.p95_col)
    except KeyError as e: print(f"[ERROR] {e}", file=sys.stderr); sys.exit(2)
    try: df = read_and_validate(args.results, args.m1_col, args.m2_col, p95_col)
    except Exception as e: print(f"[ERROR] {e}", file=sys.stderr); sys.exit(2)
    x, y, z = df[args.m1_col].values, df[args.m2_col].values, df[p95_col].values
    triang = make_triangulation_and_mask(x, y)
    zmin, zmax = float(np.nanmin(z)), float(np.nanmax(z))
    if zmax - zmin < 1e-8: zmax = zmin + 1e-6
    levels = np.linspace(zmin, zmax, args.levels)
    vmin, vmax, clipped = zmin, zmax, False
    if not args.no_clip:
        try: p_lo, p_hi = np.percentile(z, [0.1, 99.9])
        except Exception: p_lo, p_hi = zmin, zmax
        if p_hi - p_lo > 1e-8 and (p_lo > zmin or p_hi < zmax):
            vmin, vmax, clipped = float(p_lo), float(p_hi), True
            warnings.warn(f"Clipping [{vmin:.4g}, {vmax:.4g}] (0.1%–99.9%).")
    norm = colors.Normalize(vmin=vmin, vmax=vmax, clip=True)
    plt.style.use("classic")
    fig, ax = plt.subplots(figsize=(10, 8))
    cf = ax.tricontourf(triang, z, levels=levels, cmap=args.cmap, alpha=0.95, norm=norm)
    _cs = ax.tricontour(
        triang, z, levels=levels, colors="k", linewidths=0.45, alpha=0.5
    )

    # scatter overlay (points) - smaller, semi-transparent
    ax.scatter(
        x, y, c="k", s=3, alpha=0.5, edgecolors="none", label="échantillons", zorder=5
    )

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
        fig.subplots_adjust(left=0.04, right=0.98, bottom=0.06, top=0.96)

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



# === MCGT:CLI-SHIM-BEGIN ===
# Idempotent. Expose: --out/--dpi/--format/--transparent/--style/--verbose
# Ne modifie pas la logique existante : parse_known_args() au module-scope.

def _mcgt_cli_shim_parse_known():
    import argparse, sys
    p = argparse.ArgumentParser(add_help=False)
    p.add_argument("--out", type=str, default=None, help="Chemin de sortie (optionnel).")
    p.add_argument("--dpi", type=int, default=None, help="DPI de sortie (optionnel).")
    p.add_argument("--format", type=str, default=None, choices=["png","pdf","svg"], help="Format de sortie.")
    p.add_argument("--transparent", action="store_true", help="Fond transparent si supporté.")
    p.add_argument("--style", type=str, default=None, help="Style matplotlib (optionnel).")
    p.add_argument("--verbose", action="store_true", help="Verbosité accrue.")
    args, _ = p.parse_known_args(sys.argv[1:])
    try:
        import matplotlib as _mpl
        if args.style:
            import matplotlib.pyplot as _plt  # force init si besoin
            _mpl.style.use(args.style)
        if args.dpi and hasattr(_mpl, "rcParams"):
            _mpl.rcParams["figure.dpi"] = int(args.dpi)
    except Exception:
        # Ne jamais casser le producteur si style/DPI échoue.
        pass
    return args

try:
    MCGT_CLI = _mcgt_cli_shim_parse_known()
except Exception:
    MCGT_CLI = None
# === MCGT:CLI-SHIM-END ===

