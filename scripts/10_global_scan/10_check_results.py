#!/usr/bin/env python3
from __future__ import annotations

import argparse
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CSV = ROOT / "assets/zz-data/10_global_scan/10_mc_results.csv"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Quick inspection of Chapter 10 Monte Carlo results.")
    parser.add_argument("--csv", type=Path, default=DEFAULT_CSV, help="Input CSV to inspect.")
    return parser


def main() -> None:
    args = build_parser().parse_args()
    df = pd.read_csv(args.csv)
    print(f"Imported simulations: {len(df)}")
    print(f"Best p95 found: {df['p95_20_300'].min():.8f} rad")
    exclusion_zone = df[df["p95_20_300"] < 0.1]
    print(f"GR-indistinguishable points (p95 < 0.1 rad): {len(exclusion_zone)}")


if __name__ == "__main__":
    main()
