#!/usr/bin/env python3
from __future__ import annotations
import argparse, os
from pathlib import Path
import pandas as pd
import matplotlib.pyplot as plt

DATA_FILE = Path("zz-data/chapter03/03_fR_stability_domain.csv")

def add_common_plot_args(p: argparse.ArgumentParser) -> None:
    p.add_argument("--outdir", default=".ci-out/smoke_v1")
    p.add_argument("--format", default="png", choices=["png","pdf","svg"])
    p.add_argument("--dpi", type=int, default=120)
    p.add_argument("--style", default="classic")
    p.add_argument("--figsize", default="6,4")
    p.add_argument("--transparent", action="store_true")
    p.add_argument("--save-pdf", dest="save_pdf", action="store_true")
    p.add_argument("--save-svg", dest="save_svg", action="store_true")
    p.add_argument("--show", action="store_true")

def parse_figsize(s: str) -> tuple[float,float]:
    try: w,h = s.split(","); return float(w), float(h)
    except Exception: return (6.0, 4.0)

def ensure_outpath(args) -> str:
    os.makedirs(args.outdir, exist_ok=True)
    return os.path.join(args.outdir, "chapter03_fig01_fr_stability."+args.format)

def save_figure(fig, outpath: str, fmt: str, dpi: int, transparent: bool, save_pdf: bool, save_svg: bool):
    fig.savefig(outpath, dpi=dpi, transparent=transparent)
    if save_pdf: fig.savefig(outpath.rsplit(".",1)[0]+".pdf")
    if save_svg: fig.savefig(outpath.rsplit(".",1)[0]+".svg")

def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="Domaine de stabilité f(R) — standalone")
    add_common_plot_args(p)
    p.add_argument("--data", default=str(DATA_FILE))
    return p

def main(argv=None) -> int:
    args = build_parser().parse_args(argv)
    try: plt.style.use(args.style)
    except Exception: pass
    out = ensure_outpath(args); figsize = parse_figsize(args.figsize)

    fig, ax = plt.subplots(dpi=args.dpi, figsize=figsize)

    if not Path(args.data).exists():
        ax.text(0.5,0.55,"Fichier manquant",ha="center",va="center",transform=ax.transAxes)
        ax.text(0.5,0.45,args.data,ha="center",va="center",transform=ax.transAxes)
        ax.set_axis_off()
        save_figure(fig, out, args.format, args.dpi, args.transparent, args.save_pdf, args.save_svg)
        return 0

    df = pd.read_csv(args.data)
    req = {"beta","gamma_min","gamma_max"}
    if not req.issubset(df.columns):
        ax.text(0.5,0.5,"Colonnes beta,gamma_min,gamma_max requises",ha="center",va="center",transform=ax.transAxes)
        ax.set_axis_off()
        save_figure(fig, out, args.format, args.dpi, args.transparent, args.save_pdf, args.save_svg)
        return 2

    ax.fill_between(df["beta"], df["gamma_min"], df["gamma_max"], alpha=0.5)
    ax.set_xlabel(r"$\beta = R/R_0$"); ax.set_ylabel(r"$\gamma$")
    ax.set_title("Chapitre 3 — Domaine de stabilité f(R)")
    ax.grid(True, linestyle=":", linewidth=0.5)

    save_figure(fig, out, args.format, args.dpi, args.transparent, args.save_pdf, args.save_svg)
    if args.show: plt.show()
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
