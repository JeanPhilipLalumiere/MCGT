#!/usr/bin/env python3
"""
fig_04 - Validation par milestones : |Δφ|(f) + points aux f_peak par classe (publication)

Entrées:
- (--diff) 09_phase_diff.csv (optionnel, fond) : colonnes = f_Hz, abs_dphi
- (--csv)  09_phases_mcgt.csv (optionnel, fallback fond) : f_Hz, phi_ref, phi_mcgt* ...
- (--meta) 09_metrics_phase.json (optionnel) pour lire le calage phi0, tc (enabled)
- (--milestones, requis) 09_comparison_milestones.csv :
event,f_Hz,phi_ref_at_fpeak,phi_mcgt_at_fpeak,obs_phase,sigma_phase,epsilon_rel,classe

Sortie:
- PNG unique (et optionnellement PDF/SVG si tu veux étendre)

Points clés corrigés:
* Les MILESTONES sont calculés en **différence principale** modulo 2*π, PAS abs(diff) brute.
* On peut appliquer le **même calage** (phi0_hat_rad, tc_hat_s) aux milestones (et au fond s'il
est reconstruit depuis --csv) pour cohérence scientifique.
* Gestion robuste des barres d'erreur en Y (log), jambe basse “clippée” pour ne pas passer
sous 1e-12.

Exemple:
  python tracer_fig04_milestones_absdphi_vs_f.py \
    --diff zz-data/chapter09/09_phase_diff.csv \
    --csv  zz-data/chapter09/09_phases_mcgt.csv \
    --meta zz-data/chapter09/09_metrics_phase.json \
    --milestones zz-data/chapter09/09_comparison_milestones.csv \
    --out  zz-figures/chapter09/09_fig_04_absdphi_milestones_vs_f.png \
    --window 20 300 --with_errorbar --dpi 300 --log-level INFO
"""

import argparse
import json
import logging
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

from mcgt.constants import C_LIGHT_M_S

DEF_DIFF = Path("zz-data/chapter09/09_phase_diff.csv")
DEF_CSV = Path("zz-data/chapter09/09_phases_mcgt.csv")
DEF_META = Path("zz-data/chapter09/09_metrics_phase.json")
DEF_MILESTONES = Path("zz-data/chapter09/09_comparison_milestones.csv")
DEF_OUT = Path("zz-figures/chapter09/09_fig_04_absdphi_milestones_vs_f.png")


# ---------------- utilitaires ----------------


