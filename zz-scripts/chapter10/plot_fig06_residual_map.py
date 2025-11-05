#!/usr/bin/env python3
# Rewritten clean version (Round3) — 20251105T182218Z
import argparse, sys, warnings
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

def _detect_col(df, candidates):
    for c in candidates:
        if c and c in df.columns: return c
    raise KeyError(f"None of {candidates} found in columns={list(df.columns)[:20]}...")

def _parse_pair(pair_str):
    a,b = (s.strip() for s in pair_str.split(","))
    return float(a), float(b)

def build_parser():
    p = argparse.ArgumentParser(description="Residual hexbin map for Δp95 over (m1,m2)")
    p.add_argument("--results", required=True, help="CSV with m1,m2 and p95 columns")
    p.add_argument("--m1-col", dest="m1_col", default="m1")
    p.add_argument("--m2-col", dest="m2_col", default="m2")
    p.add_argument("--orig-col", default=None, help="original p95 column (e.g. p95_20_300)")
    p.add_argument("--recalc-col", default=None, help="recalculated p95 column (e.g. p95_20_300_recalc)")
    p.add_argument("--metric", default="dp95", choices=["dp95"], help="residual metric")
    p.add_argument("--abs", action="store_true", help="use absolute value |Δp95|")
    p.add_argument("--scale-exp", dest="scale_exp", type=float, default=0.0, help="display scale ×10^exp")
    p.add_argument("--vclip", default="0.1,99.9", help="percentiles for vmin,vmax (on scaled)")
    p.add_argument("--no-clip", action="store_true", help="disable percentile clipping")
    p.add_argument("--figsize", default="9,6", help="width,height (inches)")
    p.add_argument("--dpi", type=int, default=150)
    p.add_argument("--cmap", default="viridis")
    p.add_argument("--gridsize", type=int, default=50)
    p.add_argument("--mincnt", type=int, default=1)
    p.add_argument("--threshold", type=float, default=1.0, help="note: fraction of |Δp95| > threshold is reported")
    p.add_argument("--title", default=r"Carte résidus $\Delta p_{95}$ sur $(m_1,m_2)$")
    p.add_argument("--out", default="plot_fig06_residual_map.png")
    return p

def main(argv=None):
    args = build_parser().parse_args(argv)
    try:
        with warnings.catch_warnings():
            warnings.simplefilter("ignore")
            df = pd.read_csv(args.results).dropna(subset=[args.m1_col, args.m2_col])
            m1 = df[args.m1_col].astype(float).values
            m2 = df[args.m2_col].astype(float).values

            col_o = _detect_col(df, [args.orig_col, "p95_20_300", "p95"])
            col_r = _detect_col(df, [args.recalc_col, "p95_20_300_recalc", "p95_recalc"])

            raw = df[col_r].astype(float).values - df[col_o].astype(float).values
            metric_name = r"\Delta p_{95}"
            if args.abs:
                raw = np.abs(raw)
                metric_label = rf"|{metric_name}|"
            else:
                metric_label = rf"{metric_name}"

            # scaling for display
            scale = 10.0**args.scale_exp
            scaled = raw / scale

            # vmin/vmax
            if args.no_clip:
                vmin, vmax = float(np.min(scaled)), float(np.max(scaled))
            else:
                p_lo, p_hi = _parse_pair(args.vclip)
                vmin = float(np.percentile(scaled, p_lo))
                vmax = float(np.percentile(scaled, p_hi))
                if vmin == vmax:
                    vmax = vmin + 1e-12

            # stats
            med = float(np.median(scaled))
            mean = float(np.mean(scaled))
            std = float(np.std(scaled, ddof=0))
            p95 = float(np.percentile(scaled, 95.0))
            frac_over = float(np.mean(np.abs(raw) > args.threshold))

            # figure
            w,h = _parse_pair(args.figsize)
            plt.style.use("classic")
            fig = plt.figure(figsize=(w,h), dpi=args.dpi)
            ax_main = fig.add_axes([0.07, 0.145, 0.56, 0.74])
            ax_cbar = fig.add_axes([0.645, 0.145, 0.025, 0.74])
            right_left, right_w = 0.75, 0.23
            ax_cnt  = fig.add_axes([right_left, 0.60, right_w, 0.30])
            ax_hist = fig.add_axes([right_left, 0.20, right_w, 0.30])

            hb = ax_main.hexbin(m1, m2, C=scaled, gridsize=args.gridsize,
                                reduce_C_function=np.median, mincnt=args.mincnt,
                                vmin=vmin, vmax=vmax, cmap=args.cmap)
            cbar = fig.colorbar(hb, cax=ax_cbar)
            exp_txt = f"× 10^{args.scale_exp}" if args.scale_exp else ""
            cbar.set_label(rf"{metric_label} {exp_txt} [rad]")

            ax_main.set_title(args.title)
            ax_main.set_xlabel(args.m1_col); ax_main.set_ylabel(args.m2_col)
            ax_main.text(0.02, 0.02, f"Hexagones vides = count < {args.mincnt}",
                         transform=ax_main.transAxes, ha="left", va="bottom",
                         bbox=dict(boxstyle="round", fc="white", ec="0.5", alpha=0.9),
                         fontsize=9)

            # side: contour of density (counts) and histogram of scaled
            # counts grid (rough)
            ax_cnt.set_title("Densité (approx.)", fontsize=10)
            ax_cnt.hexbin(m1, m2, gridsize=args.gridsize, mincnt=args.mincnt, cmap="Greys")
            ax_cnt.set_xticks([]); ax_cnt.set_yticks([])

            ax_hist.set_title("Distribution (scaled)", fontsize=10)
            ax_hist.hist(scaled, bins=50, density=True, alpha=0.8)
            ax_hist.axvline(med, color="k", lw=1, ls="--", label=f"med={med:.3g}")
            ax_hist.legend(loc="best", fontsize=9)

            fig.subplots_adjust(left=0.04, right=0.98, bottom=0.06, top=0.96)
            fig.savefig(args.out, dpi=args.dpi)
            print(f"Wrote: {args.out}  (frac(|Δp95|>{args.threshold})={frac_over:.3f}, mean={mean:.3g}, std={std:.3g})")
    except Exception as e:
        print(f"[ERROR] residual_map failed: {e}", file=sys.stderr)
        sys.exit(2)

if __name__ == "__main__":
    main()
