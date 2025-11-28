#!/usr/bin/env python3
"""
plot_fig05_scatter_phi_at_fpeak.py
Fig. 05 - Comparaison ponctuelle aux f_peak : φ_ref vs φ_MCGT (±σ)

Entrée (obligatoire)
- zz-data/chapter09/09_comparison_milestones.csv

Colonnes attendues (au minimum) :
- phi_ref_at_fpeak
- phi_mcgt_at_fpeak

Colonnes optionnelles (fortement recommandées si disponibles) :
- sigma_phase
- classe
- event
- f_Hz

Sorties
-------
- PNG (par défaut) : zz-figures/chapter09/09_fig_05_scatter_phi_at_fpeak.png
- PDF optionnel (--pdf)

Points clés
-----------
- Nuage φ_MCGT(f_peak) vs φ_ref(f_peak) avec diagonale y = x.
- Par défaut, alignement "principal" :
      y' = y − 2π * round((y − x)/(2π))
  Les points sont ramenés visuellement dans une bande ±π autour de la diagonale.
- Légende par classes : "primaire", "ordre2", "autres".
- Barres d'erreur : si sigma_phase est présent et fini → yerr = sigma_phase.

Exemple
-------
python zz-scripts/chapter09/plot_fig05_scatter_phi_at_fpeak.py \
  --milestones zz-data/chapter09/09_comparison_milestones.csv \
  --out zz-figures/chapter09/09_fig_05_scatter_phi_at_fpeak.png \
  --dpi 300 --log-level INFO --pdf

# Pour désactiver l’alignement principal (montrer valeurs brutes) :
#   --align none
"""

from __future__ import annotations

import argparse
import logging
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd


# ---------- Defaults ----------
DEF_MILESTONES = Path("zz-data/chapter09/09_comparison_milestones.csv")
DEF_OUT = Path("zz-figures/chapter09/09_fig_05_scatter_phi_at_fpeak.png")


