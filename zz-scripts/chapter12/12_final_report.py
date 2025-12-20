#!/usr/bin/env python3
"""Chapter 12: consolidate final audit metrics into a summary table."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate final audit report table.")
    parser.add_argument(
        "--mcmc-summary",
        default="zz-data/chapter09/09_mcmc_tri_probe_summary.json",
        help="Tri-probe MCMC summary JSON.",
    )
    parser.add_argument(
        "--lensing-summary",
        default="zz-data/chapter11/11_summary.json",
        help="Chapter 11 lensing summary JSON.",
    )
    parser.add_argument(
        "--cmb-summary",
        default="zz-data/chapter12/12_cmb_theta_summary.json",
        help="Chapter 12 theta/R summary JSON.",
    )
    parser.add_argument(
        "--out",
        default="zz-docs/FINAL_REPORT.md",
        help="Output markdown report.",
    )
    return parser.parse_args()


def read_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def format_float(value: float | None, digits: int = 4) -> str:
    if value is None:
        return "n/a"
    return f"{value:.{digits}f}"


def main() -> int:
    args = parse_args()
    mcmc = read_json(Path(args.mcmc_summary))
    lens = read_json(Path(args.lensing_summary))
    cmb = read_json(Path(args.cmb_summary))

    best = mcmc.get("best_fit", {})
    best_no_cmb = mcmc.get("best_fit_no_cmb", {})

    table = [
        "# Final Audit Report",
        "",
        "| Metric | Value |",
        "| --- | --- |",
        f"| Steps (MCMC) | {mcmc.get('steps', 'n/a')} |",
        f"| Acceptance rate | {format_float(mcmc.get('acceptance_rate'), 3)} |",
        f"| Best-fit w0 | {format_float(best.get('w0'))} |",
        f"| Best-fit wa | {format_float(best.get('wa'))} |",
        f"| Best-fit Omega_m | {format_float(best.get('omega_m'))} |",
        f"| chi2_total (SN+BAO+CMB) | {format_float(best.get('chi2_total'), 3)} |",
        f"| chi2_SN | {format_float(best.get('chi2_sn'), 3)} |",
        f"| chi2_BAO | {format_float(best.get('chi2_bao'), 3)} |",
        f"| chi2_CMB | {format_float(best.get('chi2_cmb'), 3)} |",
        f"| chi2_total (SN+BAO only) | {format_float(best_no_cmb.get('chi2_total_no_cmb'), 3)} |",
        f"| sigma8 (CPL) | {format_float(lens.get('sigma8_cpl'))} |",
        f"| sigma8 (LCDM) | {format_float(lens.get('sigma8_lcdm'))} |",
        f"| 100*theta* (CPL) | {format_float(cmb.get('theta100_cpl'), 6)} |",
        f"| 100*theta* (LCDM) | {format_float(cmb.get('theta100_lcdm'), 6)} |",
        f"| R_shift (CPL) | {format_float(cmb.get('R_shift_cpl'), 6)} |",
        f"| R_shift (LCDM) | {format_float(cmb.get('R_shift_lcdm'), 6)} |",
    ]

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text("\n".join(table) + "\n", encoding="utf-8")
    print(out_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
