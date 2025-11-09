#!/usr/bin/env python3
from __future__ import annotations
import argparse, sys, os, pathlib
import matplotlib.pyplot as plt
import pandas as pd
from _common.cli import add_common_plot_args, finalize_plot_from_args, init_logging
try:
    from _common import cli as C
except Exception:
    sys.path.append(str(pathlib.Path(__file__).resolve().parents[1]))
    from _common import cli as C

DATA_FILE = "zz-data/chapter03/03_fR_stability_domain.csv"

def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="Chap3 Domaine de stabilité f(R) (homogène)")
    C.add_common_plot_args(p)
    return p

def main(argv=None) -> int:
    args = build_parser().parse_args(argv)
    args._stem = "chapter03_fig01_fr_stability"
    log = C.setup_logging(args.log_level)
    C.setup_mpl(args.style)
    out = C.ensure_outpath(args)
    figsize = C.parse_figsize(args.figsize)

    fig, ax = plt.subplots(figsize=figsize, dpi=args.dpi)
    if not os.path.isfile(DATA_FILE):
        log.error("Fichier manquant : %s", DATA_FILE)
        ax.text(0.5,0.55,"Fichier de données manquant",ha="center",va="center",transform=ax.transAxes)
        ax.text(0.5,0.45,DATA_FILE,ha="center",va="center",transform=ax.transAxes)
        ax.set_axis_off()
        C.save_figure(fig, out, args.format, args.dpi, args.transparent, args.save_pdf, args.save_svg)
        return 0

    df = pd.read_csv(DATA_FILE)
    required = {"beta", "gamma_min", "gamma_max"}
    missing = required - set(df.columns)
    if missing:
        log.error("Colonnes manquantes : %s", missing)
        ax.text(0.5,0.5,"Colonnes manquantes",ha="center",va="center",transform=ax.transAxes)
        ax.set_axis_off()
        C.save_figure(fig, out, args.format, args.dpi, args.transparent, args.save_pdf, args.save_svg)
        return 2

    ax.fill_between(df["beta"], df["gamma_min"], df["gamma_max"], alpha=0.5, linewidth=0)
    ax.set_xlabel(r"$\beta$"); ax.set_ylabel(r"$\gamma$")
    ax.set_title("Chapitre 3 — Domaine de stabilité de f(R)")
    ax.grid(True, linestyle=":", linewidth=0.5)
    C.save_figure(fig, out, args.format, args.dpi, args.transparent, args.save_pdf, args.save_svg)
    if args.show: plt.show()
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
