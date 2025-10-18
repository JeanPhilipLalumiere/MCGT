#!/usr/bin/env python3
"""
plot_fig07_summary.py - Figure 7 (synthèse)

"""
from __future__ import annotations

import argparse
import csv
import json
import os
import sys
from dataclasses import dataclass
from typing import Any

import matplotlib.pyplot as plt
import numpy as np
from matplotlib.gridspec import GridSpec
from matplotlib.lines import Line2D

def safe_make_table(ax_tab, cell_text, col_labels):
    """Construit le tableau si utile, sinon None (sans lever d'IndexError)."""
    if not cell_text:
        return None
    try:
        t = ax_tab.table(
            cellText=cell_text,
            colLabels=col_labels,
            cellLoc="center",
            colLoc="center",
            loc="center",
        )
        return t
    except IndexError:
        return None

# ---------- utils ----------
def parse_figsize(s: str) -> tuple[float, float]:
    try:
        a, b = s.split(",")
        return float(a), float(b)
    except Exception as e:
        raise argparse.ArgumentTypeError(
            "figsize doit être 'largeur,hauteur' (ex: 14,6)"
        ) from e

def load_manifest(path: str) -> dict[str, Any]:
    with open(path, encoding="utf-8") as f:
        return json.load(f)

def _first(d: dict[str, Any], keys: list[str], default=np.nan):
    for k in keys:
        if k in d and d[k] is not None:
            return d[k]
    return default

def _param(params: dict[str, Any], candidates: list[str], default=np.nan):
    return _first(params, candidates, default)

@dataclass
class Series:
    label: str
    N: np.ndarray
    coverage: np.ndarray
    err_low: np.ndarray
    err_high: np.ndarray
    width_mean: np.ndarray
    alpha: float
    params: dict[str, Any]

def series_from_manifest(
    man: dict[str, Any], label_override: str | None = None
) -> Series:
    results = man.get("results", [])
    if not results:
        raise ValueError("Manifest ne contient pas de 'results'.")

    N = np.array([_first(r, ["N"], np.nan) for r in results], dtype=float)
    coverage = np.array([_first(r, ["coverage"], np.nan) for r in results], dtype=float)
    err_low = np.array(
        [_first(r, ["coverage_err95_low", "coverage_err_low"], 0.0) for r in results],
        dtype=float,
    )
    err_high = np.array(
        [_first(r, ["coverage_err95_high", "coverage_err_high"], 0.0) for r in results],
        dtype=float,
    )
    width_mean = np.array(
        [_first(r, ["width_mean_rad", "width_mean"], np.nan) for r in results],
        dtype=float,
    )

    params = man.get("params", {})
    alpha = float(_param(params, ["alpha", "conf_alpha"], 0.05))
    label = label_override or man.get("series_label") or man.get("label") or "série"

    return Series(
        label=label,
        N=N,
        coverage=coverage,
        err_low=err_low,
        err_high=err_high,
        width_mean=width_mean,
        alpha=alpha,
        params=params,
    )

def detect_reps_params(params: dict[str, Any]) -> tuple[float, float, float]:
    M = _param(
        params, ["M", "num_trials", "n_trials", "n_repeat", "repeats", "nsimu"], np.nan
    )
    outer_B = _param(
        params, ["outer_B", "outer", "B_outer", "outerB", "Bouter"], np.nan
    )
    inner_B = _param(
        params, ["inner_B", "inner", "B_inner", "innerB", "Binner"], np.nan
    )
    return float(M), float(outer_B), float(inner_B)

# ---------- stats & résumé ----------
def compute_summary_rows(series_list: list[Series]) -> list[list[Any]]:
    rows = []
    for s in series_list:
        if (len(s.coverage) == 0 or (hasattr(np, 'isnan') and np.all(np.isnan(s.coverage)))) \
           and (len(s.width_mean) == 0 or (hasattr(np, 'isnan') and np.all(np.isnan(s.width_mean)))):
            continue
        mean_cov = np.nanmean(s.coverage)
        med_cov = np.nanmedian(s.coverage)
        std_cov = np.nanstd(s.coverage)
        p95_cov = np.nanpercentile(s.coverage, 95)
        med_w = np.nanmedian(s.width_mean)
        _, outer_B, inner_B = detect_reps_params(s.params)
        rows.append(
            [
                s.label,
                int(outer_B) if np.isfinite(outer_B) else "",
                int(inner_B) if np.isfinite(inner_B) else "",
                mean_cov,
                med_cov,
                std_cov,
                p95_cov,
                med_w,
            ]
        )
    return rows

