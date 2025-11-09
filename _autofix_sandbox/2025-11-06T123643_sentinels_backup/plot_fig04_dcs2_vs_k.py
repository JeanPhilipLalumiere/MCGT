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

DEF_CSV  = "zz-data/chapter07/07_dcs2_dk.csv"
DEF_META = "zz-data/chapter07/07_meta.json"

def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="Chap7 Δc_s^2(k) vs k (homogène)")
    C.add_common_plot_args(p)
    p.add_argument("--data", default=DEF_CSV)
    p.add_argument("--meta", default=DEF_META)
    p.add_argument("--kmin", type=float, default=None)
    p.add_argument("--kmax", type=float, default=None)
    p.add_argument("--k-split", type=float, default=2e-2)
    return p

def main(argv=None) -> int:
    args = build_parser().parse_args(argv)
    args._stem = "chapter07_fig04_dcs2_vs_k"
    log = C.setup_logging(args.log_level)
    C.setup_mpl(args.style)
    out = C.ensure_outpath(args)
    figsize = C.parse_figsize(args.figsize)
    fig, ax = plt.subplots(figsize=figsize, constrained_layout=True)

    if not os.path.isfile(args.data):
        log.warning("Données absentes → %s", args.data)
        ax.text(0.5,0.55,"Fichier de données manquant",ha="center",va="center",transform=ax.transAxes)
        ax.text(0.5,0.45,args.data,ha="center",va="center",transform=ax.transAxes)
        ax.set_axis_off()
        C.save_figure(fig, out, args.format, args.dpi, args.transparent, args.save_pdf, args.save_svg)
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
    C.save_figure(fig, out, args.format, args.dpi, args.transparent, args.save_pdf, args.save_svg)
    if args.show: plt.show()
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