# ---------- Utils ----------
def setup_logger(level: str) -> logging.Logger:
    lvl = getattr(logging, level.upper(), logging.INFO)
    logging.basicConfig(
        level=lvl,
        format="[%(asctime)s] [%(levelname)s] %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )
    return logging.getLogger("fig05_scatter_fpeak")


def principal_align(y: np.ndarray, x: np.ndarray) -> np.ndarray:
    """Aligne y sur x modulo 2π : y' = y - 2π * round((y-x)/(2π))."""
    y = np.asarray(y, float)
    x = np.asarray(x, float)
    return y - 2.0 * np.pi * np.round((y - x) / (2.0 * np.pi))


def class_color_map() -> dict[str, str]:
    return {"primaire": "C0", "ordre2": "C1", "autres": "C2"}


def normalize_class(c) -> str:
    if c is None:
        return "autres"
    t = str(c).lower().strip().replace(" ", "").replace("-", "")
    if t in {"primaire", "primary"}:
        return "primaire"
    if t in {"ordre2", "order2", "ordredeux"}:
        return "ordre2"
    return "autres"


def finite_mask(*arrs) -> np.ndarray:
    """Masque de finitude commun à plusieurs tableaux."""
    base = np.asarray(arrs[0], float)
    m = np.ones_like(base, dtype=bool)
    for a in arrs:
        aa = np.asarray(a, float)
        m &= np.isfinite(aa)
    return m


def robust_stats(residual: np.ndarray) -> tuple[float, float, float, float, int]:
    """mean, median, p95, max, N sur |résidu|."""
    a = np.asarray(residual, float)
    a = a[np.isfinite(a)]
    if a.size == 0:
        return (np.nan, np.nan, np.nan, np.nan, 0)
    mean = float(np.nanmean(a))
    med = float(np.nanmedian(a))
    p95 = float(np.nanpercentile(a, 95.0))
    mx = float(np.nanmax(a))
    return (mean, med, p95, mx, a.size)


def parse_args() -> argparse.Namespace:
    ap = argparse.ArgumentParser(
        description="Fig.05 — φ_ref vs φ_MCGT aux f_peak (±σ)"
    )
    ap.add_argument(
        "--milestones",
        type=Path,
        default=DEF_MILESTONES,
        help="CSV milestones (phi_ref_at_fpeak, phi_mcgt_at_fpeak, ...)",
    )
    ap.add_argument(
        "--out",
        type=Path,
        default=DEF_OUT,
        help="Image de sortie (PNG, par défaut).",
    )
    ap.add_argument(
        "--pdf",
        action="store_true",
        help="Écrire aussi un PDF à côté du PNG.",
    )
    ap.add_argument(
        "--align",
        choices=["principal", "none"],
        default="principal",
        help="Alignement visuel de y sur x modulo 2π (défaut=principal).",
    )
    ap.add_argument(
        "--dpi",
        type=int,
        default=300,
        help="DPI de la figure.",
    )
    ap.add_argument(
        "--log-level",
        choices=["DEBUG", "INFO", "WARNING", "ERROR"],
        default="INFO",
    )
    return ap.parse_args()


# ---------- Main ----------
def main() -> None:
    args = parse_args()
    log = setup_logger(args.log_level)

    if not args.milestones.exists():
        raise SystemExit(f"Fichier introuvable : {args.milestones}")

    ms = pd.read_csv(args.milestones)

    need = {"phi_ref_at_fpeak", "phi_mcgt_at_fpeak"}
    if not need.issubset(ms.columns):
        raise SystemExit(f"{args.milestones} doit contenir au minimum les colonnes {need}")

    # Colonnes principales
    x = ms["phi_ref_at_fpeak"].to_numpy(float)
    y = ms["phi_mcgt_at_fpeak"].to_numpy(float)

    # Classes (optionnelles)
    if "classe" in ms.columns:
        cls_raw = ms["classe"]
    else:
        cls_raw = pd.Series(["autres"] * len(ms), index=ms.index)
    cls = np.array([normalize_class(c) for c in cls_raw], dtype=object)

    # Barres d'erreur (optionnelles)
    sigma = None
    if "sigma_phase" in ms.columns:
        sigma = ms["sigma_phase"].to_numpy(float)

    # Filtre de finitude
    masks_for_finite = [x, y]
    if sigma is not None:
        masks_for_finite.append(sigma)
    m_fin = finite_mask(*masks_for_finite)
    n_drop = int((~m_fin).sum())
    if n_drop:
        log.warning("Lignes ignorées (valeurs non finies) : %d", n_drop)

    x = x[m_fin]
    y = y[m_fin]
    cls = cls[m_fin]
    if sigma is not None:
        sigma = sigma[m_fin]

    if x.size == 0:
        raise SystemExit("Aucune ligne exploitable après filtrage.")

    # Alignement visuel (pour la position des points)
    if args.align == "principal":
        y_al = principal_align(y, x)
        log.info("Alignement 'principal' activé (modulo 2π).")
    else:
        y_al = y.copy()
        log.info("Alignement désactivé (valeurs brutes).")

    # Résidu principal pour les métriques
    res_principal = (y - x + np.pi) % (2.0 * np.pi) - np.pi
    abs_res = np.abs(res_principal)
    mean_abs, med_abs, p95_abs, max_abs, n_eff = robust_stats(abs_res)
    log.info(
        "Métriques |Δφ|_principal : mean=%.3f  median=%.3f  p95=%.3f  max=%.3f  (N=%d)",
        mean_abs,
        med_abs,
        p95_abs,
        max_abs,
        n_eff,
    )

    # Figure
    args.out.parent.mkdir(parents=True, exist_ok=True)
    fig, ax = plt.subplots(figsize=(7.8, 7.6), dpi=args.dpi)

    fig.suptitle(
        r"Comparaison ponctuelle aux $f_{\rm peak}$ : "
        r"$\phi_{\rm ref}$ vs $\phi_{\rm MCGT}$",
        fontsize=18,
        fontweight="semibold",
        y=0.97,
    )
    fig.subplots_adjust(top=0.90, bottom=0.10, left=0.12, right=0.98)

    # Couleurs / classes
    cmap = class_color_map()
    masks = {
        "primaire": (cls == "primaire"),
        "ordre2": (cls == "ordre2"),
        "autres": (cls == "autres"),
    }

    # Limites (après alignement visuel si activé)
    mn = float(np.nanmin([np.nanmin(x), np.nanmin(y_al)]))
    mx = float(np.nanmax([np.nanmax(x), np.nanmax(y_al)]))
    if mx <= mn:
        pad = 1.0
    else:
        pad = 0.05 * (mx - mn)
    lo, hi = mn - pad, mx + pad

    # Diagonale y = x
    ax.plot(
        [lo, hi],
        [lo, hi],
        ls="--",
        lw=1.2,
        color="0.5",
        label="y = x",
        zorder=1,
    )

    # Tracé par classes (avec barres d'erreur si disponibles)
    for name, m in masks.items():
        if not np.any(m):
            continue
        color = cmap[name]
        xg = x[m]
        yg = y_al[m]

        if sigma is not None:
            sg = sigma[m]
            yerr = np.where(np.isfinite(sg) & (sg > 0), sg, np.nan)
            if np.any(np.isfinite(yerr)):
                ax.errorbar(
                    xg,
                    yg,
                    yerr=yerr,
                    fmt="o",
                    ms=4.0,
                    capsize=3.0,
                    elinewidth=0.9,
                    alpha=0.85,
                    color=color,
                    label=name,
                    zorder=3,
                )
            else:
                ax.scatter(
                    xg,
                    yg,
                    s=28,
                    color=color,
                    edgecolor="k",
                    linewidth=0.4,
                    alpha=0.85,
                    label=name,
                    zorder=3,
                )
        else:
            ax.scatter(
                xg,
                yg,
                s=28,
                color=color,
                edgecolor="k",
                linewidth=0.4,
                alpha=0.85,
                label=name,
                zorder=3,
            )

    ax.set_xlim(lo, hi)
    ax.set_ylim(lo, hi)
    ax.set_xlabel(r"$\phi_{\rm ref}(f_{\rm peak})$  [rad]")
    ax.set_ylabel(r"$\phi_{\rm MCGT}(f_{\rm peak})$  [rad]")
    ax.grid(True, ls=":", alpha=0.4)

    # Légende
    ax.legend(loc="best", frameon=True, framealpha=0.9)

    # Encadré métriques
    text_metrics = (
        r"$|\Delta\phi_{\rm principal}|$ [rad]" + "\n"
        + f"mean   = {mean_abs:.3f}\n"
        + f"median = {med_abs:.3f}\n"
        + f"p95    = {p95_abs:.3f}\n"
        + f"max    = {max_abs:.3f}\n"
        + f"N      = {n_eff:d}"
    )
    ax.text(
        0.02,
        0.03,
        text_metrics,
        transform=ax.transAxes,
        ha="left",
        va="bottom",
        fontsize=10.5,
        bbox=dict(boxstyle="round,pad=0.3", facecolor="white", alpha=0.85),
    )

    # Sauvegarde
    fig.savefig(args.out, dpi=args.dpi)
    log.info("Figure PNG enregistrée → %s", args.out)
    if args.pdf:
        pdf_path = args.out.with_suffix(".pdf")
        fig.savefig(pdf_path, dpi=args.dpi)
        log.info("Figure PDF enregistrée → %s", pdf_path)


if __name__ == "__main__":
    main()
