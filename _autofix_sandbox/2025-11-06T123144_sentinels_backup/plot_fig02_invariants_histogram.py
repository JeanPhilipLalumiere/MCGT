#!/usr/bin/env python3
from __future__ import annotations
import argparse, os
import numpy as np, pandas as pd
import matplotlib.pyplot as plt

DEF_CSV = "zz-data/chapter04/04_dimensionless_invariants.csv"

def add_common_plot_args(p: argparse.ArgumentParser) -> None:
    p.add_argument("--outdir", default=".ci-out/smoke_v1")
    p.add_argument("--format", default="png", choices=["png","pdf","svg"])
    p.add_argument("--dpi", type=int, default=120)
    p.add_argument("--style", default="classic")
    p.add_argument("--figsize", default="9,5")
    p.add_argument("--transparent", action="store_true")
    p.add_argument("--save-pdf", dest="save_pdf", action="store_true")
    p.add_argument("--save-svg", dest="save_svg", action="store_true")
    p.add_argument("--show", action="store_true")

def parse_figsize(s: str) -> tuple[float,float]:
    try: w,h = s.split(","); return float(w), float(h)
    except Exception: return (9.0, 5.0)

def ensure_outpath(args) -> str:
    os.makedirs(args.outdir, exist_ok=True)
    return os.path.join(args.outdir, "chapter04_fig02_invariants_hist."+args.format)

def save_figure(fig, outpath: str, fmt: str, dpi: int, transparent: bool, save_pdf: bool, save_svg: bool):
    fig.savefig(outpath, dpi=dpi, transparent=transparent)
    if save_pdf: fig.savefig(outpath.rsplit(".",1)[0]+".pdf")
    if save_svg: fig.savefig(outpath.rsplit(".",1)[0]+".svg")

def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="Histogramme invariants (standalone)")
    add_common_plot_args(p)
    p.add_argument("--data", default=DEF_CSV)
    p.add_argument("--bins", type=int, default=40)
    return p

def main(argv=None) -> int:
    args = build_parser().parse_args(argv)
    try: plt.style.use(args.style)
    except Exception: pass
    out = ensure_outpath(args); figsize = parse_figsize(args.figsize)
    fig, ax = plt.subplots(figsize=figsize)

    if not os.path.isfile(args.data):
        ax.text(0.5,0.55,"Fichier de données manquant",ha="center",va="center",transform=ax.transAxes)
        ax.text(0.5,0.45,args.data,ha="center",va="center",transform=ax.transAxes)
        ax.set_axis_off()
        save_figure(fig, out, args.format, args.dpi, args.transparent, args.save_pdf, args.save_svg)
        return 0

    df = pd.read_csv(args.data)
    if not {"I2","I3"}.issubset(df.columns):
        ax.text(0.5,0.5,"Colonnes I2/I3 absentes",ha="center",va="center",transform=ax.transAxes)
        ax.set_axis_off()
        save_figure(fig, out, args.format, args.dpi, args.transparent, args.save_pdf, args.save_svg)
        return 2

    logI2 = np.log10(df["I2"].replace(0, np.nan).dropna())
    logI3 = np.log10(np.abs(df["I3"].replace(0, np.nan).dropna()))
    rng = (min(logI2.min(), logI3.min()), max(logI2.max(), logI3.max()))
    bins = np.linspace(rng[0], rng[1], args.bins)

    ax.hist(logI2, bins=bins, density=True, alpha=0.7, label=r"$\log_{10} I_2$")
    ax.hist(logI3, bins=bins, density=True, alpha=0.7, label=r"$\log_{10} |I_3|$")
    ax.set_xlabel(r"$\log_{10}(\text{invariant})$"); ax.set_ylabel("Densité normalisée")
    ax.set_title("Fig. 02 – Histogramme des invariants adimensionnels"); ax.legend(fontsize="small")
    ax.grid(True, which="both", linestyle=":", linewidth=0.5)

    save_figure(fig, out, args.format, args.dpi, args.transparent, args.save_pdf, args.save_svg)
    if args.show: plt.show()
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
