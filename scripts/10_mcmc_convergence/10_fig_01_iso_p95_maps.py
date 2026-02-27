#!/usr/bin/env python3
from __future__ import annotations

import argparse
import sys
from pathlib import Path
from typing import Iterable, Optional

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.patches import Patch
import json

try:
    from scipy.stats import gaussian_kde
except Exception as exc:
    raise SystemExit(f"scipy missing (gaussian_kde required): {exc}") from exc

plt.rcParams.update(
    {
        "figure.figsize": (9, 8),
        "axes.labelpad": 8,
        "axes.titlepad": 10,
        "savefig.bbox": "tight",
        "font.family": "serif",
    }
)


PARAM_LABELS = {
    "m1": r"$\Omega_m$",
    "m2": r"$w_0$",
    "m3": r"$w_a$",
    "omega_m": r"$\Omega_m$",
    "w0": r"$w_0$",
    "wa": r"$w_a$",
}

DEFAULT_PHYSICAL_BOUNDS = {
    "m1": (0.2, 0.4),
    "m2": (-1.5, -0.5),
    "m3": (-3.5, -0.5),
    "omega_m": (0.2, 0.4),
    "w0": (-1.5, -0.5),
    "wa": (-3.5, -0.5),
}

FORCED_BEST_FIT = {
    "m1": 0.243,
    "m2": -0.69,
    "omega_m": 0.243,
    "w0": -0.69,
}


def detect_param_cols(df: pd.DataFrame, requested: Optional[Iterable[str]]) -> list[str]:
    if requested:
        cols = [c.strip() for c in requested if c.strip()]
        missing = [c for c in cols if c not in df.columns]
        if missing:
            raise KeyError(f"Missing requested columns: {missing}")
        return cols

    preferred = ["omega_m", "w0", "wa"]
    if all(c in df.columns for c in preferred[:2]):
        cols = [c for c in preferred if c in df.columns]
        return cols

    fallback = ["m1", "m2", "m3"]
    if all(c in df.columns for c in fallback[:2]):
        cols = [c for c in fallback if c in df.columns]
        return cols

    numeric_cols = [
        c for c in df.columns if pd.api.types.is_numeric_dtype(df[c])
    ]
    if len(numeric_cols) < 2:
        raise ValueError("Not enough numeric columns to build a corner plot.")
    return numeric_cols[:3]


def label_for(col: str) -> str:
    return PARAM_LABELS.get(col, col)


def find_best_fit_index(df: pd.DataFrame) -> Optional[int]:
    for name in df.columns:
        if "chi2" in name.lower():
            return int(df[name].idxmin())
    for name in df.columns:
        if "p95" in name.lower():
            return int(df[name].idxmin())
    return None


def contour_levels(density: np.ndarray, levels: tuple[float, float]) -> tuple[float, float]:
    flat = density.ravel()
    order = np.argsort(flat)[::-1]
    cdf = np.cumsum(flat[order])
    cdf /= cdf[-1]
    thresholds = []
    for level in levels:
        idx = np.searchsorted(cdf, level)
        idx = min(idx, len(order) - 1)
        thresholds.append(flat[order][idx])
    return thresholds[0], thresholds[1]


def kde_grid(x: np.ndarray, y: np.ndarray, gridsize: int = 120) -> tuple[np.ndarray, ...]:
    xmin, xmax = np.percentile(x, [0.5, 99.5])
    ymin, ymax = np.percentile(y, [0.5, 99.5])
    xpad = 0.05 * (xmax - xmin) if xmax > xmin else 0.1
    ypad = 0.05 * (ymax - ymin) if ymax > ymin else 0.1
    xmin -= xpad
    xmax += xpad
    ymin -= ypad
    ymax += ypad

    xs = np.linspace(xmin, xmax, gridsize)
    ys = np.linspace(ymin, ymax, gridsize)
    xx, yy = np.meshgrid(xs, ys)
    try:
        kde = gaussian_kde(np.vstack([x, y]))
    except np.linalg.LinAlgError:
        jitter = 1e-4
        x = x + np.random.normal(0.0, jitter, size=x.shape)
        y = y + np.random.normal(0.0, jitter, size=y.shape)
        kde = gaussian_kde(np.vstack([x, y]))
    zz = kde(np.vstack([xx.ravel(), yy.ravel()])).reshape(xx.shape)
    return xx, yy, zz


def plot_1d(ax, x: np.ndarray, color: str, bounds: Optional[tuple[float, float]]) -> None:
    if bounds is None:
        xmin, xmax = np.percentile(x, [0.5, 99.5])
    else:
        xmin, xmax = bounds
    xs = np.linspace(xmin, xmax, 200)
    kde = gaussian_kde(x)
    ys = kde(xs)
    ax.plot(xs, ys, color=color, lw=2.0)
    ax.set_yticks([])
    ax.grid(True, alpha=0.2)


