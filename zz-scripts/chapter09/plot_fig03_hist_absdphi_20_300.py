#!/usr/bin/env python3
"""
plot_fig03_hist_absdphi_20_300.py
Histogramme du résidu de phase |Δφ| sur une fenêtre (par défaut 20–300 Hz).

Exemple :
python zz-scripts/chapter09/plot_fig03_hist_absdphi_20_300.py \
  --csv zz-data/chapter09/09_phases_mcgt.csv \
  --meta zz-data/chapter09/09_metrics_phase.json \
  --out zz-figures/chapter09/09_fig_03_hist_absdphi_20_300.png \
  --mode principal --bins 50 --window 20 300 --xscale log --dpi 300 --log-level INFO
"""

import argparse
import json
import logging
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

# -------- Defaults
DEF_CSV = Path("zz-data/chapter09/09_phases_mcgt.csv")
DEF_DIFF = Path("zz-data/chapter09/09_phase_diff.csv")
DEF_META = Path("zz-data/chapter09/09_metrics_phase.json")
DEF_OUT = Path("zz-figures/chapter09/09_fig_03_hist_absdphi_20_300.png")


# -------- Utils
def setup_logger(level: str):
    logging.basicConfig(
        level=getattr(logging, level.upper(), logging.INFO),
        format="[%(asctime)s] [%(levelname)s] %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )
    return logging.getLogger("fig03")


def principal_phase_diff(a: np.ndarray, b: np.ndarray) -> np.ndarray:
    """((a-b+π) mod 2π) − π  ∈ (−π, π]"""
    return (np.asarray(a, float) - np.asarray(b, float) + \
            np.pi) % (2 * np.pi) - np.pi


def parse_args():
    p = argparse.ArgumentParser(
    p.add_argument('--style', choices=['paper','talk','mono','none'], default='none', help='Style de figure (opt-in)')
    args = p.parse_args()
        description="Tracer fig_03 – Histogramme |Δφ| (20–300 Hz)"
    )
    p.add_argument(
        "--diff",
        type=Path,
        default=DEF_DIFF,
        help="CSV 09_phase_diff.csv (préféré si présent, contient 'abs_dphi')",
    )
    p.add_argument( "--csv", type=Path, default=DEF_CSV,
                    help="CSV 09_phases_mcgt.csv (fallback)" )
    p.add_argument(
        "--meta",
        type=Path,
        default=DEF_META,
        help="JSON méta (calage/grille) pour annotation",
    )
    p.add_argument("--out", type=Path, default=DEF_OUT, help="PNG de sortie")
    p.add_argument("--svg", action="store_true", help="Écrire aussi un .svg")
    p.add_argument("--bins", type=int, default=50, help="Nombre de bins")
    p.add_argument(
        "--window",
        nargs=2,
        type=float,
        default=[20.0, 300.0],
        metavar=("FMIN", "FMAX"),
        help="Fenêtre fréquentielle [Hz]",
    )
    p.add_argument(
        "--xscale",
        choices=[
            "linear",
            "log"],
        default="log",
        help="Échelle horizontale" )
    p.add_argument(
        "--mode",
        choices=["principal", "unwrap", "raw"],
        default="principal",
        help="Définition du résidu si --csv est utilisé (défaut: principal)",
    )
    p.add_argument(
        "--no-lines",
        action="store_true",
        help="Ne pas tracer les lignes des stats" )
    p.add_argument(
        "--legend-loc",
        default="upper right",
        help="loc Matplotlib")
    p.add_argument("--dpi", type=int, default=300, help="DPI de sortie")
    p.add_argument(
        "--log-level",
        choices=[
            "DEBUG",
            "INFO",
            "WARNING",
            "ERROR"],
        default="INFO" )
    return pp.add_argument(
        "--outdir",
        type=str,
        default=None,
        help="Dossier pour copier la figure (fallback $MCGT_OUTDIR)")


p.add_argument("--fmt", type=str, default=None,
               help="Format savefig (png, pdf, etc.)")


# -------- Main
def main():
    args = parse_args()
    log = setup_logger(args.log_level)

    # --- Charger données
    data_label = None
    f = None
    abs_dphi = None

    if args.diff.exists():
        df = pd.read_csv(args.diff)
        if {"f_Hz", "abs_dphi"}.issubset(df.columns):
            f = df["f_Hz"].to_numpy(float)
            abs_dphi = df["abs_dphi"].to_numpy(float)
            data_label = args.diff.name
            log.info("Chargé diff CSV: %s (%d points).", args.diff, len(df))
        else:
            log.warning(
                "%s existe mais colonnes manquantes -> fallback sur --csv",
                args.diff )

    if abs_dphi is None:
        if not args.csv.exists():
            raise SystemExit(
                f"Aucun fichier d'entrée: {
                    args.diff} et {
                    args.csv}")
        mc = pd.read_csv(args.csv).sort_values("f_Hz")
        need = {"f_Hz", "phi_ref"}
        if not need.issubset(mc.columns):
            raise SystemExit(f"{args.csv} doit contenir au moins {need}")
        # choisir variante
        for col in ("phi_mcgt", "phi_mcgt_cal", "phi_mcgt_raw"):
            if col in mc.columns:
                phi_m = mc[col].to_numpy(float)
                variant = col
                break
        else:
            raise SystemExit(
                "Aucune colonne phi_mcgt* disponible dans le CSV.")
        phi_r = mc["phi_ref"].to_numpy(float)
        f = mc["f_Hz"].to_numpy(float)

        fmin, fmax = sorted(map(float, args.window))
        mask_win = (
            f >= fmin) & (
            f <= fmax) & np.isfinite(phi_m) & np.isfinite(phi_r)

        if args.mode == "raw":
            abs_dphi = np.abs(phi_m - phi_r)
            info_mode = "raw abs(φ_MCGT−φ_ref)"
            k_used = None
        elif args.mode == "unwrap":
            abs_dphi = np.abs(np.unwrap(phi_m - phi_r))
            info_mode = "abs(unwrap(φ_MCGT−φ_ref))"
            k_used = None
        else:  # principal
            two_pi = 2 * np.pi
            if np.any(mask_win):
                k_used = int(
                    np.round(
                        np.nanmedian(
                            (phi_m[mask_win] -
                             phi_r[mask_win]) /
                            two_pi)) )
            else:
                k_used = 0
            dphi = principal_phase_diff(phi_m - k_used * two_pi, phi_r)
            abs_dphi = np.abs(dphi)
            info_mode = f"principal diff (k={k_used})"
        data_label = f"{args.csv.name} • {variant} • {info_mode}"
        log.info(
            "Chargé mcgt CSV: %s (%d points). Mode=%s",
            args.csv,
            len(mc),
            args.mode )

    # --- Fenêtre & stats
    fmin, fmax = sorted(map(float, args.window))
    sel = (f >= fmin) & (f <= fmax) & np.isfinite(abs_dphi)
    if not np.any(sel):
        raise SystemExit(f"Aucun point dans la fenêtre {fmin}-{fmax} Hz")

    vals = abs_dphi[sel]
    n_total = int(vals.size)
    n_zero = int(np.sum(vals == 0.0))
    pos = vals[vals > 0.0]

    def _p95(a):
        a = a[np.isfinite(a)]
        return float(np.percentile(a, 95.0)) if a.size else np.nan

    mean_abs = float(np.nanmean(vals))
    med_abs = float(np.nanmedian(vals))
    p95_abs = _p95(vals)
    max_abs = float(np.nanmax(vals))

    log.info(
        "Fenêtre %.0f–%.0f Hz : n=%d (zeros=%d). mean=%.3g median=%.3g p95=%.3g max=%.3g",
        fmin,
        fmax,
        n_total,
        n_zero,
        mean_abs,
        med_abs,
        p95_abs,
        max_abs,
    )

    # --- Tracé
    plt.rcParams.update(
        {
            "font.size": 11,
            "axes.titlesize": 16,
            "axes.labelsize": 12,
            "legend.fontsize": 10,
            "xtick.labelsize": 10,
            "ytick.labelsize": 10,
        }
    )
    fig, ax = plt.subplots(figsize=(12.8, 6.0))

    if args.xscale == "log" and pos.size > 0:
        vmin, vmax = pos.min(), pos.max()
        edge_lo = max(vmin, 10 ** (np.floor(np.log10(vmin)) - 1))
        edge_hi = vmax * 1.2
        bins = np.logspace(np.log10(edge_lo), np.log10(edge_hi), args.bins + 1)
        ax.hist(
            pos,
            bins=bins,
            alpha=0.75,
            edgecolor="k",
            label="données (>0)")
        ax.set_xscale("log")
        if n_zero > 0:
            ax.text(
                0.02,
                0.92,
                f"n_zero = {n_zero}",
                transform=ax.transAxes,
                fontsize=9,
                va="top",
                bbox=dict(
                    boxstyle="round,pad=0.2",
                    facecolor="white",
                    edgecolor="gray",
                    linewidth=0.6,
                ),
            )
    else:
        ax.hist(vals, bins=args.bins, alpha=0.75, edgecolor="k")

    ax.set_xlabel(rf"$|\Delta\phi|$ [rad]  ({int(fmin)}–{int(fmax)} Hz)")
    ax.set_ylabel("Comptes")
    ax.set_title(
        rf"Histogramme du résidu de phase $|\Delta\phi|$  ({
            int(fmin)}–{
            int(fmax)} Hz)" )

    ax.grid(which="major", linestyle="-", linewidth=0.6, alpha=0.45)
    ax.grid(which="minor", linestyle=":", linewidth=0.4, alpha=0.35)

    if not args.no_lines and (pos.size > 0 or args.xscale == "linear"):
        ax.axvline(
            med_abs,
            color="C0",
            linestyle="--",
            linewidth=1.6,
            label="médiane")
        ax.axvline(
            mean_abs,
            color="C1",
            linestyle="--",
            linewidth=1.6,
            label="moyenne")
        ax.axvline(
            p95_abs,
            color="C2",
            linestyle=":",
            linewidth=1.6,
            label="p95")
        ax.axvline(
            max_abs,
            color="C3",
            linestyle=":",
            linewidth=1.6,
            label="max")

    handles, labels = ax.get_legend_handles_labels()
    if handles:
        ax.legend(
            handles,
            labels,
            loc="center left",
            bbox_to_anchor=(
                1.02,
                0.5),
            frameon=True )

    # --- Boîtes d'info
    ax.text(
        0.02,
        0.95,
        f"Source: {data_label}\n" f"n={n_total}  mean={
            mean_abs:.3g}  median={
            med_abs:.3g}  p95={
                p95_abs:.3g}  max={
                    max_abs:.3g}",
        transform=ax.transAxes,
        fontsize=9,
        va="top",
        bbox=dict(
                        boxstyle="round,pad=0.4",
                        facecolor="white",
                        edgecolor="black",
                        linewidth=0.7,
                        ),
                         )

    # méta (si fournie)
    cal_lines = []
    if args.meta and Path(args.meta).exists():
        try:
            meta = json.loads(Path(args.meta).read_text())
            cal = meta.get("calibration", {})
            grid = meta.get("grid_used", meta.get("grid", {}))
            cal_lines.append(
                f"Calage: {cal.get('model', cal.get('mode', 'phi0,tc'))} "
                f"(enabled={cal.get('enabled', False)})"
            )
            if "phi0_hat_rad" in cal or "tc_hat_s" in cal:
                phi0 = cal.get("phi0_hat_rad", np.nan)
                tc = cal.get("tc_hat_s", np.nan)
                cal_lines.append(f"φ0={phi0:.3g} rad,  t_c={tc:.3g} s")
            if grid:
                cal_lines.append(
                    f"Grille: [{int(grid.get('fmin_Hz', fmin))}-{int(grid.get('fmax_Hz', fmax))}] Hz, "
                    f"dlog10={grid.get('dlog10', '?')}"
                )
        except Exception as e:
            cal_lines.append(f"(meta illisible: {e})")
    else:
        cal_lines.append("(meta indisponible)")

    cal_lines.append(
        f"|Δφ| {
            int(fmin)}–{
            int(fmax)} Hz : mean={
                mean_abs:.3g} rad ; p95={
                    p95_abs:.3g} rad" )
    ax.text(
        0.02,
        0.82,
        "\n".join(cal_lines),
        transform=ax.transAxes,
        fontsize=9,
        va="top",
        bbox=dict(
            boxstyle="round,pad=0.4",
            facecolor="white",
            edgecolor="black",
            linewidth=0.7,
        ),
    )

    # p95 rappel
    if np.isfinite(p95_abs) and p95_abs > 0:
        ax.text(
            0.80,
            0.95,
            f"p95 = {p95_abs:.3f} rad",
            transform=ax.transAxes,
            fontsize=10,
            va="top",
            bbox=dict(
                boxstyle="round,pad=0.3",
                facecolor="#f2f2f2",
                edgecolor="gray",
                linewidth=0.6,
            ),
        )

    # Save
    args.out.parent.mkdir(parents=True, exist_ok=True)
    plt.tight_layout(rect=[0, 0, 0.88, 1.0])
    plt.savefig(args.out, dpi=args.dpi, bbox_inches="tight")
    log.info("PNG écrit → %s", args.out)
    if args.svg:
        plt.savefig(args.out.with_suffix(".svg"), bbox_inches="tight")
        log.info("SVG écrit → %s", args.out.with_suffix(".svg"))


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