def powerlaw_slope(N: np.ndarray, W: np.ndarray) -> float:
    m = np.isfinite(N) & np.isfinite(W) & (N > 0) & (W > 0)
    if m.sum() < 2:
        return np.nan
    p = np.polyfit(np.log(N[m]), np.log(W[m]), 1)
    return float(p[0])

# ---------- CSV ----------
def save_summary_csv(series_list: list[Series], out_csv: str) -> None:
    os.makedirs(os.path.dirname(out_csv) or ".", exist_ok=True)
    fields = [
        "series",
        "N",
        "coverage",
        "err95_low",
        "err95_high",
        "width_mean",
        "M",
        "outer_B",
        "inner_B",
        "alpha",
    ]
    with open(out_csv, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        for s in series_list:
            M, outer_B, inner_B = detect_reps_params(s.params)
            for i in range(len(s.N)):
                w.writerow(
                    {
                        "series": s.label,
                        "N": int(s.N[i]) if np.isfinite(s.N[i]) else "",
                        "coverage": (
                            float(s.coverage[i]) if np.isfinite(s.coverage[i]) else ""
                        ),
                        "err95_low": (
                            float(s.err_low[i]) if np.isfinite(s.err_low[i]) else ""
                        ),
                        "err95_high": (
                            float(s.err_high[i]) if np.isfinite(s.err_high[i]) else ""
                        ),
                        "width_mean": (
                            float(s.width_mean[i])
                            if np.isfinite(s.width_mean[i])
                            else ""
                        ),
                        "M": int(M) if np.isfinite(M) else "",
                        "outer_B": int(outer_B) if np.isfinite(outer_B) else "",
                        "inner_B": int(inner_B) if np.isfinite(inner_B) else "",
                        "alpha": s.alpha,
                    }
                )

# ---------- tracé ----------
def plot_synthese(
    series_list: list[Series],
    out_png: str,
    figsize=(14, 6),
    dpi=300,
    ymin_cov: float | None = None,
    ymax_cov: float | None = None,
):
    plt.style.use("classic")
    fig = plt.figure(figsize=figsize, constrained_layout=False)

    gs = GridSpec(2, 2, figure=fig, height_ratios=[0.78, 0.22], width_ratios=[1.0, 1.0])
    ax_cov = fig.add_subplot(gs[0, 0])
    ax_width = fig.add_subplot(gs[0, 1])
    ax_tab = fig.add_subplot(gs[1, :])

    alpha = series_list[0].alpha if series_list else 0.05
    nominal_level = 1.0 - alpha

    handles = []
    for s in series_list:
        yerr = np.vstack([s.err_low, s.err_high])
        h = ax_cov.errorbar(
            s.N,
            s.coverage,
            yerr=yerr,
            fmt="o-",
            lw=1.6,
            ms=6,
            capsize=3,
            zorder=3,
            label=s.label,
        )
        handles.append(h)

    ax_cov.axhline(nominal_level, color="crimson", ls="--", lw=1.5, zorder=1)
    nominal_handle = Line2D(
        [0],
        [0],
        color="crimson",
        lw=1.5,
        ls="--",
        label=f"Niveau nominal {int(nominal_level * 100)}%",
    )

    ax_cov.legend(
        [nominal_handle] + handles,
        [nominal_handle.get_label()] + [h.get_label() for h in handles],
        loc="upper left",
        frameon=True,
        fontsize=10,
    )

    ax_cov.set_title("Couverture vs N")
    ax_cov.set_xlabel("Taille d'échantillon N")
    ax_cov.set_ylabel("Couverture (IC 95% contient la référence)")
    if (ymin_cov is not None) or (ymax_cov is not None):
        ymin = ymin_cov if ymin_cov is not None else ax_cov.get_ylim()[0]
        ymax = ymax_cov if ymax_cov is not None else ax_cov.get_ylim()[1]
        ax_cov.set_ylim(ymin, ymax)

    ax_cov.text(
        0.02,
        0.06,
        "Barres = Wilson 95% (n = outer B=400,2000); IC interne = percentile (inner B=2000)",
        transform=ax_cov.transAxes,
        fontsize=9,
        va="bottom",
    )
    ax_cov.text(
        0.02,
        0.03,
        "α=0.05. Variabilité ↑ pour petits N.",
        transform=ax_cov.transAxes,
        fontsize=9,
        va="bottom",
    )

    for s, h in zip(series_list, handles, strict=False):
        color = h.lines[0].get_color() if hasattr(h, "lines") and h.lines else None
        ax_width.plot(s.N, s.width_mean, "-o", lw=1.8, ms=5, label=s.label, color=color)
    ax_width.set_title("Largeur d'IC vs N")
    ax_width.set_xlabel("Taille d'échantillon N")
    ax_width.set_ylabel("Largeur moyenne de l'IC 95% [rad]")
    ax_width.legend(fontsize=10, loc="upper right", frameon=True)

    ax_tab.set_title("Synthèse numérique (résumé)", y=0.88, pad=12, fontsize=12)
    rows = compute_summary_rows(series_list)

    col_labels = [
        "série",
        "outer_B",
        "inner_B",
        "mean_cov",
        "med_cov",
        "std_cov",
        "p95_cov",
        "med_width [rad]",
    ]
    cell_text = []
    for r in rows:
        cell_text.append(
            [
                r[0],
                f"{r[1]}" if r[1] != "" else "-",
                f"{r[2]}" if r[2] != "" else "-",
                f"{r[3]:.3f}" if np.isfinite(r[3]) else "-",
                f"{r[4]:.3f}" if np.isfinite(r[4]) else "-",
                f"{r[5]:.3f}" if np.isfinite(r[5]) else "-",
                f"{r[6]:.3f}" if np.isfinite(r[6]) else "-",
                f"{r[7]:.5f}" if np.isfinite(r[7]) else "-",
            ]
        )

    ax_tab.axis("off")
    table = safe_make_table(ax_tab, cell_text, col_labels)
    if table is not None:
        table.auto_set_font_size(False)
        table.set_fontsize(10)
        table.scale(1.0, 1.3)
        for (r, c), cell in table.get_celld().items():
            cell.set_edgecolor("0.3")
            cell.set_linewidth(0.8)
            if r == 0:
                cell.set_height(cell.get_height() * 1.15)
            if c == 0:
                cell.set_width(cell.get_width() * 1.85)
    
    slopes = []
    for s in series_list:
        b = powerlaw_slope(s.N, s.width_mean)
        slopes.append(f"{s.label}: b={b:.2f}" if np.isfinite(b) else f"{s.label}: b=NA")

    if series_list:
        s0 = series_list[0]
        M0, outer0, inner0 = detect_reps_params(s0.params)
        cap1 = (
            f"Protocole : M={int(M0) if np.isfinite(M0) else '?'} réalisations/point ; "
            f"barres = Wilson 95% (calculées sur M). "
            f"Bootstrap : outer_B={int(outer0) if np.isfinite(outer0) else '?'}, "
            f"inner_B={int(inner0) if np.isfinite(inner0) else '?'} ; α={s0.alpha:.2f}."
        )
        cap2 = (
            "Largeur moyenne en radians ; ajustement log-log width ≈ a·N^b ; "
            + " ; ".join(slopes)
            + "."
        )
        fig.text(0.5, 0.035, cap1, ha="center", fontsize=9)
        fig.text(0.5, 0.017, cap2, ha="center", fontsize=9)

    fig.subplots_adjust(
        left=0.06, right=0.98, top=0.93, bottom=0.09, wspace=0.25, hspace=0.35
    )

    os.makedirs(os.path.dirname(out_png) or ".", exist_ok=True)
    fig.savefig(out_png, dpi=dpi, bbox_inches="tight")
    print(f"[OK] Figure écrite : {out_png}")

# ---------- CLI ----------
def main(argv=None):
    ap = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    ap.add_argument("--manifest-a", required=True)
    ap.add_argument("--label-a", default=None)
    ap.add_argument("--manifest-b", default=None)
    ap.add_argument("--label-b", default=None)
    ap.add_argument("--out", default="fig_07_summary_compare.png")
    ap.add_argument("--dpi", type=int, default=300)
    ap.add_argument("--figsize", default="14,6")
    ap.add_argument("--ymin-coverage", type=float, default=None)
    ap.add_argument("--ymax-coverage", type=float, default=None)
    args = ap.parse_args(argv)

    fig_w, fig_h = parse_figsize(args.figsize)

    series_list: list[Series] = []
    try:
        man_a = load_manifest(args.manifest_a)
        series_list.append(series_from_manifest(man_a, args.label_a))
    except Exception as e:
        print(f"[ERR] Manifest A invalide: {e}", file=sys.stderr)
        sys.exit(2)

    if args.manifest_b:
        try:
            man_b = load_manifest(args.manifest_b)
            series_list.append(series_from_manifest(man_b, args.label_b))
        except Exception as e:
            print(f"[WARN] Manifest B ignoré: {e}", file=sys.stderr)

    out_csv = os.path.splitext(args.out)[0] + ".table.csv"
    save_summary_csv(series_list, out_csv)
    print(f"[OK] CSV écrit : {out_csv}")

    plot_synthese(
        series_list,
        args.out,
        figsize=(fig_w, fig_h),
        dpi=args.dpi,
        ymin_cov=args.ymin_coverage,
        ymax_cov=args.ymax_coverage,
    )

if __name__ == "__main__":
    main()
