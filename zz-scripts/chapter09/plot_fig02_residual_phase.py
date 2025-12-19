#!/usr/bin/env python3

from __future__ import annotations

import sys
from pathlib import Path


import sys
from pathlib import Path

# Seed automatique des arguments CLI lorsqu'aucun n'est fourni
if __name__ == "__main__" and len(sys.argv) == 1:
    ROOT = Path(__file__).resolve().parents[2]
    csv_default = ROOT / "zz-data" / "chapter09" / "09_phase_diff.csv"
    meta_default = ROOT / "zz-data" / "chapter09" / "09_metrics_phase.json"
    out_default = ROOT / "zz-figures" / "chapter09" / "09_fig_02_residual_phase.png"
    sys.argv.extend([
        "--csv", str(csv_default),
        "--meta", str(meta_default),
        "--out", str(out_default),
    ])


import argparse
import json
import logging
from pathlib import Path
import textwrap

import matplotlib.gridspec as gridspec
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.lines import Line2D
from matplotlib.ticker import LogLocator, NullFormatter, NullLocator

plt.rcParams.update(
    {
        "figure.autolayout": True,
        "figure.figsize": (10, 6),
        "axes.titlepad": 25,
        "axes.labelpad": 15,
        "savefig.bbox": "tight",
        "savefig.pad_inches": 0.3,
        "font.family": "serif",
    }
)

from zz_tools import common_io as ci


