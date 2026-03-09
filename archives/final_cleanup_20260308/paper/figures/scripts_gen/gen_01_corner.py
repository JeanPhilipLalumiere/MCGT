#!/usr/bin/env python3
"""Figure generator for ΨTMG Manuscript v4.0.0 - arXiv Preprint Ready"""

from __future__ import annotations

import argparse
import gzip
import json
from pathlib import Path

import corner
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

REPO_ROOT = Path(__file__).resolve().parents[3]
DEFAULT_CHAIN = REPO_ROOT / "assets" / "zz-data" / "10_global_scan" / "10_mcmc_affine_chain.csv.gz"
DEFAULT_PHASE4 = REPO_ROOT / "phase4_global_verdict_report.json"
DEFAULT_OUT = Path(__file__).resolve().parents[1] / "01_fig_corner.pdf"

PARAMS = ["omega_m", "H0", "w0", "wa", "S8"]
LABELS = {
    "omega_m": r"$\Omega_m$",
    "H0": r"$H_0$",
    "w0": r"$w_0$",
    "wa": r"$w_a$",
    "S8": r"$S_8$",
}


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="Generate final corner plot PDF for paper/figures.")
    p.add_argument("--chain", type=Path, default=DEFAULT_CHAIN)
    p.add_argument("--phase4", type=Path, default=DEFAULT_PHASE4)
    p.add_argument("--out", type=Path, default=DEFAULT_OUT)
    return p


def load_chain(path: Path) -> np.ndarray:
    opener = gzip.open if path.suffix == ".gz" else open
    with opener(path, "rt", encoding="utf-8") as f:
        df = pd.read_csv(f)
    missing = [c for c in PARAMS if c not in df.columns]
    if missing:
        raise KeyError(f"Missing columns in chain: {missing}")
    return df[PARAMS].to_numpy(dtype=float)


def main() -> int:
    args = build_parser().parse_args()

    samples = load_chain(args.chain)
    labels = [LABELS[c] for c in PARAMS]

    if args.phase4.exists():
        _ = json.loads(args.phase4.read_text(encoding="utf-8"))

    fig = corner.corner(
        samples,
        labels=labels,
        show_titles=True,
        title_fmt=".3f",
        plot_datapoints=False,
        fill_contours=False,
        levels=(1 - np.exp(-0.5), 1 - np.exp(-2)),
        color="#003366",
        smooth=1.0,
        max_n_ticks=4,
    )
    fig.suptitle(r"$\Psi$TMG posterior constraints", y=1.02)

    args.out.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(args.out, bbox_inches="tight")
    plt.close(fig)
    print(f"[ok] wrote {args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
