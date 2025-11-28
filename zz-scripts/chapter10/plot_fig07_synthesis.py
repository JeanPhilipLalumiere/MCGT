#!/usr/bin/env python3
"""
Fig. 07 – Synthèse des séries de couverture – Chapitre 10.

Ce script lit un ou deux manifests JSON de résultats de bootstrap / couverture,
construit des séries (N, couverture, barres d'erreur, largeur moyenne d'IC),
puis produit :

- une figure de synthèse :
    zz-figures/chapter10/10_fig_07_synthesis.png  (par défaut)

- un tableau CSV détaillé à côté de la figure :
    zz-figures/chapter10/10_fig_07_synthesis.table.csv
"""

from __future__ import annotations

import argparse
import csv
import json
import logging
import os
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable, Sequence, Tuple, List

import matplotlib.pyplot as plt
import numpy as np
from matplotlib.gridspec import GridSpec
from matplotlib.lines import Line2D

# ---------------------------------------------------------------------------
# Paths MCGT
# ---------------------------------------------------------------------------
ROOT = Path(__file__).resolve().parents[2]
FIG_DIR = ROOT / "zz-figures" / "chapter10"
FIG_DIR.mkdir(parents=True, exist_ok=True)
DEFAULT_OUT_PNG = FIG_DIR / "10_fig_07_synthesis.png"


# ---------------------------------------------------------------------------
# Utils
# ---------------------------------------------------------------------------
def parse_figsize(s: str) -> tuple[float, float]:
    """Parse 'largeur,hauteur' en pouces (ex: '14,6')."""
    try:
        a, b = s.split(",")
        return float(a), float(b)
    except Exception as e:  # pragma: no cover - garde
        raise argparse.ArgumentTypeError(
            "figsize doit être 'largeur,hauteur' (ex: 14,6)"
        ) from e


def load_manifest(path: str | Path) -> dict[str, Any]:
    """Charge un manifest JSON."""
    p = Path(path)
    with p.open(encoding="utf-8") as f:
        return json.load(f)


def _first(d: dict[str, Any], keys: Sequence[str], default: Any = np.nan) -> Any:
    """Retourne la première clé présente/non None dans d, sinon default."""
    for k in keys:
        if k in d and d[k] is not None:
            return d[k]
    return default


def _param(params: dict[str, Any], candidates: Sequence[str], default: Any = np.nan) -> Any:
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


def series_from_manifest(man: dict[str, Any], label_override: str | None = None) -> Series:
    """Construit une Series à partir d'un manifest JSON."""
    results = man.get("results", [])
    if not results:
        raise ValueError("Manifest ne contient pas de 'results' non vide.")

    N = np.array([_first(r, ["N"], np.nan) for r in results], dtype=float)
    coverage = np.array(
        [_first(r, ["coverage"], np.nan) for r in results],
        dtype=float,
    )
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

    params = man.get("params", {}) or {}
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
    """Essaye de détecter (M, outer_B, inner_B) dans le dict de paramètres."""
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


# ---------------------------------------------------------------------------
# Stats & résumé
# ---------------------------------------------------------------------------
def compute_summary_rows(series_list: list[Series]) -> list[list[Any]]:
    """Prépare les lignes de tableau récapitulatif pour chaque série."""
    rows: list[list[Any]] = []
    for s in series_list:
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
    """Ajuste log W ~ a + b log N → renvoie b."""
    m = np.isfinite(N) & np.isfinite(W) & (N > 0) & (W > 0)
    if m.sum() < 2:
        return np.nan
    p = np.polyfit(np.log(N[m]), np.log(W[m]), 1)
    return float(p[0])


# ---------------------------------------------------------------------------
# CSV détaillé
# ---------------------------------------------------------------------------
def save_summary_csv(series_list: list[Series], out_csv: str | Path) -> None:
    """Écrit un CSV détaillant tous les points (N, couverture, largeur, etc.)."""
    out_csv = Path(out_csv)
    out_csv.parent.mkdir(parents=True, exist_ok=True)

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
    with out_csv.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        for s in series_list:
            M, outer_B, inner_B = detect_reps_params(s.params)
            for i in range(len(s.N)):
                w.writerow(
                    {
                        "series": s.label,
                        "N": int(s.N[i]) if np.isfinite(s.N[i]) else "",
                        "coverage": float(s.coverage[i])
                        if np.isfinite(s.coverage[i])
                        else "",
                        "err95_low": float(s.err_low[i])
                        if np.isfinite(s.err_low[i])
                        else "",
                        "err95_high": float(s.err_high[i])
                        if np.isfinite(s.err_high[i])
                        else "",
                        "width_mean": float(s.width_mean[i])
                        if np.isfinite(s.width_mean[i])
                        else "",
                        "M": int(M) if np.isfinite(M) else "",
                        "outer_B": int(outer_B) if np.isfinite(outer_B) else "",
                        "inner_B": int(inner_B) if np.isfinite(inner_B) else "",
                        "alpha": s.alpha,
                    }
                )
    logging.info("CSV de synthèse écrit : %s", out_csv)


