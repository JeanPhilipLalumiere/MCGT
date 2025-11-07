# === [HELP-SHIM v1] ===
try:
    import sys, os, argparse
    if any(a in ('-h','--help') for a in sys.argv[1:]):
        os.environ.setdefault('MPLBACKEND','Agg')
        parser = argparse.ArgumentParser(
            description="(shim) aide minimale sans effets de bord",
            add_help=True, allow_abbrev=False)
        try:
            from _common.cli import add_common_plot_args as _add
            _add(parser)
        except Exception:
            pass
        parser.add_argument('--out', help='fichier de sortie', default=None)
        parser.add_argument('--dpi', type=int, default=150)
        parser.add_argument('--log-level', choices=['DEBUG','INFO','WARNING','ERROR'], default='INFO')
        parser.print_help()
        sys.exit(0)
except SystemExit:
    raise
except Exception:
    pass
# === [/HELP-SHIM v1] ===


from _common.cli import add_common_plot_args, finalize_plot_from_args, init_logging
#!/usr/bin/env python3
# Rewritten clean version (Round3) — 20251105T182218Z
import argparse, sys, warnings
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.tri as mtri

def _detect_col(df, candidates):
    for c in candidates:
        if c and c in df.columns: return c
    raise KeyError(f"None of {candidates} found in columns={list(df.columns)[:20]}...")

def _parse_pair(pair_str):
    a,b = (s.strip() for s in pair_str.split(","))
    return float(a), float(b)

def build_parser() -> argparse.ArgumentParser:

    p = argparse.ArgumentParser(description="(autofix)",  required=True, help="CSV with m1,m2,p95")

    p.add_argument("--m1-col", dest="m1_col", default="m1")

    p.add_argument("--m2-col", dest="m2_col", default="m2")

    p.add_argument("--p95-col", dest="p95_col", default=None,

    help="p95 column (e.g. p95_20_300). If not set, tries common names.")

    p.add_argument("--levels", type=int, default=10)

    p.add_argument("--vclip", default="0.1,99.9", help="percentiles for vmin,vmax")

    p.add_argument("--figsize", default="8,6")

    p.add_argument("--dpi", type=int, default=150)

    p.add_argument("--cmap", default="viridis")

    p.add_argument("--title", default=r"Cartes iso-$p_{95}$")

    p.add_argument("--out", default="plot_fig01_iso_p95_maps.png")

    return p

def main(argv=None):
    args = build_parser().parse_args(argv)
    try:
        with warnings.catch_warnings():
            warnings.simplefilter("ignore")
            df = pd.read_csv(args.results).dropna(subset=[args.m1_col, args.m2_col])
            m1 = df[args.m1_col].astype(float).values
            m2 = df[args.m2_col].astype(float).values
            p95_col = _detect_col(df, [args.p95_col, "p95_20_300", "p95"])
            z = df[p95_col].astype(float).values

            # domain & levels
            p_lo, p_hi = _parse_pair(args.vclip)
            vmin = float(np.percentile(z, p_lo))
            vmax = float(np.percentile(z, p_hi))
            if vmin == vmax:
                vmax = vmin + 1e-12
            levels = np.linspace(vmin, vmax, num=max(3, int(args.levels)))

            # triangulation + contours
            w,h = _parse_pair(args.figsize)
            plt.style.use("classic")
            fig, ax = plt.subplots(figsize=(w,h), dpi=args.dpi)
            tri = mtri.Triangulation(m1, m2)

            cf = ax.tricontourf(tri, z, levels=levels, cmap=args.cmap)
            ax.tricontour(tri, z, levels=levels, colors="k", linewidths=0.45, alpha=0.6)

            # scatter overlay for context
            ax.scatter(m1, m2, c="k", s=3, alpha=0.4, edgecolors="none", label="échantillons", zorder=5)

            cbar = fig.colorbar(cf, ax=ax, shrink=0.85)
            cbar.set_label(f"{p95_col} [rad]")
            ax.set_xlabel(args.m1_col); ax.set_ylabel(args.m2_col)
            ax.set_title(args.title, fontsize=15)
            ax.legend(loc="upper right", frameon=True, fontsize=9)

            # bounds with light padding
            xmin, xmax = float(np.min(m1)), float(np.max(m1))
            ymin, ymax = float(np.min(m2)), float(np.max(m2))
            xpad = 0.02 * (xmax - xmin) if xmax > xmin else 0.5
            ypad = 0.02 * (ymax - ymin) if ymax > ymin else 0.5
            ax.set_xlim(xmin - xpad, xmax + xpad)
            ax.set_ylim(ymin - ypad, ymax + ypad)

            fig.tight_layout()
            fig.savefig(args.out, dpi=args.dpi)
            print(f"Wrote: {args.out}")
    except Exception as e:
        print(f"[ERROR] iso_p95 failed: {e}", file=sys.stderr)
        sys.exit(2)

if __name__ == "__main__":
    main()