# ----------------------------------------------------------------------
# Logging
# ----------------------------------------------------------------------
def setup_logger(level: str) -> logging.Logger:
    lvl = getattr(logging, level.upper(), logging.INFO)
    logging.basicConfig(
        level=lvl,
        format="[%(asctime)s] [%(levelname)s] %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )
    return logging.getLogger("fig02_residual_phase")


# ----------------------------------------------------------------------
# Utils
# ----------------------------------------------------------------------
def p95(a: np.ndarray) -> float:
    """Percentile 95 robuste (ignore NaN / inf)."""
    a = np.asarray(a, float)
    a = a[np.isfinite(a)]
    if a.size == 0:
        return float("nan")
    return float(np.percentile(a, 95.0))


def parse_bands(vals: list[float]) -> list[tuple[float, float]]:
    if len(vals) == 0 or len(vals) % 2:
        raise ValueError("bands must be pairs of floats (even count).")
    it = iter(vals)
    out: list[tuple[float, float]] = []
    for a, b in zip(it, it, strict=False):
        out.append(tuple(sorted((float(a), float(b)))))
    return out


def contiguous_segments(f_band: np.ndarray, gap_thresh_log10: float):
    """Index runs contigus en log10(f) d’après un seuil de 'trou'."""
    if f_band.size == 0:
        return []
    logf = np.log10(f_band)
    diffs = np.diff(logf)
    breaks = np.nonzero(diffs > gap_thresh_log10)[0]
    segments: list[np.ndarray] = []
    start = 0
    for b in breaks:
        segments.append(np.arange(start, b + 1))
        start = b + 1
    segments.append(np.arange(start, f_band.size))
    return segments


def load_meta(meta_path: Path) -> dict:
    if meta_path and meta_path.exists():
        try:
            return json.loads(meta_path.read_text(encoding="utf-8"))
        except Exception:
            return {}
    return {}


def principal_diff(a: np.ndarray, b: np.ndarray) -> np.ndarray:
    """Δφ_principal ∈ (−π, π]"""
    two_pi = 2.0 * np.pi
    return (np.asarray(a, float) - np.asarray(b, float) + np.pi) % (two_pi) - np.pi


def k_rebranch_median(
    phi_m: np.ndarray, phi_r: np.ndarray, f: np.ndarray, f1: float, f2: float
) -> int:
    """k = round(median((φ_m − φ_r)/2π)) sur [f1,f2]."""
    two_pi = 2.0 * np.pi
    m = (f >= f1) & (f <= f2) & np.isfinite(phi_m) & np.isfinite(phi_r)
    if not np.any(m):
        return 0
    return int(np.round(np.nanmedian((phi_m[m] - phi_r[m]) / two_pi)))


# ----------------------------------------------------------------------
# Main
# ----------------------------------------------------------------------
def main() -> None:
    ap = argparse.ArgumentParser(
        description="Figure 02 — Résidu |Δφ| par bandes + panneau compact"
    )
    ap.add_argument("--csv", type=Path, required=True)
    ap.add_argument(
        "--meta", type=Path, default=Path("zz-data/chapter09/09_metrics_phase.json")
    )
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--dpi", type=int, default=300)
    ap.add_argument(
        "--bands", nargs="+", type=float, default=[20, 300, 300, 1000, 1000, 2000]
    )
    ap.add_argument("--marker-size", type=float, default=3.0)
    ap.add_argument("--line-width", type=float, default=0.9)
    ap.add_argument("--gap-thresh-log10", type=float, default=0.12)
    ap.add_argument(
        "--log-level", choices=["DEBUG", "INFO", "WARNING", "ERROR"], default="INFO"
    )
    args = ap.parse_args()

    log = setup_logger(args.log_level)
    meta = load_meta(args.meta)  # pas forcément utilisé, mais inoffensif

    if not args.csv.exists():
        raise SystemExit(f"CSV introuvable: {args.csv}")

    # --- lecture CSV + normalisation colonnes (via zz_tools.common_io) ---
    df = pd.read_csv(args.csv)
    df = ci.ensure_fig02_cols(df)  # assure f_Hz, phi_ref, phi_mcgt*, etc.

    required = ["f_Hz", "phi_ref"]
    missing = [c for c in required if c not in df.columns]
    if missing:
        print(f"[WARNING] Colonnes manquantes pour fig02: {missing} – fig02 sautée pour le pipeline minimal.")

    # Variante active (phi_mcgt*) ou abs_dphi direct
    phi_col = None
    if "phi_mcgt" in df:
        phi_col = "phi_mcgt"
    elif "phi_mcgt_cal" in df:
        phi_col = "phi_mcgt_cal"
    elif "phi_mcgt_raw" in df:
        phi_col = "phi_mcgt_raw"
    elif "abs_dphi" in df:
        phi_col = None
    else:
        raise SystemExit(0)
    if phi_col:
        log.info("Variante active: %s", phi_col)

    # Tri / nettoyage
    order = np.argsort(df["f_Hz"].to_numpy(float))
    f = df["f_Hz"].to_numpy(float)[order]
    eps = 1e-12

    if phi_col:
        ref = df["phi_ref"].to_numpy(float)[order]
        mcg = df[phi_col].to_numpy(float)[order]
        m = np.isfinite(f) & np.isfinite(ref) & np.isfinite(mcg)
        f, ref, mcg = f[m], ref[m], mcg[m]
        if f.size == 0:
            raise SystemExit("Aucune ligne exploitable après filtrage de base.")

        bands = parse_bands(args.bands)
        if len(bands) == 0:
            raise SystemExit("Aucune bande valide fournie via --bands.")
        if len(bands) > 3:
            log.warning("Plus de 3 bandes fournies, seules les 3 premières seront tracées.")
            bands = bands[:3]

        # k de rebranch sur la première bande (20–300 typiquement)
        f20, f300 = bands[0]
        k = k_rebranch_median(mcg, ref, f, f20, f300)
        log.info("Rebranch k (%.1f–%.1f Hz) = %d cycles", f20, f300, k)
        absd_full = np.abs(principal_diff(mcg - k * (2.0 * np.pi), ref))
    else:
        bands = parse_bands(args.bands)
        f20, f300 = bands[0]
        k = 0
        absd_full = np.abs(df["abs_dphi"].to_numpy(float)[order])

    absd_plot = np.where((~np.isfinite(absd_full)) | (absd_full <= 0), eps, absd_full)

    # Stats globales sur 20–300
    m20300 = (f >= f20) & (f <= f300) & np.isfinite(absd_full)
    mean20 = float(np.nanmean(absd_full[m20300])) if m20300.any() else float("nan")
    p9520 = float(p95(absd_full[m20300])) if m20300.any() else float("nan")
    max20 = float(np.nanmax(absd_full[m20300])) if m20300.any() else float("nan")
    log.info(
        "Stats 20–300 Hz: mean=%.3f  p95=%.3f  max=%.3f",
        mean20,
        p9520,
        max20,
    )

    # ------------------------------------------------------------------
    # Figure & layout
    # ------------------------------------------------------------------
    n_bands = len(bands)
    args.out.parent.mkdir(parents=True, exist_ok=True)

    fig = plt.figure(figsize=(14, 8), dpi=args.dpi)
    gs = gridspec.GridSpec(
        nrows=n_bands,
        ncols=2,
        width_ratios=[1.0, 0.42],
        wspace=0.08,
        hspace=0.40,
    )

    axs = [fig.add_subplot(gs[i, 0]) for i in range(n_bands)]
    ax_right = fig.add_subplot(gs[:, 1])
    ax_right.axis("off")

    fig.suptitle(
        r"Phase Residual $|\Delta \phi|$ by Frequency Band  "
        r"($\phi_{\rm ref}$ vs $\phi_{\rm MCGT}$)",
        fontsize=22,
        weight="bold",
        y=0.985,
    )
    # plus d’espace sous le titre
    fig.subplots_adjust(top=0.88, bottom=0.08, left=0.08, right=0.65)

    # Styles
    marker_kw = dict(
        marker="o",
        markersize=float(args.marker_size),
        markeredgecolor="k",
        markeredgewidth=0.25,
        linestyle="",
        zorder=4,
    )
    line_kw = dict(
        lw=float(args.line_width),
        solid_capstyle="butt",
        zorder=3,
        color="C0",
    )

    # Limites globales en y (pour homogénéité)
    valid_absd = absd_plot[np.isfinite(absd_plot)]
    if valid_absd.size:
        ymin = max(float(valid_absd.min()) * 0.8, eps)
        ymax = float(valid_absd.max()) * 1.2
    else:
        ymin, ymax = eps, 1.0

    band_stats: list[tuple[float, float, int, float, float, float]] = []

    # ------------------------------------------------------------------
    # Panneaux par bande
    # ------------------------------------------------------------------
    for i, (ax, (blo, bhi)) in enumerate(zip(axs, bands, strict=False)):
        mb = (f >= blo) & (f <= bhi) & np.isfinite(absd_full)
        fb = f[mb]
        db = absd_full[mb]
        db_plot = absd_plot[mb]
        n_pts = int(mb.sum())

        if n_pts == 0:
            ax.text(
                0.5,
                0.5,
                "Aucun point dans cette bande",
                transform=ax.transAxes,
                ha="center",
                va="center",
                fontsize=11,
            )
            ax.set_xscale("log")
            ax.set_yscale("log")
            ax.set_xlim(blo, bhi)
            ax.set_ylim(ymin, ymax)
            ax.yaxis.set_major_locator(LogLocator(base=10.0, numticks=5))
            ax.yaxis.set_minor_locator(NullLocator())
            ax.yaxis.set_minor_formatter(NullFormatter())
            ax.grid(True, which="both", ls=":", alpha=0.3)
            continue

        mean_b = float(np.nanmean(db))
        p95_b = float(p95(db))
        max_b = float(np.nanmax(db))
        band_stats.append((blo, bhi, n_pts, mean_b, p95_b, max_b))

        # segments contigus (en log-f) pour des lignes propres
        segments = contiguous_segments(fb, args.gap_thresh_log10)
        for seg in segments:
            ax.plot(fb[seg], db_plot[seg], **line_kw)

        # Nuage de points par-dessus
        ax.plot(fb, db_plot, **marker_kw)

        ax.set_xscale("log")
        ax.set_yscale("log")
        ax.set_xlim(blo, bhi)
        ax.set_ylim(ymin, ymax)
        ax.yaxis.set_major_locator(LogLocator(base=10.0, numticks=5))
        ax.yaxis.set_minor_locator(NullLocator())
        ax.yaxis.set_minor_formatter(NullFormatter())
        ax.grid(True, which="both", ls=":", alpha=0.3)

        ax.set_title(
            f"{int(blo)}–{int(bhi)} Hz  n={n_pts} — "
            f"mean={mean_b:.3f}  p95={p95_b:.3f}  max={max_b:.3f}",
            fontsize=11,
            pad=8,
        )

        if i == n_bands - 1:
            ax.set_xlabel("Fréquence [Hz]")
        else:
            ax.set_xticklabels([])
        ax.set_ylabel(r"$|\Delta\phi_{\rm principal}|$  [rad]")

    # ------------------------------------------------------------------
    # Panneau de droite : résumé texte
    # ------------------------------------------------------------------
    lines: list[str] = []
    lines.append(r"$\bf Statistiques\ globales$ (20–300 Hz)")
    lines.append(f"mean = {mean20:.3f} rad")
    lines.append(f"p95  = {p9520:.3f} rad")
    lines.append(f"max  = {max20:.3f} rad")
    lines.append("")
    lines.append(r"$\bf Bandes\ individuelles$")

    if not band_stats:
        lines.append("(aucune bande avec points valides)")
    else:
        for (blo, bhi, n_pts, mean_b, p95_b, max_b) in band_stats:
            lines.append(
                f"{int(blo)}–{int(bhi)} Hz : n={n_pts}, "
                f"mean={mean_b:.3f}, p95={p95_b:.3f}, max={max_b:.3f}"
            )

    # éventuels méta (facultatif)
    if meta:
        lines.append("")
        lines.append(r"$\bf Méta\ (résumé)$")
        for k, v in meta.items():
            lines.append(textwrap.fill(f"{k}: {v}", width=40))

    ax_right.text(
        0.0,
        1.0,
        "\n".join(lines),
        transform=ax_right.transAxes,
        ha="left",
        va="top",
        fontsize=8,
    )

    # Légende générique (pour rappeler marker/ligne)
    legend_handles = [
        Line2D(
            [], [],
            **{k: v for k, v in line_kw.items() if k in {"color", "lw"}},
            label="courbe |Δφ|",
        ),
        Line2D(
            [], [],
            linestyle="",
            marker=marker_kw["marker"],
            markeredgecolor=marker_kw["markeredgecolor"],
            markerfacecolor="C0",
            markersize=marker_kw["markersize"],
            label="points individuels",
        ),
    ]
    axs[0].legend(
        handles=legend_handles,
        loc="upper right",
        fontsize=10,
        frameon=True,
        framealpha=0.85,
    )

    fig.savefig(args.out, dpi=args.dpi)
    log.info("Figure enregistrée → %s", args.out)


if __name__ == "__main__":
    main()