# ---------------------------------------------------------------------------
# Tracé principal
# ---------------------------------------------------------------------------
def plot_synthese(
    series_list: list[Series],
    out_png: str | Path,
    figsize: tuple[float, float] = (14.0, 6.0),
    dpi: int = 300,
    ymin_cov: float | None = None,
    ymax_cov: float | None = None,
) -> None:
    """Trace la figure de synthèse (couverture + largeur + tableau)."""
    out_png = Path(out_png)
    out_png.parent.mkdir(parents=True, exist_ok=True)

    plt.style.use("classic")
    fig = plt.figure(figsize=figsize, constrained_layout=False)

    gs = GridSpec(2, 2, figure=fig, height_ratios=[0.78, 0.22], width_ratios=[1.0, 1.0])
    ax_cov = fig.add_subplot(gs[0, 0])
    ax_width = fig.add_subplot(gs[0, 1])
    ax_tab = fig.add_subplot(gs[1, :])

    alpha = series_list[0].alpha if series_list else 0.05
    nominal_level = 1.0 - alpha

    # --- Couverture vs N ---
    handles: list[Any] = []
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
        "Barres = Wilson 95% (n = outer B) ; IC interne = percentile (inner B).",
        transform=ax_cov.transAxes,
        fontsize=9,
        va="bottom",
    )
    ax_cov.text(
        0.02,
        0.03,
        f"α={alpha:.2f}. Variabilité ↑ pour petits N.",
        transform=ax_cov.transAxes,
        fontsize=9,
        va="bottom",
    )

    # --- Largeur vs N ---
    for s, h in zip(series_list, handles, strict=False):
        color = None
        if hasattr(h, "lines") and h.lines:
            color = h.lines[0].get_color()
        ax_width.plot(
            s.N,
            s.width_mean,
            "-o",
            lw=1.8,
            ms=5,
            label=s.label,
            color=color,
        )

    ax_width.set_title("Largeur d'IC vs N")
    ax_width.set_xlabel("Taille d'échantillon N")
    ax_width.set_ylabel("Largeur moyenne de l'IC 95% [rad]")
    ax_width.legend(fontsize=10, loc="upper right", frameon=True)

    # --- Tableau récapitulatif ---
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
    cell_text: list[list[str]] = []
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
    table = ax_tab.table(
        cellText=cell_text,
        colLabels=col_labels,
        cellLoc="center",
        colLoc="center",
        loc="center",
    )
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

    slopes: list[str] = []
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
            "Largeur moyenne en radians ; ajustement log–log width ≈ a·N^b ; "
            + " ; ".join(slopes)
            + "."
        )
        fig.text(0.5, 0.035, cap1, ha="center", fontsize=9)
        fig.text(0.5, 0.017, cap2, ha="center", fontsize=9)

    fig.subplots_adjust(
        left=0.06, right=0.98, top=0.93, bottom=0.09, wspace=0.25, hspace=0.35
    )

    fig.savefig(out_png, dpi=dpi, bbox_inches="tight")
    logging.info("Figure écrite : %s", out_png)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------
def main(argv: Sequence[str] | None = None) -> None:
    ap = argparse.ArgumentParser(
        description="Figure 07 – Synthèse des séries de couverture (Chapitre 10).",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
        allow_abbrev=False,
    )
    ap.add_argument(
        "--manifest-a",
        required=True,
        help="Manifest JSON principal (série A).",
    )
    ap.add_argument(
        "--label-a",
        default=None,
        help="Libellé override pour la série A (optionnel).",
    )
    ap.add_argument(
        "--manifest-b",
        default=None,
        help="Manifest JSON secondaire (série B, optionnelle).",
    )
    ap.add_argument(
        "--label-b",
        default=None,
        help="Libellé override pour la série B (optionnel).",
    )
    ap.add_argument(
        "--out",
        default=str(DEFAULT_OUT_PNG),
        help="Chemin de sortie de la figure PNG.",
    )
    ap.add_argument(
        "--dpi",
        type=int,
        default=300,
        help="DPI de la figure.",
    )
    ap.add_argument(
        "--figsize",
        default="14,6",
        help="Taille de la figure en pouces 'largeur,hauteur'.",
    )
    ap.add_argument(
        "--ymin-coverage",
        type=float,
        default=None,
        help="Bornes manuelles Ymin pour la couverture.",
    )
    ap.add_argument(
        "--ymax-coverage",
        type=float,
        default=None,
        help="Bornes manuelles Ymax pour la couverture.",
    )
    ap.add_argument(
        "-v",
        "--verbose",
        action="count",
        default=0,
        help="Verbosity cumulable (-v, -vv).",
    )

    args = ap.parse_args(list(argv) if argv is not None else None)

    # Logging
    level = logging.WARNING
    if args.verbose == 1:
        level = logging.INFO
    elif args.verbose >= 2:
        level = logging.DEBUG
    logging.basicConfig(level=level, format="[%(levelname)s] %(message)s")

    fig_w, fig_h = parse_figsize(args.figsize)

    series_list: list[Series] = []

    # Série A
    try:
        man_a = load_manifest(args.manifest_a)
        logging.info("Manifest A : %s", args.manifest_a)
        series_list.append(series_from_manifest(man_a, args.label_a))
    except Exception as e:
        print(f"[ERR] Manifest A invalide : {e}", file=sys.stderr)
        sys.exit(2)

    # Série B optionnelle
    if args.manifest_b:
        try:
            man_b = load_manifest(args.manifest_b)
            logging.info("Manifest B : %s", args.manifest_b)
            series_list.append(series_from_manifest(man_b, args.label_b))
        except Exception as e:
            print(f"[WARN] Manifest B ignoré : {e}", file=sys.stderr)

    # CSV à côté de la figure
    out_png = Path(args.out)
    out_csv = out_png.with_suffix(".table.csv")
    save_summary_csv(series_list, out_csv)

    # Tracé
    plot_synthese(
        series_list,
        out_png,
        figsize=(fig_w, fig_h),
        dpi=args.dpi,
        ymin_cov=args.ymin_coverage,
        ymax_cov=args.ymax_coverage,
    )


if __name__ == "__main__":
    main()
