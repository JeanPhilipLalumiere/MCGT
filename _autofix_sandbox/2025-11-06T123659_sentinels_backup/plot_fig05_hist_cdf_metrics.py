#!/usr/bin/env python3
from __future__ import annotations
import argparse, os, sys, pathlib
import numpy as np, pandas as pd
import matplotlib.pyplot as plt
try:
    from _common import cli as C
except Exception:
    sys.path.append(str(pathlib.Path(__file__).resolve().parents[1]))
    from _common import cli as C

DEF_RESULTS = "zz-data/chapter10/10_metrics_primary.csv"

def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="Chap10 Hist & CDF des métriques (homogène)")
    C.add_common_plot_args(p)
    p.add_argument("--results", default=DEF_RESULTS, help="CSV des métriques")
    p.add_argument("--metrics", nargs="*", default=None, help="Colonnes à tracer (auto si vide)")
    p.add_argument("--bins", type=int, default=50)
    return p

def select_numeric_columns(df: pd.DataFrame, user_cols: list[str] | None) -> list[str]:
    if user_cols: return [c for c in user_cols if c in df.columns]
    num = df.select_dtypes(include=[np.number]).columns.tolist()
    blacklist = {"idx","id","run","seed"}
    return [c for c in num if c.lower() not in blacklist]

def main(argv=None) -> int:
    args = build_parser().parse_args(argv)
    args._stem = "chapter10_fig05_hist_cdf"
    log = C.setup_logging(args.log_level)
    C.setup_mpl(args.style)
    out = C.ensure_outpath(args)
    figsize = C.parse_figsize(args.figsize)

    fig = plt.figure(figsize=figsize)
    ax_hist = fig.add_subplot(1,2,1)
    ax_cdf  = fig.add_subplot(1,2,2)

    if not os.path.isfile(args.results):
        log.warning("CSV manquant → %s", args.results)
        ax_hist.text(0.5, 0.5, "Fichier résultats manquant", ha="center", va="center", transform=ax_hist.transAxes)
        ax_cdf.text(0.5, 0.5, args.results, ha="center", va="center", transform=ax_cdf.transAxes)
        ax_hist.set_axis_off(); ax_cdf.set_axis_off()
        C.save_figure(fig, out, args.format, args.dpi, args.transparent, args.save_pdf, args.save_svg)
        return 0

    df = pd.read_csv(args.results)
    metrics = select_numeric_columns(df, args.metrics)
    if not metrics:
        log.error("Aucune colonne numérique détectée (ou métriques inconnues).")
        ax_hist.text(0.5,0.5,"Aucune métrique à tracer",ha="center",va="center",transform=ax_hist.transAxes)
        ax_cdf.set_axis_off()
        C.save_figure(fig, out, args.format, args.dpi, args.transparent, args.save_pdf, args.save_svg)
        return 2

    for col in metrics:
        s = df[col].dropna().values
        if s.size == 0: continue
        ax_hist.hist(s, bins=args.bins, alpha=0.45, label=col, density=True)
        x = np.sort(s); y = np.linspace(0.0, 1.0, x.size, endpoint=True)
        ax_cdf.plot(x, y, label=col)

    ax_hist.set_xlabel("Valeur"); ax_hist.set_ylabel("Densité (normée)"); ax_hist.grid(True, linestyle=":", linewidth=0.5)
    ax_cdf.set_xlabel("Valeur");  ax_cdf.set_ylabel("CDF empirique");     ax_cdf.grid(True, linestyle=":", linewidth=0.5)
    ax_hist.legend(fontsize=8); ax_cdf.legend(fontsize=8)
    fig.suptitle("Chapitre 10 — Histogrammes & CDF des métriques", y=0.98)
    C.save_figure(fig, out, args.format, args.dpi, args.transparent, args.save_pdf, args.save_svg)
    if args.show: plt.show()
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
