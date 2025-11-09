from __future__ import annotations
import argparse, logging, os
from typing import Tuple
import matplotlib.pyplot as plt
from _common.cli import add_common_plot_args, finalize_plot_from_args, init_logging

def add_common_plot_args(p: argparse.ArgumentParser) -> None:
    p.add_argument("--outdir", default=".ci-out/smoke_v1")
    p.add_argument("--format", default="png", choices=["png","pdf","svg"])
    p.add_argument("--dpi", type=int, default=120)
    p.add_argument("--style", default="classic")
    p.add_argument("--figsize", default="8,5")
    p.add_argument("--transparent", action="store_true")
    p.add_argument("--save-pdf", dest="save_pdf", action="store_true")
    p.add_argument("--save-svg", dest="save_svg", action="store_true")
    p.add_argument("--show", action="store_true")
    p.add_argument("--log-level", default="INFO")

def setup_logging(level: str = "INFO") -> logging.Logger:
    lvl = getattr(logging, str(level).upper(), logging.INFO)
    logging.basicConfig(level=lvl, format="[%(levelname)s] %(message)s")
    return logging.getLogger("mcgt")

def setup_mpl(style: str = "classic") -> None:
    try:
        plt.style.use(style)
    except Exception:
        pass

def parse_figsize(s: str) -> Tuple[float,float]:
    try:
        w, h = s.split(","); return float(w), float(h)
    except Exception:
        return (8.0, 5.0)

def ensure_outpath(args) -> str:
    os.makedirs(args.outdir, exist_ok=True)
    stem = getattr(args, "_stem", "figure")
    return os.path.join(args.outdir, f"{stem}.{args.format}")

def save_figure(fig, outpath: str, fmt: str, dpi: int, transparent: bool, save_pdf: bool, save_svg: bool):
    fig.savefig(outpath, dpi=dpi, transparent=transparent)
    base = outpath.rsplit(".",1)[0]
    if save_pdf: fig.savefig(base + ".pdf")
    if save_svg: fig.savefig(base + ".svg")
