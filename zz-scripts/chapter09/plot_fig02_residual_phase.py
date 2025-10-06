#!/usr/bin/env python3
"""
Figure 02 — Résidu de phase |Δφ| par bande de fréquence (φ_ref vs φ_MCGT)
Version publication – panneau de droite compact (Option A)

CHANGEMENTS CLÉS
- Résidu = |Δφ_principal| où Δφ_principal = ((φ_mcgt - k·2π) - φ_ref + π) mod 2π − π
  avec k = median((φ_mcgt − φ_ref)/(2π)) sur la bande 20–300 Hz.
- Étiquettes p95 à leur position "historique" : centrées en x, SOUS la ligne en log-y.
- Plus d’espace vertical entre le titre et le 1er panneau.

Exemple:
  python zz-scripts/chapter09/tracer_fig02_residual_phase.py \
    --csv zz-data/chapter09/09_phases_mcgt.csv \
    --meta zz-data/chapter09/09_metrics_phase.json \
    --out zz-figures/chapter09/09_fig_02_residual_phase.png \
    --bands 20 300 300 1000 1000 2000 \
    --dpi 300 --marker-size 3 --line-width 0.9 \
    --gap-thresh-log10 0.12 --log-level INFO
"""

from __future__ import annotations

import argparse
import json
import logging
from pathlib import Path

import matplotlib.gridspec as gridspec
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.lines import Line2D


