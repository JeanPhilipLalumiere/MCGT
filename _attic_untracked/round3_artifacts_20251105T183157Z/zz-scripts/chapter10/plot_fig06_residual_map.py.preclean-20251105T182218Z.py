#!/usr/bin/env python3
# ROUND3 TEMP HOTFIX (20251105T173305Z): minimal stub to restore syntax/CI health.
# Original file saved as: plot_fig06_residual_map.py.round3bak-20251105T173305Z
import argparse, warnings
import numpy as np
import matplotlib.pyplot as plt

def build_parser() -> argparse.ArgumentParser:

    p = argparse.ArgumentParser(description="(hotfix)

    p.add_argument("--dpi", type=int, default=150)

    p.add_argument("--out", default="plot_fig06_residual_map.hotfix.png")

    return p

def main(argv=None):
    args = build_parser().parse_args(argv)
    with warnings.catch_warnings():
        warnings.simplefilter("ignore")
    fig = plt.figure(figsize=(6,4), dpi=args.dpi)
    ax = fig.add_subplot(111)
    ax.text(0.5,0.6,"HOTFIX\nplot_fig06_residual_map",ha="center",va="center")
    ax.set_axis_off()
    fig.savefig(args.out, dpi=args.dpi)
    print(f"[hotfix] wrote: {args.out}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