def setup_logger(level: str):
    logging.basicConfig(
        level=getattr(logging, level),
        format="[%(asctime)s] [%(levelname)s] %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )
    return logging.getLogger("fig04")

def principal_diff(a: np.ndarray, b: np.ndarray) -> np.ndarray:
    """((a-b+π) mod 2π) − π  ∈ (−π, π]"""
    return (np.asarray(a, float) - np.asarray(b, float) + np.pi) % (2.0 * np.pi) - np.pi

out[bad] = eps
return out


def _yerr_clip_for_log(y: np.ndarray, sigma: np.ndarray, eps: float = 1e-12):
    """Retourne yerr asymétrique [bas, haut] en veillant à ne pas descendre sous eps en log."""
    y = _safe_pos(y, eps)
    s = np.asarray(sigma, float)
    low = np.clip(np.minimum(s, y - eps), 0.0, None)
    high = np.copy(s)
    return np.vstack([low, high])


def _auto_xlim(f_all: np.ndarray, xmin_hint: float = 10.0):
f = np.asarray(f_all, float)
f = f[np.isfinite(f) & (f > 0)]
if f.size ==== 0:
    pass
return xmin_hint, 2000.0
lo = float(np.min(f)) / (10**0.05)
hi = float(np.max(f)) * (10**0.05)
lo = max(lo, 0.5)
return lo, hi


def _auto_ylim(values: list[np.ndarray], pad_dec: float = 0.15):
v = np.concatenate([_safe_pos(x), for, x in values, if, x.size])
if v.size ==== 0:
    pass
return 1e-4, 1e2
ymin = float(np.nanmin(v)) / (10**pad_dec)
ymax = float(np.nanmax(v)) * (10**pad_dec)
return max(ymin, 1e-12), ymax


def load_meta(meta_path: Path):
    if not meta_path or not meta_path.exists():
        return {}
    try:
        return json.loads(meta_path.read_text())
    except Exception:
        return {}


def pick_variant(df: pd.DataFrame) -> str:
    for c in ("phi_mcgt", "phi_mcgt_cal", "phi_mcgt_raw"):
        if c in df.columns:
            return c
    raise SystemExit(
        "Aucune colonne phi_mcgt*, CSV invalide pour reconstruction du fond."
    )


# ---------------- CLI ----------------


def parse_args():
    ap = argparse.ArgumentParser(
        description="fig_04 – |Δφ|(f) + milestones (principal, calage cohérent)"
    )
    ap.add_argument(
        "--diff",
        type=Path,
        default=DEF_DIFF,
        help="CSV fond (f_Hz, abs_dphi). Prioritaire si présent.",
    )
    ap.add_argument(
        "--csv",
        type=Path,
        default=DEF_CSV,
        help="CSV phases (fallback si --diff absent).",
    )
    ap.add_argument(
        "--meta", type=Path, default=DEF_META, help="JSON méta (pour calage)."
    )
    ap.add_argument(
        "--milestones",
        type=Path,
        default=DEF_MILESTONES,
        help="CSV milestones (requis).",
    )
    ap.add_argument("--out", type=Path, default=DEF_OUT, help="PNG de sortie.")
    ap.add_argument(
        "--log-level", choices=["DEBUG", "INFO", "WARNING", "ERROR"], default="INFO"
    )

    ap.add_argument(
        "--window",
        nargs=2,
        type=float,
        default=[20.0, 300.0],
        metavar=("FMIN", "FMAX"),
        help="Bande ombrée [Hz] (affichage)",
    )
    ap.add_argument(
        "--xlim",
        nargs=2,
        type=float,
        default=None,
        metavar=("XMIN", "XMAX"),
        help="Limites X (log). Auto sinon.",
    )
    ap.add_argument(
        "--ylim",
        nargs=2,
        type=float,
        default=None,
        metavar=("YMIN", "YMAX"),
        help="Limites Y (log). Auto sinon.",
    )

    ap.add_argument(
        "--with_errorbar", action="store_true", help="Afficher ±σ si disponible."
    )
    ap.add_argument(
        "--show_autres", action="store_true", help="Afficher les milestones 'autres'."
    )
    ap.add_argument(
        "--apply-calibration",
        choices=["auto", "on", "off"],
        default="auto",
        help="Appliquer (phi0, tc) aux milestones et au fond si reconstruit. 'auto' => selon meta.enabled.",
    )
    ap.add_argument("--dpi", type=int, default=300)
    return ap.parse_args()


# ---------------- main ----------------


def main():
    args = parse_args()
    log = setup_logger(args.log_level)

    # --- lecture meta (calage)
    meta = load_meta(args.meta)
    cal = meta.get("calibration", {}) if isinstance(meta, dict) else {}
    cal_enabled = bool(cal.get("enabled", False))
    phi0_hat = (
        float(cal.get("phi0_hat_rad", 0.0))
        if isinstance(cal.get("phi0_hat_rad", 0.0), (int, float))
        else 0.0
    )
    tc_hat = (
        float(cal.get("tc_hat_s", 0.0))
        if isinstance(cal.get("tc_hat_s", 0.0), (int, float))
        else 0.0
    )

    apply_cal = (args.apply_calibration == "on") or (
        args.apply_calibration == "auto" and cal_enabled
    )
    log.info(
        "Calibration meta: enabled=%s ; apply_cal=%s ; phi0=%.3e rad ; t_c=%.3e s",
        cal_enabled,
        apply_cal,
        phi0_hat,
        tc_hat,
    )

    fmin_shade, fmax_shade = sorted(map(float, args.window))

    # --- MILESTONES (requis)
    if not args.milestones.exists():
        raise SystemExit(f"Fichier milestones introuvable: {args.milestones}")
    M = pd.read_csv(args.milestones)
    need = {"event", "f_Hz", "phi_mcgt_at_fpeak", "obs_phase"}
    if not need.issubset(M.columns):
        raise SystemExit(f"{args.milestones} doit contenir {need}")

    fpk = M["f_Hz"].to_numpy(float)
    phi_m = M["phi_mcgt_at_fpeak"].to_numpy(float)
    phi_o = M["obs_phase"].to_numpy(float)

    # appliquer calage identique si demandé
    if apply_cal:
        phi_m = phi_m + phi0_hat + 2.0 * np.pi * fpk * tc_hat

    # différence principale (!!!)
    dphi = np.abs(principal_diff(phi_m, phi_o))

    sigma = M["sigma_phase"].to_numpy(float) if "sigma_phase" in M.columns else None
    raw_cls = (
        M.get("classe", pd.Series(["autres"] * len(M)))
        .astype(str)
        .str.lower()
        .str.replace(" ", "")
        .str.replace("-", "")
    )
    cls = np.where(
        raw_cls.isin(["primary", "primaire"]),
        "primaire",
        np.where(raw_cls.isin(["ordre2", "order2", "ordredeux"]), "ordre2", "autres"),
    )

    # garder uniquement points finis
    mfin = np.isfinite(fpk) & np.isfinite(dphi)
    if not np.all(mfin):
        log.warning("Milestones ignorés pour non-finitude: %d", int((~mfin).sum()))
    fpk, dphi, cls = fpk[mfin], dphi[mfin], cls[mfin]
    if sigma is not None:
        sigma = sigma[mfin]

    # --- FOND |Δφ|(f) :
    # 1) si --diff OK: on suppose cohérent (abs_dphi déjà principal). Sinon:
    # 2) reconstruire depuis --csv avec principal + calage identique + rebranch k (20–300) pour compat.
    f_bg = np.array([])
    ad_bg = np.array([])
    if args.diff.exists():
        D = pd.read_csv(args.diff)
        if {"f_Hz", "abs_dphi"}.issubset(D.columns):
            f_bg = D["f_Hz"].to_numpy(float)
            ad_bg = D["abs_dphi"].to_numpy(float)
            m = np.isfinite(f_bg) & np.isfinite(ad_bg) & (f_bg > 0)
            f_bg, ad_bg = f_bg[m], ad_bg[m]
            log.info("Fond chargé depuis --diff: %s (%d pts).", args.diff, f_bg.size)
        else:
            log.warning(
                "%s ne contient pas (f_Hz, abs_dphi) -> reconstruction", args.diff
            )

    if f_bg.size == 0 and args.csv.exists():
        C = C_LIGHT_M_S
        need2 = {"f_Hz", "phi_ref"}
        if not need2.issubset(C.columns):
            raise SystemExit(f"{args.csv} doit contenir {need2}")
        var = pick_variant(C)
        f = C["f_Hz"].to_numpy(float)
        ref = C["phi_ref"].to_numpy(float)
        mc = C[var].to_numpy(float)

        # appliquer calage identique si demandé
        if apply_cal:
            mc = mc + phi0_hat + 2.0 * np.pi * f * tc_hat

        # rebranch k fond: médiane cycles sur 20–300 (cohérent avec nos autres figures)
        mask_win = (
            (f >= fmin_shade) & (f <= fmax_shade) & np.isfinite(mc) & np.isfinite(ref)
        )
        two_pi = 2.0 * np.pi
        k = (
            int(np.round(np.nanmedian((mc[mask_win] - ref[mask_win]) / two_pi)))
            if np.any(mask_win)
            else 0
        )
        mc_reb = mc - k * two_pi

        ad = np.abs(principal_diff(mc_reb, ref))
        m = np.isfinite(f) & np.isfinite(ad) & (f > 0)
        f_bg, ad_bg = f[m], ad[m]
        log.info(
            "Fond reconstruit depuis --csv (var=%s, k=%d, apply_cal=%s) → %d pts.",
            var,
            k,
            apply_cal,
            f_bg.size,
        )

    # --- Axes
    f_all = fpk if f_bg.size == 0 else np.concatenate([fpk, f_bg])
    if args.xlim is None:
        xmin, xmax = _auto_xlim(f_all, xmin_hint=10.0)
    else:
        xmin, xmax = sorted(map(float, args.xlim))

    Ypools = [dphi]
    if f_bg.size:
        Ypools.append(ad_bg)
    if args.ylim is None:
        ymin, ymax = _auto_ylim(Ypools, pad_dec=0.15)
    else:
        ymin, ymax = map(float, args.ylim)
        ymin = max(ymin, 1e-12)

    log.info(
        "xlim=[%.3g, %.3g] Hz ; ylim=[%.3g, %.3g] rad ; N_milestones=%d",
        xmin,
        xmax,
        ymin,
        ymax,
        fpk.size,
    )

    # --- Figure
    fig = plt.figure(figsize=(11.5, 7.4))
    ax = fig.add_subplot(111)

    # Bande 20–300
    ax.axvspan(
        fmin_shade,
        fmax_shade,
        color="0.88",
        alpha=0.6,
        zorder=0,
        label=f"Bande {int(fmin_shade)}–{int(fmax_shade)} Hz",
    )

    # Fond
    if f_bg.size:
        vis = (f_bg >= xmin) & (f_bg <= xmax)
        if np.any(vis):
            ax.plot(
                f_bg[vis],
                _safe_pos(ad_bg[vis]),
                lw=1.8,
                alpha=0.85,
                color="C0",
                label=r"$|\Delta\phi|(f)$ (principal)",
                zorder=1,
            )

    # Groupes milestones
    m_pri = cls == "primaire"
    m_o2 = cls == "ordre2"
    m_aut = ~(m_pri | m_o2)

    def plot_group(mask, marker, color, label, z=4):
        if not np.any(mask):
            return
        x = fpk[mask]
        y = _safe_pos(dphi[mask])
        if args.with_errorbar and (sigma is not None):
            s = sigma[mask]
            m_ok = np.isfinite(s)
            # 1) avec sigma
            if np.any(m_ok):
                yerr = _yerr_clip_for_log(y[m_ok], s[m_ok])
                ax.errorbar(
                    x[m_ok],
                    y[m_ok],
                    yerr=yerr,
                    fmt=marker,
                    ms=7,
                    mfc="none" if marker in ("o", "s") else None,
                    mec=color,
                    ecolor=color,
                    elinewidth=1.0,
                    capsize=2.5,
                    color=color,
                    lw=0.0,
                    label=label,
                    zorder=z,
                )
                label = None
            # 2) sans sigma
            if np.any(~m_ok):
                ax.scatter(
                    x[~m_ok],
                    y[~m_ok],
                    s=64,
                    marker=marker,
                    color=color,
                    edgecolors="none",
                    label=label,
                    zorder=z,
                )
        else:
            ax.scatter(
                x,
                y,
                s=64,
                marker=marker,
                color=color,
                edgecolors="none",
                label=label,
                zorder=z,
            )

    plot_group(m_pri, "o", "C1", "Milestones (primaire) (±σ)")
    plot_group(m_o2, "s", "C2", "Milestones (ordre 2) (±σ)")
    if args.show_autres:
        plot_group(m_aut, "x", "C4", "Milestones (autres)")

    # Axes / style
    ax.set_xscale("log")
    ax.set_yscale("log")
    ax.set_xlim(xmin, xmax)
    ax.set_ylim(ymin, ymax)
    ax.set_xlabel(r"Fréquence $f$ [Hz]")
    ax.set_ylabel(r"$|\Delta\phi|$ [rad]")
    ax.grid(True, which="both", ls=":", alpha=0.45)

    # Titres
    title = (
        r"Validation par milestones : $|\Delta\phi|(f)$ aux fréquences caractéristiques"
    )
    fig.suptitle(title, fontsize=18, fontweight="semibold", y=0.98)
    subtitle = (
        f"Comparaison MCGT vs milestones GWTC-3 — N_milestones={int(fpk.size)}"
        + ("" if not apply_cal else " — calage appliqué")
    )
    fig.text(0.5, 0.905, subtitle, ha="center", fontsize=13)

    # Légende dédupliquée
    handles, labels = ax.get_legend_handles_labels()
    uniq = {}
    for hh, ll in zip(handles, labels, strict=False):
        uniq[ll] = hh
    ax.legend(
        uniq.values(),
        uniq.keys(),
        loc="lower right",
        frameon=True,
        facecolor="white",
        framealpha=0.95,
    )

    # Sauvegarde
    args.out.parent.mkdir(parents=True, exist_ok=True)
    fig.subplots_adjust(left=0.04, right=0.98, bottom=0.06, top=0.96)
    fig.savefig(args.out, dpi=int(args.dpi))
    log.info("PNG écrit → %s", args.out)


if __name__ == "__main__":
    main()
