#!/usr/bin/env python3
"""
Figure 01 — Overlay φ_ref vs φ_MCGT + inset résidu (version corrigée)

- Auto-variant: phi_mcgt > phi_mcgt_cal > phi_mcgt_raw
- k (rebranch) = round(median((phi_m - phi_r)/(2π))) sur [f1,f2]
- k appliqué à la série affichée (superposition)
- Inset/métriques sur |Δφ| principal après rebranch
"""

from __future__ import annotations

import argparse
import configparser
import json
import logging
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.lines import Line2D

from mcgt.constants import C_LIGHT_M_S

DEF_IN = Path("zz-data/chapter09/09_phases_mcgt.csv")
DEF_META = Path("zz-data/chapter09/09_metrics_phase.json")
DEF_INI = Path("zz-configuration/gw_phase.ini")
DEF_OUT = Path("zz-figures/chapter09/09_fig_01_phase_overlay.png")


# ---------------- utils
def setup_logger(level="INFO"):
    logging.basicConfig(
        level=getattr(logging, level.upper(), logging.INFO),
        format="[%(asctime)s] [%(levelname)s] %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )
    return logging.getLogger("fig01")


def p95(a: np.ndarray) -> float:
    a = np.asarray(a, float)
    a = a[np.isfinite(a)]
    return float(np.percentile(a, 95.0)) if a.size else float("nan")


def principal_diff(a: np.ndarray, b: np.ndarray) -> np.ndarray:
    return (a - b + np.pi) % (2.0 * np.pi) - np.pi


def enforce_monotone_freq(f, arrays, log):
    f = np.asarray(f, float)
    order = np.argsort(f)
    f_sorted = f[order]
    keep = np.ones_like(f_sorted, bool)
    keep[1:] = np.diff(f_sorted) > 0
    if np.any(~keep):
        log.warning(
            "Fréquences dupliquées → %d doublons supprimés.", int(
                (~keep).sum()) )
    out = {k: np.asarray(v, float)[order][keep] for k, v in arrays.items()}
    return f_sorted[keep], out


def mask_flat_tail(y: np.ndarray, min_run=3, atol=1e-12):
    y = np.asarray(y, float)
    n = y.size
    if n < min_run + 1:
        return y, n - 1
    run, last = 0, n - 1
    for i in range(n - 1, 0, -1):
        if np.isfinite(y[i]) and np.isfinite(
            y[i - 1]) and abs(y[i] - y[i - 1]) < atol:
            run += 1
            if run >= min_run:
                last = i - run
                break
        else:
            run = 0
    if run >= min_run and last < n - 1:
        yy = y.copy()
        yy[last + 1 :] = np.nan
        return yy, last
    return y, n - 1


def pick_anchor_frequency(f: np.ndarray, fmin: float, fmax: float) -> float:
    if fmin <= 100.0 and fmax >= 100.0:
        return 100.0
    return float(
        np.exp(0.5 * (np.log(max(fmin, 1e-12)) + np.log(max(fmax, 1e-12)))))


def interp_at(x, xp, fp):
    xp = np.asarray(xp, float)
    fp = np.asarray(fp, float)
    m = np.isfinite(xp) & np.isfinite(fp)
    return float(np.interp(x, xp[m], fp[m])) if np.any(m) else float("nan")


def load_meta_and_ini(meta_path: Path, ini_path: Path, log):
    grid = {"fmin_Hz": 10.0, "fmax_Hz": 2048.0, "dlog10": 0.01}
    calib = {
        "enabled": False,
        "model": "phi0,tc",
        "weight": "1/f2",
        "phi0_hat_rad": 0.0,
        "tc_hat_s": 0.0,
        "window_Hz": [20.0, 300.0],
        "used_window_Hz": None,
    }
    variant = None
    if meta_path.exists():
        try:
            meta = json.loads(meta_path.read_text())
            c = C_LIGHT_M_S
            calib["enabled"] = bool(c.get("enabled", calib["enabled"]))
            calib["model"] = str(
                c.get(
                    "mode",
                    c.get(
                        "model_used",
                        calib["model"])))
            calib["phi0_hat_rad"] = float(
                c.get("phi0_hat_rad", calib["phi0_hat_rad"]))
            calib["tc_hat_s"] = float(c.get("tc_hat_s", calib["tc_hat_s"]))
            if (
                "window_Hz" in c
                and isinstance(c["window_Hz"], (list, tuple))
                and len(c["window_Hz"]) >= 2
            ):
                calib["window_Hz"] = [
                    float(c["window_Hz"][0]),
                    float(c["window_Hz"][1]),
                ]
            if (
                "used_window_Hz" in c
                and isinstance(c["used_window_Hz"], (list, tuple))
                and len(c["used_window_Hz"]) >= 2
            ):
                calib["used_window_Hz"] = [
                    float(c["used_window_Hz"][0]),
                    float(c["used_window_Hz"][1]),
                ]
            variant = (
                meta.get(
                    "metrics_active",
                    {}) or {}).get(
                "variant",
                None)
        except Exception as e:
            log.warning("Lecture JSON méta échouée (%s).", e)
    if ini_path.exists():
        try:
            cp = configparser.ConfigParser(
                inline_comment_prefixes=("#", ";"), interpolation=None
            )
            cp.read(ini_path)
            if "scan" in cp:
                s = cp["scan"]
                grid["fmin_Hz"] = s.getfloat("fmin", fallback=grid["fmin_Hz"])
                grid["fmax_Hz"] = s.getfloat("fmax", fallback=grid["fmax_Hz"])
                grid["dlog10"] = s.getfloat("dlog", fallback=grid["dlog10"])
        except Exception as e:
            log.warning("Lecture INI échouée (%s).", e)
    return grid, calib, variant


# ---------------- CLI
def parse_args():
    ap = argparse.ArgumentParser(
        description="Figure 01 — Overlay φ_ref vs φ_MCGT + inset résidu"
    )
    ap.add_argument("--csv", type=Path, default=DEF_IN)
    ap.add_argument("--meta", type=Path, default=DEF_META)
    ap.add_argument("--ini", type=Path, default=DEF_INI)
    ap.add_argument("--out", type=Path, default=DEF_OUT)
    ap.add_argument(
        "--display-variant",
        choices=["auto", "phi_mcgt", "phi_mcgt_cal", "phi_mcgt_raw"],
        default="auto",
        help="Variante affichée (auto: phi_mcgt > cal > raw)",
    )
    ap.add_argument(
        "--force-fit",
        action="store_true",
        help="Forcer un fit visuel même si variante *cal*",
    )
    ap.add_argument(
        "--shade",
        nargs=2,
        type=float,
        default=[
            20.0,
            300.0],
        metavar=(
            "F1",
            "F2") )
    ap.add_argument("--show-residual", action="store_true")
    ap.add_argument(
        "--anchor-policy",
        choices=["if-not-calibrated", "always", "never"],
        default="if-not-calibrated",
    )
    ap.add_argument("--dpi", type=int, default=300)
    ap.add_argument("--save-pdf", action="store_true")
    ap.add_argument(
        "--log-level",
        choices=[
            "DEBUG",
            "INFO",
            "WARNING",
            "ERROR"],
        default="INFO" )
    return apap.add_argument(
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
ap.add_argument(
    "--style",
    choices=[
        "paper",
        "talk",
        "mono",
        "none"],
    default=None,
    help="Thème MCGT commun (opt-in)").parse_args()


# ---------------- main
def main():
    args = parse_args()
    log = setup_logger(args.log_level)

    if not args.csv.exists():
        raise SystemExit(f"Introuvable : {args.csv}")
    df = pd.read_csv(args.csv)
    if "f_Hz" not in df.columns:
        raise SystemExit("Colonne manquante: f_Hz")

    # Sélection variante (priorité corrigée)
    cols = df.columns.tolist()
    disp = args.display_variant
    if disp == "auto":
        if "phi_mcgt" in cols:
            disp = "phi_mcgt"
        elif "phi_mcgt_cal" in cols:
            disp = "phi_mcgt_cal"
        elif "phi_mcgt_raw" in cols:
            disp = "phi_mcgt_raw"
        else:
            raise SystemExit("Aucune colonne phi_mcgt* trouvée.")
    if disp not in cols:
        raise SystemExit(f"Colonne {disp} introuvable. Colonnes={cols}")

    f_raw = df["f_Hz"].to_numpy(float)
    phi_ref_raw = (
        df["phi_ref"].to_numpy(float)
        if "phi_ref" in cols
        else np.full_like(f_raw, np.nan)
    )
    phi_mcg_raw = df[disp].to_numpy(float)

    grid, calib, variant_meta = load_meta_and_ini(args.meta, args.ini, log)
    log.info(
        "Calibration meta: enabled=%s, model=%s, window=%s",
        calib["enabled"],
        calib["model"],
        calib["window_Hz"],
    )

    # Tri et alignement
    f, arrs = enforce_monotone_freq(
        f_raw, {"ref": phi_ref_raw, "mcg": phi_mcg_raw}, log
    )
    ref = arrs["ref"]
    mcg = arrs["mcg"]

    # Unwrap de la ref pour rendu + masque plateau
    ref_u = np.unwrap(ref) if np.isfinite(ref).any() else ref
    ref_u, last_valid = mask_flat_tail(ref_u, min_run=3, atol=1e-12)
    if last_valid < ref_u.size - 1:
        log.info(
            "Plateau terminal φ_ref: masquage > f=%.3f Hz",
            float(
                f[last_valid]))

    # --- Rebranch canonique (k par médiane des cycles) ---
    f1, f2 = sorted(map(float, args.shade))
    mask_band = (f >= f1) & (f <= f2) & np.isfinite(ref) & np.isfinite(mcg)
    if not np.any(mask_band):
        raise SystemExit("Aucun point dans la bande métriques.")
    two_pi = 2.0 * np.pi
    k = int(np.round(np.nanmedian((mcg[mask_band] - ref[mask_band]) / two_pi)))
    log.info("k (médiane des cycles) = %d", k)

    mcg_rebran = (
        mcg - k * two_pi
    )  # appliqué aussi à l'affichage (clé de la superposition)

    # Rendu: unwrap pour lisser visuellement
    mcg_disp = np.unwrap(mcg_rebran) if np.isfinite(
        mcg_rebran).any() else mcg_rebran

    # Fit visuel (phi0, tc) uniquement si variante non calibrée (ou forcé)
    variant_is_cal = ("cal" in disp.lower()) or (
        variant_meta and "cal" in str(variant_meta).lower()
    )
    do_fit = (
        (args.anchor_policy == "always")
        or (args.anchor_policy == "if-not-calibrated" and (not variant_is_cal))
        or args.force_fit
    )
    if do_fit:
        # petit fit linéaire ref_u - mcg_disp ≈ dphi0 + 2π f dtc (poids 1/f²)
        m = mask_band & np.isfinite(ref_u) & np.isfinite(mcg_disp)
        if m.sum() >= 3:
            ff = f[m]
            y = ref_u[m] - mcg_disp[m]
            w = 1.0 / (ff**2)
            A = np.vstack([np.ones_like(ff), 2.0 * np.pi * ff]).T
            ATA = (A.T * w) @ A
            ATy = (A.T * w) @ y
            try:
                dphi0, dtc = np.linalg.solve(ATA, ATy)
                mcg_disp = mcg_disp + dphi0 + (2.0 * np.pi) * f * dtc
                log.info(
                    "Fit visuel: dphi0=%.3e rad, dtc=%.3e s",
                    float(dphi0),
                    float(dtc) )
            except np.linalg.LinAlgError:
                log.warning("Fit visuel instable, ignoré.")
        else:
            log.info("Pas assez de points pour fit visuel.")

    # --- Résidu & métriques (principal, après rebranch) ---
    dphi = principal_diff(mcg_rebran, ref)
    m2 = (f >= f1) & (f <= f2) & np.isfinite(dphi)
    mean_abs = float(np.nanmean(np.abs(dphi[m2])))
    p95_abs = float(p95(np.abs(dphi[m2])))
    max_abs = float(np.nanmax(np.abs(dphi[m2])))
    log.info(
        "|Δφ| %g–%g Hz (après rebranch k=%d): mean=%.3f ; p95=%.3f ; max=%.3f (n=%d)",
        f1,
        f2,
        k,
        mean_abs,
        p95_abs,
        max_abs,
        int(m2.sum()),
    )

    # ---------------- figure
    args.out.parent.mkdir(parents=True, exist_ok=True)
    fig = plt.figure(figsize=(11.8, 7.2))
    ax = fig.add_subplot(111)

    ax.plot(f, ref_u, lw=2.4, label=r"$\phi_{\rm ref}$ (IMRPhenomD)", zorder=3)
    ax.plot(
        f,
        mcg_disp,
        lw=1.8,
        ls="--",
        label=rf"$\phi_{{\rm MCGT}}$ (affichée: {disp}, rebranch k={k})",
        zorder=2,
    )

    ax.set_xscale("log")
    xmin = max(f1 / 5.0, float(np.nanmin(f)) * 0.98)
    xmax = float(np.nanmax(f))
    ax.set_xlim(xmin, xmax)
    ax.axvspan(f1, f2, color="0.90", alpha=0.6)
    ax.grid(True, which="both", ls=":", alpha=0.4)
    ax.set_xlabel("Fréquence $f$ [Hz]")
    ax.set_ylabel("Phase $\\phi$ [rad]")

    # Légende compacte
    legend_w = 0.50
    bbox = (1.0 - legend_w - 0.02, 0.54, legend_w, 0.42)
    cal_txt = f"Calage: {
        calib.get(
            'model',
            'phi0,tc')} (enabled={
            calib.get(
                'enabled',
                False)})"
    grid_txt = f"Grille: [{
        grid['fmin_Hz']:.0f}-{
        grid['fmax_Hz']:.0f}] Hz, dlog10={
            grid['dlog10']:.3f}"
    metrics_txt = f"|Δφ| {
        int(f1)}–{
        int(f2)} Hz (principal, k={k}): mean={
            mean_abs:.3f} rad ; p95={
                p95_abs:.3f} rad"
    handles, labels = ax.get_legend_handles_labels()
    extra = [
        Line2D([], [], color="none", label=cal_txt),
        Line2D([], [], color="none", label=grid_txt),
        Line2D([], [], color="none", label=metrics_txt),
    ]
    leg = ax.legend(
        handles + extra,
        labels + [cal_txt, grid_txt, metrics_txt],
        loc="upper left",
        bbox_to_anchor=bbox,
        frameon=True,
        framealpha=0.95,
    )
    for t in leg.get_texts():
        t.set_fontsize(9)

    # Inset résidu (log-log) — cohérent avec métriques
    if args.show_residual and np.isfinite(dphi).any():
        inset = ax.inset_axes([0.60, 0.07, 0.35, 0.32])
        absd = np.abs(dphi)
        eps = 1e-12
        absd = np.where(absd <= 0, eps, absd)
        inset.plot(f, absd, lw=1.1)
        inset.set_xscale("log")
        inset.set_yscale("log")
        inset.set_xlim(xmin, xmax)
        finite = absd[np.isfinite(absd)]
        if finite.size:
            ymin = max(eps, float(np.nanmin(finite[finite > 0])) * 0.9)
            ymax = float(np.nanmax(finite)) * 1.1
            inset.set_ylim(ymin, ymax)
        inset.set_title("Résidu principal $|\\Delta\\phi|$", fontsize=9)
        inset.grid(True, which="both", ls=":", alpha=0.3)
        inset.text(
            0.98,
            0.02,
            f"mean={
                mean_abs:.2f} rad\np95={
                p95_abs:.2f} rad\nmax={
                max_abs:.2f} rad",
            transform=inset.transAxes,
            va="bottom",
            ha="right",
            fontsize=8,
            bbox=dict(
                    boxstyle="round",
                    facecolor="white",
                    alpha=0.85),
                     )

    # Titre & marges
    ax.set_title(
        "Comparaison des phases $\\phi_{\\rm ref}$ vs $\\phi_{\\rm MCGT}$",
        fontsize=16,
        pad=18,
    )
    fig.tight_layout(rect=[0.035, 0.035, 0.985, 0.965])
    fig.savefig(
        args.out,
        dpi=int(
            args.dpi),
        bbox_inches="tight",
        pad_inches=0.03)
    if args.save_pdf:
        fig.savefig(args.out.with_suffix(".pdf"), dpi=int(args.dpi))
    log.info("Figure écrite → %s", str(args.out))


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
