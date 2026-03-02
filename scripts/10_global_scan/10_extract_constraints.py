#!/usr/bin/env python3
"""Extract Chapter 10 exclusion constraints from the 100k global scan."""

from __future__ import annotations

import argparse
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

DEFAULT_INPUT = Path.home() / "Downloads" / "MCGT_Final_Results" / "10_mc_results.csv"
DEFAULT_FIGURE = Path("assets/zz-figures/10_global_scan/10_exclusion_curve.png")
DEFAULT_TABLE = Path("assets/zz-data/10_global_scan/10_exclusion_constraints.md")
DEFAULT_CSV = Path("assets/zz-data/10_global_scan/10_exclusion_constraints.csv")

ALPHA_MIN = -0.9
ALPHA_MAX = 0.9
N_BINS = 10
SURVIVAL_THRESHOLD_RAD = 0.1


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Extract |q0*| exclusion limits as a function of alpha."
    )
    parser.add_argument("--input", type=Path, default=DEFAULT_INPUT, help="Input CSV file.")
    parser.add_argument("--figure", type=Path, default=DEFAULT_FIGURE, help="Output PNG figure.")
    parser.add_argument("--table", type=Path, default=DEFAULT_TABLE, help="Output Markdown table.")
    parser.add_argument("--csv", type=Path, default=DEFAULT_CSV, help="Output CSV summary.")
    return parser


def format_limit(value: float) -> str:
    if np.isnan(value):
        return "N/A"
    return f"{value:.6g}"


def build_markdown_table(summary: pd.DataFrame, global_limit: float) -> str:
    lines = [
        "# Chapter 10 Exclusion Constraints",
        "",
        f"Threshold used: `p95_20_300 <= {SURVIVAL_THRESHOLD_RAD:.3f} rad`.",
        f"Global conservative constraint: `|q0*| <= {global_limit:.6g}`.",
        "",
        "| Alpha bin | Mean alpha | Constraint limit `|q0*|_max` | Survival fraction |",
        "|---|---:|---:|---:|",
    ]
    for row in summary.itertuples(index=False):
        lines.append(
            "| "
            f"[{row.alpha_lo:.2f}, {row.alpha_hi:.2f})"
            f" | {row.alpha_mean:.4f}"
            f" | {format_limit(row.q0_abs_max_survivor)}"
            f" | {row.survival_fraction_pct:.2f}% |"
        )
    lines.append("")
    return "\n".join(lines) + "\n"


def main() -> None:
    args = build_parser().parse_args()

    df = pd.read_csv(args.input)
    required = {"alpha", "q0star", "p95_20_300", "status"}
    missing = required.difference(df.columns)
    if missing:
        raise SystemExit(f"Missing required columns: {sorted(missing)}")

    df = df.loc[df["status"].fillna("").eq("ok")].copy()
    df = df.loc[df["alpha"].between(ALPHA_MIN, ALPHA_MAX, inclusive="both")].copy()
    df["q0_abs"] = df["q0star"].abs()
    df["survives"] = df["p95_20_300"] <= SURVIVAL_THRESHOLD_RAD

    edges = np.linspace(ALPHA_MIN, ALPHA_MAX, N_BINS + 1)
    df["alpha_bin"] = pd.cut(
        df["alpha"],
        bins=edges,
        include_lowest=True,
        right=False,
    )
    # Include alpha == ALPHA_MAX in the final bin.
    df.loc[df["alpha"] == ALPHA_MAX, "alpha_bin"] = df["alpha_bin"].cat.categories[-1]

    records: list[dict[str, float | int]] = []
    for idx, interval in enumerate(df["alpha_bin"].cat.categories):
        chunk = df.loc[df["alpha_bin"] == interval].copy()
        survivors = chunk.loc[chunk["survives"]]
        total = int(len(chunk))
        n_survivors = int(len(survivors))
        survival_fraction_pct = 100.0 * n_survivors / total if total else 0.0
        q0_abs_max_survivor = float(survivors["q0_abs"].max()) if n_survivors else np.nan
        alpha_mean = float(chunk["alpha"].mean()) if total else float((interval.left + interval.right) / 2.0)
        records.append(
            {
                "bin_index": idx,
                "alpha_lo": float(interval.left),
                "alpha_hi": float(interval.right),
                "alpha_mean": alpha_mean,
                "n_total": total,
                "n_survivors": n_survivors,
                "survival_fraction_pct": survival_fraction_pct,
                "q0_abs_max_survivor": q0_abs_max_survivor,
            }
        )

    summary = pd.DataFrame.from_records(records)
    finite_limits = summary["q0_abs_max_survivor"].replace([np.inf, -np.inf], np.nan).dropna()
    if finite_limits.empty:
        raise SystemExit("No surviving point found below the p95 threshold.")
    global_limit = float(finite_limits.min())

    args.csv.parent.mkdir(parents=True, exist_ok=True)
    args.table.parent.mkdir(parents=True, exist_ok=True)
    args.figure.parent.mkdir(parents=True, exist_ok=True)
    summary.to_csv(args.csv, index=False)
    args.table.write_text(build_markdown_table(summary, global_limit), encoding="utf-8")

    plt.rcParams.update(
        {
            "figure.dpi": 120,
            "font.family": "DejaVu Serif",
            "axes.labelsize": 12,
            "axes.titlesize": 13,
        }
    )
    fig, ax = plt.subplots(figsize=(8.4, 5.2))
    ax.plot(
        summary["alpha_mean"],
        summary["q0_abs_max_survivor"],
        color="#0B5FA5",
        marker="o",
        linewidth=2.0,
        label=r"Constraint limit $|q_0^*|_{\max}$",
    )
    ax.axhline(global_limit, color="#C0392B", linestyle="--", linewidth=1.6, label=f"Global limit = {global_limit:.6g}")
    ax.set_xlabel(r"Mean spectral index $\alpha$")
    ax.set_ylabel(r"Maximum surviving $|q_0^*|$")
    ax.set_title(r"Chapter 10 exclusion curve from the $p_{95} \leq 0.1$ survival threshold")
    ax.grid(True, linestyle=":", alpha=0.4)
    ax.legend(frameon=False)
    fig.tight_layout()
    fig.savefig(args.figure, dpi=300, bbox_inches="tight")
    plt.close(fig)

    print(f"[ok] Input rows kept: {len(df)}")
    print(f"[ok] Markdown table: {args.table}")
    print(f"[ok] CSV summary: {args.csv}")
    print(f"[ok] Figure: {args.figure}")
    print(f"[summary] Global conservative |q0*| limit: {global_limit:.6g}")


if __name__ == "__main__":
    main()