# -------------------- utils --------------------
def setup_logger(level: str = "INFO") -> logging.Logger:
    logging.basicConfig(
        level=getattr(logging, level.upper(), logging.INFO),
        format="%(asctime)s [%(levelname)s] %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )
    return logging.getLogger("fig02")


def p95(a: np.ndarray) -> float:
    a = np.asarray(a, float)
    a = a[np.isfinite(a)]
    return float(np.percentile(a, 95.0)) if a.size else float("nan")


def parse_bands(vals: list[float]) -> list[tuple[float, float]]:
    if len(vals) == 0 or len(vals) % 2:
        raise ValueError("bands must be pairs of floats (even count).")
    it = iter(vals)
    return [tuple(sorted((float(a), float(b))))
                  for a, b in zip(it, it, strict=False)]


def contiguous_segments(f_band: np.ndarray, gap_thresh_log10: float):
    """Index runs contigus en log10(f) d’après un seuil de 'trou'."""
    if f_band.size == 0:
        return []
    logf = np.log10(f_band)
    diffs = np.diff(logf)
    breaks = np.nonzero(diffs > gap_thresh_log10)[0]
    segments = []
    start = 0
    for b in breaks:
        segments.append(np.arange(start, b + 1))
        start = b + 1
    segments.append(np.arange(start, f_band.size))
    return segments


def load_meta(meta_path: Path) -> dict:
    if meta_path and meta_path.exists():
        try:
            return json.loads(meta_path.read_text())
        except Exception:
            return {}
    return {}


def principal_diff(a: np.ndarray, b: np.ndarray) -> np.ndarray:
    """Δφ_principal ∈ (−π, π]"""
    return (np.asarray(a, float) - np.asarray(b, float) + \
            np.pi) % (2.0 * np.pi) - np.pi


def k_rebranch_median(
    phi_m: np.ndarray, phi_r: np.ndarray, f: np.ndarray, f1: float, f2: float
) -> int:
    """k = round(median((φ_m − φ_r)/2π)) sur [f1,f2]."""
    two_pi = 2.0 * np.pi
    m = (f >= f1) & (f <= f2) & np.isfinite(phi_m) & np.isfinite(phi_r)
    if not np.any(m):
        return 0
    return int(np.round(np.nanmedian((phi_m[m] - phi_r[m]) / two_pi)))


# -------------------- script --------------------
def main():
    ap = argparse.ArgumentParser(
        description="Figure 02 — Résidu |Δφ| par bandes + panneau compact"
    )
    ap.add_argument("--csv", type=Path, required=True)
    ap.add_argument(
        "--meta",
        type=Path,
        default=Path("zz-data/chapter09/09_metrics_phase.json") )
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--dpi", type=int, default=300)
    ap.add_argument(
        "--bands",
        nargs="+",
        type=float,
        default=[
            20,
            300,
            300,
            1000,
            1000,
            2000] )
    ap.add_argument("--marker-size", type=float, default=3.0)
    ap.add_argument("--line-width", type=float, default=0.9)
    ap.add_argument("--gap-thresh-log10", type=float, default=0.12)
    ap.add_argument(
        "--log-level",
        choices=[
            "DEBUG",
            "INFO",
            "WARNING",
            "ERROR"],
        default="INFO" )
    args = apap.add_argument(
        "--outdir",
        type=str,
        default=None,
        help="Dossier pour copier la figure (fallback $MCGT_OUTDIR)")


ap.add_argument(
    "--fmt",
    type=str,
    default=None,
    help="Format savefig (png, pdf, etc.)")
ap.add_argument("--transparent", action="store_true",
                help="Fond transparent pour savefig")
.parse_args()

    log = setup_logger(args.log_level)
    meta = load_meta(args.meta)

    if not args.csv.exists():
        raise SystemExit(f"CSV introuvable: {args.csv}")

    # --- lecture
    df = pd.read_csv(args.csv)
    for c in ("f_Hz", "phi_ref"):
        if c not in df.columns:
            raise SystemExit(f"Colonne manquante: {c}")

    # variante active
    if "phi_mcgt" in df:
        phi_col = "phi_mcgt"
    elif "phi_mcgt_cal" in df:
        phi_col = "phi_mcgt_cal"
    elif "phi_mcgt_raw" in df:
        phi_col = "phi_mcgt_raw"
    else:
        raise SystemExit("Aucune colonne phi_mcgt* disponible.")
    log.info("Variante active: %s", phi_col)

    # tri / nettoyage basique
    order = np.argsort(df["f_Hz"].to_numpy(float))
    f = df["f_Hz"].to_numpy(float)[order]
    ref = df["phi_ref"].to_numpy(float)[order]
    mcg = df[phi_col].to_numpy(float)[order]
    m = np.isfinite(f) & np.isfinite(ref) & np.isfinite(mcg)
    f, ref, mcg = f[m], ref[m], mcg[m]

    # bandes et k sur 20–300
    bands = parse_bands(args.bands)
    if len(bands) > 3:
        bands = bands[:3]
    (f20, f300) = bands[0]
    k = k_rebranch_median(mcg, ref, f, f20, f300)
    log.info("Rebranch k (20–300 Hz) = %d cycles", k)

    # résidu canonique = |Δφ_principal| après rebranch k
    absd_full = np.abs(principal_diff(mcg - k * (2.0 * np.pi), ref))
    # eps pour échelle log (affichage uniquement) — les stats sont calculées
    # AVANT ce remplacement
    eps = 1e-12
    absd_plot = np.where(
        (~np.isfinite(absd_full)) | (
            absd_full <= 0), eps, absd_full)

    # stats 20–300 pour panneau compact
    m20300 = (f >= f20) & (f <= f300) & np.isfinite(absd_full)
    mean20 = float(
        np.nanmean(
            absd_full[m20300])) if m20300.any() else float("nan")
    p9520 = float(p95(absd_full[m20300])) if m20300.any() else float("nan")
    log.info(
        "Stats 20–300 Hz: mean=%.3f  p95=%.3f  max=%.3f",
        mean20,
        p9520,
        float(np.nanmax(absd_full[m20300])) if m20300.any() else float("nan"),
    )

    # ---------------- figure & layout ----------------
    fig = plt.figure(figsize=(12.6, 8.2))
    gs = gridspec.GridSpec(
        nrows=3, ncols=2, width_ratios=[1.0, 0.38], wspace=0.08, hspace=0.30
    )

    # axes
    axs = [fig.add_subplot(gs[i, 0]) for i in range(3)]
    ax_right = fig.add_subplot(gs[:, 1])
    ax_right.axis("off")

    # titre + espace vertical accru
    fig.suptitle(
        r"Résidu de phase $|\Delta\phi|$ par bande de fréquence  "
        r"($\phi_{\rm ref}$ vs $\phi_{\rm MCGT}$)",
        fontsize=22,
        weight="bold",
        y=0.985,
    )
    # pousse les sous-graphiques plus bas pour laisser un gap sous le titre
    # <— plus d’espace que précédemment
    fig.subplots_adjust(top=0.88, bottom=0.08)

    # styles
    shade_color = "0.92"
    marker_kw = dict(
        marker="o",
        markersize=float(args.marker_size),
        markeredgecolor="k",
        markeredgewidth=0.25,
        linestyle="",
        zorder=4,
    )
    line_kw = dict(lw=float(args.line_width), solid_capstyle="butt", zorder=3)

    # ---------------- tracé panneaux ----------------
    for i, (ax, (blo, bhi)) in enumerate(zip(axs, bands, strict=False)):
        mb = (f >= blo) & (f <= bhi) & np.isfinite(absd_full)
        fb, db = f[mb], absd_full[mb]
        db_plot = absd_plot[mb]
        n_pts = int(mb.sum())
        mean_b = float(np.nanmean(db)) if n_pts else float("nan")
        p95_b = float(p95(db)) if n_pts else float("nan")
        max_b = float(np.nanmax(db)) if n_pts else float("nan")

        ax.set_title(
            f"{int(blo)}-{int(bhi)} Hz  n={n_pts} — mean={mean_b:.3f}  "
            f"p95={p95_b:.3f}  max={max_b:.3f}",
            loc="left",
            fontsize=11,
        )
        ax.set_xscale("log")
        ax.set_yscale("log")
        ax.grid(True, which="both", ls=":", alpha=0.35)

        # ombrage 20–300 dans le panneau (a)
        if i == 0:
            ax.axvspan(f20, f300, color=shade_color, zorder=1, alpha=1.0)

        # points + lignes contigües
        if fb.size:
            ax.plot(fb, db_plot, color="#1f77b4", **marker_kw)
            for seg in contiguous_segments(fb, args.gap_thresh_log10):
                if seg.size >= 2:
                    ax.plot(fb[seg], db_plot[seg], color="#1f77b4", **line_kw)

            # ligne p95
            ax.axhline(
                p95_b if np.isfinite(p95_b) else np.nan,
                color="r",
                lw=1.0,
                ls=":" )

            # étiquette p95 — géométrique au centre, SOUS la ligne (coords
            # log-y)
            if np.isfinite(p95_b):
                x_p = (
                    10 ** ((np.log10(blo) + np.log10(bhi)) / 2.0)
                    if fb.size >= 2
                    else fb[0]
                )
                y_p = p95_b / (
                    1.15 if i != 2 else 1.10
                )  # même placement que la version validée
                ax.text(
                    x_p,
                    y_p,
                    f"$p95={p95_b:.3f}\\,\\mathrm{{rad}}$",
                    color="r",
                    ha="center",
                    va="top",
                    fontsize=9,
                    bbox=dict(
                        boxstyle="round,pad=0.25",
                        facecolor=(shade_color if i == 0 else "white"),
                        alpha=0.95,
                        edgecolor="0.6",
                    ),
                )
        else:
            ax.text(
                0.5,
                0.5,
                "no data",
                transform=ax.transAxes,
                ha="center",
                va="center",
                fontsize=10,
            )

        # axes & labels
        ax.set_xlim(max(10.0, blo / 1.1), min(2048.0, bhi * 1.1))
        ax.set_ylabel(r"$|\Delta\phi|$ [rad]")
        if i == 2:
            ax.set_xlabel("Fréquence $f$ [Hz]")
        ax.tick_params(labelsize=9)

    # ---------------- panneau droit (Option A) ----------------
    # 1) légende des styles (légèrement plus haut)
    box_styles = ax_right.inset_axes(
        [0.08, 0.64, 0.84, 0.18])  # x,y,w,h (en coord. ax)
    box_styles.axis("off")

    h_points = Line2D(
        [],
        [],
        marker="o",
        linestyle="",
        markeredgecolor="k",
        markeredgewidth=0.25,
        markersize=args.marker_size,
        color="#1f77b4",
        label="données (points)",
    )
    h_line = Line2D(
        [],
        [],
        color="#1f77b4",
        lw=args.line_width,
        label="runs contigus (ligne)" )
    h_p95 = Line2D(
        [],
        [],
        color="r",
        lw=1.0,
        linestyle=":",
        label="p95 (bandes)")
    h_shade = Line2D(
        [],
        [],
        color=shade_color,
        lw=6,
        label=f"Bande {
            int(f20)}–{
            int(f300)} Hz" )

    leg1 = box_styles.legend(
        [h_points, h_line, h_p95, h_shade],
        [h.get_label() for h in [h_points, h_line, h_p95, h_shade]],
        loc="upper center",
        frameon=True,
        fontsize=10,
        borderpad=0.6,
        handlelength=2.8,
        ncol=1,
    )
    for t in leg1.get_texts():
        t.set_fontsize(10)

    # 2) panneau compact "Calage + stats 20–300 Hz" (plus bas, avec air au bas)
    box_meta = ax_right.inset_axes(
        [0.14, 0.37, 0.72, 0.20]
    )  # abaissé pour laisser de l’espace au panneau du bas
    box_meta.axis("off")

    cal = meta.get("calibration", {}) if isinstance(meta, dict) else {}
    cal_model = cal.get("model", cal.get("mode", "phi0,tc"))
    cal_enabled = cal.get("enabled", False)
    phi0_hat = cal.get("phi0_hat_rad", cal.get("phi0_hat", "N/A"))
    tc_hat = cal.get("tc_hat_s", cal.get("tc_hat", "N/A"))

    if isinstance(phi0_hat, (int, float)):
        s_phi0 = f"φ₀={phi0_hat:.3e} rad"
    else:
        s_phi0 = f"φ₀={phi0_hat}"
    if isinstance(tc_hat, (int, float)):
        s_tc = f"t_c={tc_hat:.3e} s"
    else:
        s_tc = f"t_c={tc_hat}"

    meta_text = (
        f"Calage: {cal_model} (enabled={cal_enabled})\n"
        f"{s_phi0},  {s_tc}\n\n"
        f"|Δφ| {int(f20)}–{int(f300)} Hz :\n"
        f"mean={mean20:.3f} rad ;  p95={p9520:.3f} rad"
    )

    box_meta.text(
        0.5,
        0.5,
        meta_text,
        ha="center",
        va="center",
        fontsize=10,
        bbox=dict(
            boxstyle="round",
            facecolor="white",
            alpha=0.96,
            edgecolor="0.6"),
         )

    # ---------------- sortie ----------------
    args.out.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(
        args.out,
        dpi=int(
            args.dpi),
        bbox_inches="tight",
        pad_inches=0.06)
    log.info("PNG écrit → %s", args.out)


if __name__ == "__main__":
    main()

# [MCGT POSTPARSE EPILOGUE v2]
# (compact) delegate to common helper; best-effort wrapper
try:
    import os
    import sys
    _here = os.path.abspath(os.path.dirname(__file__))
    _zz = os.path.abspath(os.path.join(_here, ".."))
    if _zz not in sys.path:
        sys.path.insert(0, _zz)
    from _common.postparse import apply as _mcgt_postparse_apply
except Exception:
    def _mcgt_postparse_apply(*_a, **_k):
        pass
try:
    if "args" in globals():
        _mcgt_postparse_apply(args, caller_file=__file__)
except Exception:
    pass
