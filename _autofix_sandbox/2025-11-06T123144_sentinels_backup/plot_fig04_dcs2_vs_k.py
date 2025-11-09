#!/usr/bin/env python3
from __future__ import annotations
import argparse, os, sys
import numpy as np, pandas as pd
import matplotlib.pyplot as plt

DEF_CSV  = "zz-data/chapter07/07_dcs2_dk.csv"
DEF_META = "zz-data/chapter07/07_meta.json"

def add_common_plot_args(p: argparse.ArgumentParser) -> None:
    p.add_argument("--outdir", default=".ci-out/smoke_v1", help="Dossier de sortie")
    p.add_argument("--format", default="png", choices=["png","pdf","svg"])
    p.add_argument("--dpi", type=int, default=120)
    p.add_argument("--style", default="classic")
    p.add_argument("--figsize", default="8,5")
    p.add_argument("--transparent", action="store_true")
    p.add_argument("--save-pdf", dest="save_pdf", action="store_true")
    p.add_argument("--save-svg", dest="save_svg", action="store_true")
    p.add_argument("--show", action="store_true")
    p.add_argument("--log-level", default="INFO")

def parse_figsize(s: str) -> tuple[float,float]:
    try:
        w,h = s.split(",")
        return float(w), float(h)
    except Exception:
        return (8.0, 5.0)

def ensure_outpath(args) -> str:
    os.makedirs(args.outdir, exist_ok=True)
    return os.path.join(args.outdir, "chapter07_fig04_dcs2_vs_k."+args.format)

def save_figure(fig, outpath: str, fmt: str, dpi: int, transparent: bool, save_pdf: bool, save_svg: bool):
    fig.savefig(outpath, dpi=dpi, transparent=transparent)
    if save_pdf:
        fig.savefig(outpath.rsplit(".",1)[0]+".pdf")
    if save_svg:
        fig.savefig(outpath.rsplit(".",1)[0]+".svg")

def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="Δc_s^2(k) vs k — standalone (autofix)")
    add_common_plot_args(p)
    p.add_argument("--data", default=DEF_CSV, help=f"CSV d'entrée (défaut: {DEF_CSV})")
    p.add_argument("--meta", default=DEF_META, help=f"Méta JSON optionnel (défaut: {DEF_META})")
    p.add_argument("--kmin", type=float, default=None)
    p.add_argument("--kmax", type=float, default=None)
    p.add_argument("--k-split", type=float, default=2e-2)
    return p

def main(argv=None) -> int:
    args = build_parser().parse_args(argv)
    try:
        plt.style.use(args.style)
    except Exception:
        pass
    out = ensure_outpath(args)
    figsize = parse_figsize(args.figsize)
    fig, ax = plt.subplots(figsize=figsize, constrained_layout=True)

    if not os.path.isfile(args.data):
        ax.text(0.5,0.55,"Fichier de données manquant",ha="center",va="center",transform=ax.transAxes)
        ax.text(0.5,0.45,args.data,ha="center",va="center",transform=ax.transAxes)
        ax.set_axis_off()
        save_figure(fig, out, args.format, args.dpi, args.transparent, args.save_pdf, args.save_svg)
        return 0

    df = pd.read_csv(args.data, comment="#")
    cols = {c.lower(): c for c in df.columns}
    kcol = cols.get("k") or cols.get("k_hmpc") or list(df.columns)[0]
    vcol = cols.get("dcs2") or cols.get("delta_cs2") or list(df.columns)[1]

    s = df[[kcol, vcol]].dropna()
    if args.kmin is not None: s = s[s[kcol] >= args.kmin]
    if args.kmax is not None: s = s[s[kcol] <= args.kmax]
    s = s.sort_values(kcol)

    ax.plot(s[kcol].values, s[vcol].values, linestyle="-", marker="", label=vcol)
    if args.k_split and args.k_split>0: ax.axvline(args.k_split, linestyle="--", linewidth=0.9)
    ax.set_xscale("log"); ax.set_xlabel("k [h/Mpc]"); ax.set_ylabel(r"$\Delta c_s^2(k)$")
    ax.grid(True, linestyle=":", linewidth=0.5); ax.legend(fontsize=9); ax.set_title("Chapitre 7 — Δc_s^2(k)")

    save_figure(fig, out, args.format, args.dpi, args.transparent, args.save_pdf, args.save_svg)
    if args.show: plt.show()
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