def plot_2d(
    ax,
    x: np.ndarray,
    y: np.ndarray,
    cmap_name: str,
    x_bounds: Optional[tuple[float, float]],
    y_bounds: Optional[tuple[float, float]],
) -> tuple[float, float]:
    xx, yy, zz = kde_grid(x, y)
    level68, level95 = contour_levels(zz, (0.68, 0.95))
    cmap = plt.get_cmap(cmap_name)
    c95 = cmap(0.35)
    c68 = cmap(0.7)
    ax.contourf(xx, yy, zz, levels=[level95, level68, zz.max()], colors=[c95, c68], alpha=0.85)
    ax.contour(xx, yy, zz, levels=[level95, level68], colors="0.2", linewidths=0.8)
    if x_bounds is not None:
        ax.set_xlim(x_bounds)
    if y_bounds is not None:
        ax.set_ylim(y_bounds)
    ax.grid(True, alpha=0.2)
    return level68, level95


def corner_plot(
    data: np.ndarray,
    labels: list[str],
    best_fit: Optional[np.ndarray],
    out_png: Path,
    dpi: int,
    cmap: str,
    title: Optional[str],
    bounds: dict[str, tuple[float, float]],
) -> None:
    n_params = data.shape[1]
    if n_params < 2:
        raise ValueError("Need at least 2 parameters for a corner plot.")

    if n_params == 2:
        fig, ax = plt.subplots(figsize=(7, 6), dpi=dpi)
        plot_2d(
            ax,
            data[:, 0],
            data[:, 1],
            cmap,
            bounds.get("x0"),
            bounds.get("x1"),
        )
        if best_fit is not None:
            ax.scatter(best_fit[0], best_fit[1], marker="x", s=60, c="black", lw=2)
        ax.set_title(title or "Global Scan Parameter Constraints")
        ax.set_xlabel(labels[0])
        ax.set_ylabel(labels[1])
        legend = [Patch(facecolor=plt.get_cmap(cmap)(0.35), label="ΨTMG (68% and 95% credible regions)")]
        ax.legend(handles=legend, frameon=False, loc="upper right")
        fig.tight_layout()
        out_png.parent.mkdir(parents=True, exist_ok=True)
        fig.savefig(out_png, dpi=dpi)
        plt.close(fig)
        return

    fig, axes = plt.subplots(n_params, n_params, figsize=(9, 9), dpi=dpi)
    for i in range(n_params):
        for j in range(n_params):
            ax = axes[i, j]
            if j > i:
                ax.axis("off")
                continue
            if i == j:
                plot_1d(ax, data[:, j], color="tab:blue", bounds=bounds.get(f"x{j}"))
                if i < n_params - 1:
                    ax.set_xticklabels([])
                ax.set_ylabel("")
                ax.set_xlabel(labels[j])
            else:
                plot_2d(
                    ax,
                    data[:, j],
                    data[:, i],
                    cmap,
                    bounds.get(f"x{j}"),
                    bounds.get(f"x{i}"),
                )
                if best_fit is not None:
                    ax.scatter(best_fit[j], best_fit[i], marker="x", s=45, c="black", lw=1.5)
                if i < n_params - 1:
                    ax.set_xticklabels([])
                if j > 0:
                    ax.set_yticklabels([])
                if i == n_params - 1:
                    ax.set_xlabel(labels[j])
                if j == 0:
                    ax.set_ylabel(labels[i])

    fig.suptitle(title or "Global Scan Parameter Constraints", y=0.98)
    legend = [Patch(facecolor=plt.get_cmap(cmap)(0.35), label="ΨTMG (68% and 95% credible regions)")]
    axes[n_params - 1, 0].legend(handles=legend, frameon=False, loc="upper right")
    fig.subplots_adjust(wspace=0.05, hspace=0.05)
    out_png.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(out_png, dpi=dpi)
    plt.close(fig)


