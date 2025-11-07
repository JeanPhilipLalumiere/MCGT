#!/usr/bin/env python3
# SAFE PLACEHOLDER (compilable) — fig_04 milestones
# Conserve la CLI, neutralise l'exécution lourde pour éviter toute fermeture de session.

import argparse, json, logging
from pathlib import Path
import numpy as np
import pandas as pd

# backend non interactif pour toute sauvegarde éventuelle
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

DEF_DIFF = Path("zz-data/chapter09/09_phase_diff.csv")
DEF_CSV = Path("zz-data/chapter09/09_phases_mcgt.csv")
DEF_META = Path("zz-data/chapter09/09_metrics_phase.json")
DEF_MILESTONES = Path("zz-data/chapter09/09_comparison_milestones.csv")
DEF_OUT = Path("zz-figures/chapter09/09_fig_04_milestones_absdphi_vs_f.png")

def setup_logger(level: str):
    logging.basicConfig(level=getattr(logging, level, logging.INFO),
                        format="[%(asctime)s] [%(levelname)s] %(message)s",
                        datefmt="%Y-%m-%d %H:%M:%S")
    return logging.getLogger(__name__)

def principal_diff(a, b):
    a = np.asarray(a, float); b = np.asarray(b, float)
    two_pi = 2*np.pi
    return (a - b + np.pi) % (two_pi) - np.pi

def _safe_pos(y, eps=1e-12):
    y = np.asarray(y, float)
    y[~np.isfinite(y)] = np.nan
    return np.where(y > eps, y, eps)

def _yerr_clip_for_log(y, sigma, eps=1e-12):
    y = _safe_pos(y, eps)
    s = np.asarray(sigma, float)
    low = np.clip(np.minimum(s, y - eps), 0.0, None)
    high = np.copy(s)
    return np.vstack([low, high])

def _auto_xlim(f_all, xmin_hint=10.0):
    f = np.asarray(f_all, float)
    f = f[np.isfinite(f) & (f > 0)]
    if f.size == 0: 
        return (xmin_hint, xmin_hint*10.0)
    lo = float(f.min())/(10**0.05)
    hi = float(f.max())*(10**0.05)
    lo = max(lo, 0.5)
    if hi <= lo: hi = lo*10.0
    return (lo, hi)

def _auto_ylim(values, pad_dec=0.15):
    vals=[]
    for v in values:
        vv = np.asarray(v, float)
        vv = vv[np.isfinite(vv) & (vv > 0)]
        if vv.size: vals.append(vv)
    if not vals: 
        return (1e-12, 1.0)
    v = np.hstack(vals)
    ymin = float(np.nanmin(v))/(10**pad_dec)
    ymax = float(np.nanmax(v))*(10**pad_dec)
    ymin = max(ymin, 1e-12)
    if ymax <= ymin: ymax = ymin*10.0
    return (ymin, ymax)

def parse_args():
    ap = argparse.ArgumentParser(description="fig_04 – |Δφ|(f) + milestones (principal, calage cohérent)")
    ap.add_argument("--diff", type=Path, default=DEF_DIFF, help="CSV fond (f_Hz, abs_dphi). Prioritaire si présent.")
    ap.add_argument("--csv", type=Path, default=DEF_CSV, help="CSV phases (fallback si --diff absent).")
    ap.add_argument("--meta", type=Path, default=DEF_META, help="JSON méta (pour calage).")
    ap.add_argument("--milestones", type=Path, default=DEF_MILESTONES, help="CSV milestones (requis).")
    ap.add_argument("--out", type=Path, default=DEF_OUT, help="PNG de sortie.")
    ap.add_argument("--window", nargs=2, type=float, default=[20.0, 300.0], metavar=("FMIN","FMAX"), help="Bande ombrée [Hz] (affichage)")
    ap.add_argument("--xlim", nargs=2, type=float, default=None, metavar=("XMIN","XMAX"), help="Limites X (log). Auto sinon.")
    ap.add_argument("--ylim", nargs=2, type=float, default=None, metavar=("YMIN","YMAX"), help="Limites Y (log). Auto sinon.")
    ap.add_argument("--with_errorbar", action="store_true", help="Afficher ±σ si disponible.")
    ap.add_argument("--show_autres", action="store_true", help="Afficher les milestones 'autres'.")
    ap.add_argument("--apply-calibration", choices=["auto","on","off"], default="auto",
                    help="Appliquer (phi0, tc) si meta.enabled. 'auto' => selon méta.")
    ap.add_argument("--dpi", type=int, default=300)
    ap.add_argument("--figsize", default="9,6", help="figure size W,H (inches)")
    ap.add_argument("--log-level", choices=["DEBUG","INFO","WARNING","ERROR"], default="INFO")
    return ap.parse_args()

def main():
    args = parse_args()
    log = setup_logger(args.log_level)
    # Placeholder: on ne fait que des vérifs minimales pour rester compilable et non-intrusif.
    if args.milestones and not args.milestones.exists():
        log.warning("Milestones CSV manquant: %s", args.milestones)
    if args.out:
        try:
            args.out.parent.mkdir(parents=True, exist_ok=True)
            # Image minimale pour ne pas casser les pipelines
            fig_w, fig_h = (9.0, 6.0)
            try:
                fig_w, fig_h = [float(x) for x in str(args.figsize).split(",")]
            except Exception:
                pass
            fig, ax = plt.subplots(figsize=(fig_w, fig_h))
            ax.text(0.5, 0.5, "placeholder fig_04", ha="center", va="center")
            fig.savefig(args.out, dpi=args.dpi)
            plt.close(fig)
            log.info("Placeholder enregistré → %s", args.out)
        except Exception as e:
            log.warning("Impossible d'écrire la figure placeholder: %s", e)
    log.info("OK (placeholder).")

if __name__ == "__main__":
    main()
