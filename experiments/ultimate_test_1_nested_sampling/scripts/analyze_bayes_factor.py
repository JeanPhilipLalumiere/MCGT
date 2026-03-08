#!/usr/bin/env python3
"""Compute Delta lnZ and Bayes factor from PsiTMG and LCDM nested outputs."""

from __future__ import annotations

import argparse
import math
import pickle
from pathlib import Path


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Analyze Bayes factor from nested-sampling results.")
    parser.add_argument(
        "--psitmg-pkl",
        type=Path,
        default=Path("experiments/ultimate_test_1_nested_sampling/outputs/psitmg_nested_res.pkl"),
    )
    parser.add_argument(
        "--lcdm-pkl",
        type=Path,
        default=Path("experiments/ultimate_test_1_nested_sampling/outputs/lcdm_nested_res.pkl"),
    )
    parser.add_argument(
        "--out-report",
        type=Path,
        default=Path("experiments/ultimate_test_1_nested_sampling/outputs/nested_bayes_factor_report.txt"),
    )
    return parser


def _load_lnz(path: Path) -> tuple[float, float]:
    with path.open("rb") as f:
        results = pickle.load(f)
    lnz = float(results.logz[-1])
    lnz_err = float(results.logzerr[-1])
    return lnz, lnz_err


def _jeffreys_label(delta_lnz: float) -> str:
    ad = abs(delta_lnz)
    if ad < 1.0:
        return "inconclusive"
    if ad < 2.5:
        return "weak"
    if ad < 5.0:
        return "moderate"
    return "strong"


def main() -> int:
    args = build_parser().parse_args()
    args.out_report.parent.mkdir(parents=True, exist_ok=True)

    if not args.psitmg_pkl.exists():
        raise FileNotFoundError(f"Missing PsiTMG results: {args.psitmg_pkl}")
    if not args.lcdm_pkl.exists():
        raise FileNotFoundError(f"Missing LCDM results: {args.lcdm_pkl}")

    lnz_psitmg, err_psitmg = _load_lnz(args.psitmg_pkl)
    lnz_lcdm, err_lcdm = _load_lnz(args.lcdm_pkl)

    delta_lnz = lnz_psitmg - lnz_lcdm
    delta_err = math.sqrt(err_psitmg * err_psitmg + err_lcdm * err_lcdm)
    if delta_lnz > 700:
        bayes_factor = math.inf
    elif delta_lnz < -700:
        bayes_factor = 0.0
    else:
        bayes_factor = math.exp(delta_lnz)
    favored = "PsiTMG" if delta_lnz > 0 else "LCDM"
    strength = _jeffreys_label(delta_lnz)

    lines = [
        "Nested-Sampling Bayes Factor Report",
        f"lnZ(PsiTMG) = {lnz_psitmg:.6f} +/- {err_psitmg:.6f}",
        f"lnZ(LCDM)   = {lnz_lcdm:.6f} +/- {err_lcdm:.6f}",
        f"Delta lnZ   = {delta_lnz:.6f} +/- {delta_err:.6f}",
        f"Bayes factor K = exp(Delta lnZ) = {bayes_factor:.6e}",
        f"Favored model: {favored}",
        f"Evidence strength (Jeffreys): {strength}",
        "",
        f"PsiTMG source: {args.psitmg_pkl}",
        f"LCDM source: {args.lcdm_pkl}",
    ]
    args.out_report.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Saved report: {args.out_report}")
    print(f"Delta lnZ = {delta_lnz:.6f} +/- {delta_err:.6f}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