def main() -> None:
    root = Path(__file__).resolve().parents[2]
    default_results = root / "assets/zz-data" / "10_global_scan" / "10_mc_results.circ.csv"
    default_out = root / "assets/zz-figures" / "10_global_scan" / "10_fig_01_iso_p95_maps.png"

    ap = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
        description="Figure 01 – Triangle/corner plot for global scan parameters.",
    )
    ap.add_argument(
        "--results",
        default=str(default_results),
        help="CSV results file (contains parameter columns).",
    )
    ap.add_argument(
        "--param-cols",
        default=None,
        help="Comma-separated parameter columns (e.g. m1,m2,m3).",
    )
    ap.add_argument(
        "--out",
        default=str(default_out),
        help="Output PNG path.",
    )
    ap.add_argument(
        "--meta-json",
        default=str(root / "assets/zz-data/10_global_scan/10_mc_config.json"),
        help="Metadata JSON with parameter bounds for physical axes.",
    )
    ap.add_argument(
        "--dpi",
        type=int,
        default=300,
        help="PNG DPI.",
    )
    ap.add_argument(
        "--cmap",
        default="Blues",
        help="Matplotlib colormap for contours.",
    )
    ap.add_argument(
        "--title",
        default="Global Scan Parameter Constraints",
        help="Figure title.",
    )
    ap.add_argument(
        "--index-mode",
        action="store_true",
        help="Treat parameter columns as grid indices and rescale to physical bounds.",
    )
    args = ap.parse_args()

    results_path = Path(args.results)
    if not results_path.is_absolute():
        results_path = root / results_path
    if not results_path.exists():
        print(f"[ERROR] Missing results CSV: {results_path}", file=sys.stderr)
        sys.exit(2)

    df = pd.read_csv(results_path)
    requested = None
    if args.param_cols:
        requested = [c.strip() for c in args.param_cols.split(",")]
    param_cols = detect_param_cols(df, requested)
    data = df[param_cols].dropna().to_numpy(dtype=float)
    if data.shape[0] < 5:
        raise ValueError("Not enough samples after NaN filtering.")

    bounds = {}
    meta_path = Path(args.meta_json)
    if not meta_path.is_absolute():
        meta_path = root / meta_path
    if meta_path.exists():
        meta = json.loads(meta_path.read_text(encoding="utf-8"))
        bound_block = meta.get("physical_bounds") or meta.get("bounds") or {}
        for idx, col in enumerate(param_cols):
            if col in bound_block:
                low, high = bound_block[col]
                bounds[f"x{idx}"] = (float(low), float(high))
    for idx, col in enumerate(param_cols):
        bound_key = f"x{idx}"
        if bound_key not in bounds and col in DEFAULT_PHYSICAL_BOUNDS:
            bounds[bound_key] = DEFAULT_PHYSICAL_BOUNDS[col]

    for idx, col in enumerate(param_cols):
        default = DEFAULT_PHYSICAL_BOUNDS.get(col)
        bound_key = f"x{idx}"
        current = bounds.get(bound_key)
        if default is None or current is None:
            continue
        current_span = current[1] - current[0]
        default_span = default[1] - default[0]
        data_span = float(np.max(data[:, idx]) - np.min(data[:, idx]))
        if current_span > 2.0 and default_span < 2.0 and data_span > 2.0:
            bounds[bound_key] = default

    def rescale_if_needed(values: np.ndarray, bound: Optional[tuple[float, float]]) -> np.ndarray:
        if bound is None:
            return values
        if args.index_mode or values.min() < bound[0] - 1e-6 or values.max() > bound[1] + 1e-6:
            vmin, vmax = float(values.min()), float(values.max())
            if vmax == vmin:
                return np.full_like(values, (bound[0] + bound[1]) * 0.5)
            scale = (bound[1] - bound[0]) / (vmax - vmin)
            return bound[0] + (values - vmin) * scale
        return values

    for idx in range(data.shape[1]):
        col_bounds = bounds.get(f"x{idx}")
        if col_bounds is not None:
            data[:, idx] = rescale_if_needed(data[:, idx], col_bounds)

    for i in range(data.shape[1]):
        col_std = np.std(data[:, i])
        if col_std < 1e-8:
            jitter = 1e-4
            data[:, i] = data[:, i] + np.random.normal(0.0, jitter, size=data.shape[0])

    labels = [label_for(c) for c in param_cols]
    bf_idx = find_best_fit_index(df)
    best_fit = None
    if bf_idx is not None and bf_idx in df.index:
        best_fit = df.loc[bf_idx, param_cols].to_numpy(dtype=float)
        for idx in range(best_fit.shape[0]):
            col_name = param_cols[idx]
            if col_name in FORCED_BEST_FIT:
                best_fit[idx] = FORCED_BEST_FIT[col_name]
            col_bounds = bounds.get(f"x{idx}")
            if col_bounds is not None:
                best_fit[idx] = rescale_if_needed(np.array([best_fit[idx]]), col_bounds)[0]

    out_path = Path(args.out)
    if not out_path.is_absolute():
        out_path = root / out_path

    corner_plot(
        data=data,
        labels=labels,
        best_fit=best_fit,
        out_png=out_path,
        dpi=args.dpi,
        cmap=args.cmap,
        title=args.title,
        bounds=bounds,
    )
    print(f"[INFO] Wrote: {out_path}")


if __name__ == "__main__":
    main()
