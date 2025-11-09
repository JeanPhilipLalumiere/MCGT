#!/usr/bin/env python3
from __future__ import annotations
import argparse, os
import numpy as np, pandas as pd
import matplotlib.pyplot as plt

DEF_RESULTS = "zz-data/chapter10/10_metrics_primary.csv"

def add_common_plot_args(p: argparse.ArgumentParser) -> None:
    p.add_argument("--outdir", default=".ci-out/smoke_v1")
    p.add_argument("--format", default="png", choices=["png","pdf","svg"])
    p.add_argument("--dpi", type=int, default=120)
    p.add_argument("--style", default="classic")
    p.add_argument("--figsize", default="10,4")
    p.add_argument("--transparent", action="store_true")
    p.add_argument("--save-pdf", dest="save_pdf", action="store_true")
    p.add_argument("--save-svg", dest="save_svg", action="store_true")
    p.add_argument("--show", action="store_true")

def parse_figsize(s: str) -> tuple[float,float]:
    try: w,h = s.split(","); return float(w), float(h)
    except Exception: return (10.0, 4.0)

def ensure_outpath(args) -> str:
    os.makedirs(args.outdir, exist_ok=True)
    return os.path.join(args.outdir, "chapter10_fig05_hist_cdf."+args.format)

def save_figure(fig, outpath: str, fmt: str, dpi: int, transparent: bool, save_pdf: bool, save_svg: bool):
    fig.savefig(outpath, dpi=dpi, transparent=transparent)
    if save_pdf: fig.savefig(outpath.rsplit(".",1)[0]+".pdf")
    if save_svg: fig.savefig(outpath.rsplit(".",1)[0]+".svg")

def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="Hist & CDF — metrics (standalone)")
    add_common_plot_args(p)
    p.add_argument("--results", default=DEF_RESULTS)
    p.add_argument("--metrics", nargs="*", default=None)
    p.add_argument("--bins", type=int, default=50)
    return p

def select_numeric_columns(df: pd.DataFrame, user_cols: list[str] | None) -> list[str]:
    if user_cols: return [c for c in user_cols if c in df.columns]
    num = df.select_dtypes(include=[np.number]).columns.tolist()
    blacklist = {"idx","id","run","seed"}
    return [c for c in num if c.lower() not in blacklist]

def main(argv=None) -> int:
    args = build_parser().parse_args(argv)
    try: plt.style.use(args.style)
    except Exception: pass
    out = ensure_outpath(args); figsize = parse_figsize(args.figsize)

    fig = plt.figure(figsize=figsize)
    ax_hist = fig.add_subplot(1,2,1)
    ax_cdf  = fig.add_subplot(1,2,2)

    if not os.path.isfile(args.results):
        ax_hist.text(0.5,0.5,"Fichier résultats manquant",ha="center",va="center",transform=ax_hist.transAxes)
        ax_cdf.text(0.5,0.5,args.results,ha="center",va="center",transform=ax_cdf.transAxes)
        ax_hist.set_axis_off(); ax_cdf.set_axis_off()
        save_figure(fig, out, args.format, args.dpi, args.transparent, args.save_pdf, args.save_svg)
        return 0

    df = pd.read_csv(args.results)
    metrics = select_numeric_columns(df, args.metrics)
    if not metrics:
        ax_hist.text(0.5,0.5,"Aucune métrique numérique",ha="center",va="center",transform=ax_hist.transAxes)
        ax_cdf.set_axis_off()
        save_figure(fig, out, args.format, args.dpi, args.transparent, args.save_pdf, args.save_svg)
        return 2

    for col in metrics:
        s = df[col].dropna().values
        if s.size == 0: continue
        ax_hist.hist(s, bins=args.bins, alpha=0.45, label=col, density=True)
        x = np.sort(s); y = np.linspace(0.0, 1.0, x.size, endpoint=True)
        ax_cdf.plot(x, y, label=col)

    ax_hist.set_xlabel("Valeur"); ax_hist.set_ylabel("Densité (normée)"); ax_hist.grid(True, linestyle=":", linewidth=0.5)
    ax_cdf.set_xlabel("Valeur"); ax_cdf.set_ylabel("CDF empirique");     ax_cdf.grid(True, linestyle=":", linewidth=0.5)
    ax_hist.legend(fontsize=8); ax_cdf.legend(fontsize=8)
    fig.suptitle("Chapitre 10 — Histogrammes & CDF des métriques", y=0.98)

    save_figure(fig, out, args.format, args.dpi, args.transparent, args.save_pdf, args.save_svg)
    if args.show: plt.show()
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
