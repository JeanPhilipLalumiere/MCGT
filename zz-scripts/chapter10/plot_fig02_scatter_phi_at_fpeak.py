#!/usr/bin/env python3
"""
plot_fig02_scatter_phi_at_fpeak

Nuage de points comparant phi_ref(f_peak) vs phi_MCGT(f_peak).
- Différence circulaire Δφ = wrap(φ_MCGT - φ_ref) dans [-π, π)
- Couleur = |Δφ|
- Hexbin de fond optionnel (+ scatter alpha)
- Colorbar avec ticks explicites (0, π/4, π/2, 3π/4, π)
- Statistiques incluant IC bootstrap (95%) de la moyenne circulaire de Δφ
- Export PNG (DPI au choix)

Exemple d’usage (recommandé) à la fin du fichier.
"""

from __future__ import annotations

import argparse

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

# ------------------------- Utils (diff & stats circulaires) -------------

TWOPI = 2.0 * np.pi


def wrap_pi(x: np.ndarray) -> np.ndarray:
    """Réduit sur l'intervalle [-π, π)."""
    return (x + np.pi) % TWOPI - np.pi


def circ_diff(a: np.ndarray, b: np.ndarray) -> np.ndarray:
    """Δφ = wrap( b - a ) dans [-π, π)."""
    return wrap_pi(b - a)


def circ_mean_rad(angles: np.ndarray) -> float:
    """Moyenne circulaire (angle) en radians [-π, π)."""
    z = np.mean(np.exp(1j * angles))
    return float(np.angle(z))


def circ_std_rad(angles: np.ndarray) -> float:
    """Écart-type circulaire (radians). Définition basée sur R = |E[e^{iθ}]|."""
    R = np.abs(np.mean(np.exp(1j * angles)))
    # std circulaire : sqrt(-2 ln R)
    return float(np.sqrt(max(0.0, -2.0 * np.log(max(R, 1e-12)))))


def bootstrap_circ_mean_ci(
    angles: np.ndarray, B: int = 1000, seed: int = 12345
) -> tuple[float, float, float]:
    """
    IC bootstrap (percentile, 95%) pour la moyenne circulaire de `angles`.

    Technique: calcule la moyenne circulaire θ̂. Pour chaque bootstrap, calcule θ_b.
    Étant sur un cercle, on centre puis "wrap" : Δ_b = wrap(θ_b - θ̂).
    On prend les percentiles 2.5% et 97.5% de Δ_b, puis on réapplique autour de θ̂.

    Retourne: (theta_hat, ci_low, ci_high) en radians dans [-π, π).
    """
    n = len(angles)
    if n == 0 or B <= 0:
        th = circ_mean_rad(angles)
        return th, th, th

    rng = np.random.default_rng(seed)
    theta_hat = circ_mean_rad(angles)
    deltas = np.empty(B, dtype=float)

    for b in range(B):
        idx = rng.integers(0, n, size=n)
        th_b = circ_mean_rad(angles[idx])
        deltas[b] = wrap_pi(th_b - theta_hat)

    lo = np.percentile(deltas, 2.5)
    hi = np.percentile(deltas, 97.5)
    ci_low = wrap_pi(theta_hat + lo)
    ci_high = wrap_pi(theta_hat + hi)
    return theta_hat, ci_low, ci_high


# ------------------------- Parsing & plotting -------------------------


def detect_column(
    df: pd.DataFrame,
    hint: str | None,
    candidates: list[str]) -> str:
    if hint and hint in df.columns:
        return hint
    for c in candidates:
        if c in df.columns:
            return c
    # fallback: recherche par sous-chaîne
    lowcols = [c.lower() for c in df.columns]
    for cand in candidates:
        if cand.lower() in lowcols:
            return df.columns[lowcols.index(cand.lower())]
    raise KeyError(
        f"Aucune colonne trouvée parmi : {candidates} (ou hint={hint})")


def main():
    p = argparse.ArgumentParser(
    p.add_argument(
        required=True,
    p.add_argument(
    p.add_argument(
    p.add_argument(
    p.add_argument(
    p.add_argument(
    p.add_argument("--dpi", type=int, default=300, help="DPI PNG")
    p.add_argument(
    )
    p.add_argument(
        type=float,
    p.add_argument(
        "--alpha", type=float, default=0.7, help="Alpha des points du scatter"
    )
    p.add_argument("--cmap", default="viridis", help="Colormap pour |Δφ|")

    # options de clipping / échelle
    p.add_argument(
        action="store_true",
    )
    p.add_argument(
        type=float,
    )
    p.add_argument(
        type=int,
    )

    # HEXBIN
    p.add_argument( "--with-hexbin", action="store_true",
    p.add_argument(
        type=int,
    p.add_argument(
        type=float,

    # Colorbar ticks π/4
    p.add_argument(
        action="store_true",
    )

    # Bootstrap IC sur la moyenne circulaire
    p.add_argument(
        type=int,
    )
    p.add_argument(
        type=int,

    p.add_argument('--style', choices=['paper','talk','mono','none'], default='none', help='Style de figure (opt-in)')
    args = p.parse_args()
                       "--outdir",
                       type=str,
                       default=None,
                       help="Dossier pour copier la figure (fallback $MCGT_OUTDIR)")


p.add_argument("--fmt", type=str, default=None,
               help="Format savefig (png, pdf, etc.)")

    # lecture
    df = pd.read_csv(args.results)

    x_candidates = [
        "phi_ref_fpeak",
        "phi_ref",
        "phi_ref_f_peak",
        "phi_ref_at_fpeak",
        "phi_reference",
    ]
    y_candidates = [
        "phi_mcgt_fpeak",
        "phi_mcgt",
        "phi_mcg",
        "phi_mcg_at_fpeak",
        "phi_MCGT",
    ]

    xcol = detect_column(df, args.x_col, x_candidates)
    ycol = detect_column(df, args.y_col, y_candidates)
    groupcol = args.group_col if (args.group_col in df.columns) else None

    cols = [xcol, ycol] + ([groupcol] if groupcol else [])
    sub = df[cols].dropna().copy()
    x = sub[xcol].astype(float).values
    y = sub[ycol].astype(float).values
    _groups = sub[groupcol].values if groupcol else None

    # Δφ circulaire
    dphi = circ_diff(x, y)
    abs_d = np.abs(dphi)
    N = len(abs_d)

    # stats scalaires
    mean_abs = float(np.mean(abs_d))
    median_abs = float(np.median(abs_d))
    p95_abs = float(np.percentile(abs_d, 95))
    max_abs = float(np.max(abs_d))
    frac_below = float(np.mean(abs_d < args.p95_ref))

    # stats circulaires
    cmean = circ_mean_rad(dphi)
    cstd = circ_std_rad(dphi)
    if args.boot_ci > 0:
        cmean_hat, ci_lo, ci_hi = bootstrap_circ_mean_ci(
            dphi, B=args.boot_ci, seed=args.seed
        )
    else:
        cmean_hat, ci_lo, ci_hi = cmean, cmean, cmean

    # -- NEW: largeur d'arc la plus courte entre les bornes d'IC, puis demi-largeur --
    arc_width = float(np.abs(wrap_pi(ci_hi - ci_lo)))
    half_arc = 0.5 * arc_width

    # Figure
    plt.style.use("classic")
    fig, ax = plt.subplots(figsize=(8, 8))

    # hexbin en fond
    if args.with_hexbin:
        ax.hexbin(
            x,
            y,
            gridsize=args.hexbin_gridsize,
            mincnt=1,
            cmap="Greys",
            alpha=args.hexbin_alpha,
            linewidths=0,
            zorder=0,
        )

    # scatter par-dessus
    sc = ax.scatter(
        x,
        y,
        c=abs_d,
        s=args.point_size,
        alpha=args.alpha,
        cmap=args.cmap,
        edgecolor="none",
        zorder=1,
    )

    # limites
    xmin, xmax = np.min(x), np.max(x)
    ymin, ymax = np.min(y), np.max(y)
    if args.clip_pi:
        ax.set_xlim(-np.pi, np.pi)
        ax.set_ylim(-np.pi, np.pi)
    else:
        pad_x = 0.03 * (xmax - xmin) if xmax > xmin else 0.1
        pad_y = 0.03 * (ymax - ymin) if ymax > ymin else 0.1
        ax.set_xlim(xmin - pad_x, xmax + pad_x)
        ax.set_ylim(ymin - pad_y, ymax + pad_y)

    # -- NEW: même échelle en X et Y pour que y=x soit à 45° --
    ax.set_aspect("equal", adjustable="box")

    # y = x
    lo = min(ax.get_xlim()[0], ax.get_ylim()[0])
    hi = max(ax.get_xlim()[1], ax.get_ylim()[1])
    ax.plot([lo, hi], [lo, hi], color="gray", linestyle="--", lw=1.2, zorder=2)

    # axes / titre
    ax.set_xlabel(f"{xcol} [rad]")
    ax.set_ylabel(f"{ycol} [rad]")
    ax.set_title(args.title, fontsize=15)

    # colorbar |Δφ|
    cbar = fig.colorbar(sc, ax=ax)
    cbar.set_label(r"$|\Delta\phi|$ [rad]")
    if args.pi_ticks:
        ticks = [0.0, np.pi / 4, np.pi / 2, 3 * np.pi / 4, np.pi]
        cbar.set_ticks(ticks)
        cbar.set_ticklabels(
            ["0", r"$\pi/4$", r"$\pi/2$", r"$3\pi/4$", r"$\pi$"])

    # stats box
    stat_lines = [
        f"N = {N}",
        f"|Δφ| mean = {mean_abs:.3f}",
        f"median = {median_abs:.3f}",
        f"p95 = {p95_abs:.3f}",
        f"max = {max_abs:.3f}",
        f"|Δφ| < {args.p95_ref:.4f} : {100 * frac_below:.2f}% (n={int(round(frac_below * N))})",
        f"circ-mean(Δφ) = {cmean_hat:.3f} rad",
        f"  95% CI ≈ {cmean_hat:.3f} ± {half_arc:.3f} rad (arc court)",
        f"circ-std(Δφ) = {cstd:.3f} rad",
    ]
    bbox = dict(boxstyle="round", fc="white", ec="black", lw=1, alpha=0.95)
    ax.text(
        0.02,
        0.98,
        "\n".join(stat_lines),
        transform=ax.transAxes,
        fontsize=9,
        va="top",
        ha="left",
        bbox=bbox,
        zorder=5,
    )

    # annotation top-K pires |Δφ|
    if args.annotate_top_k and args.annotate_top_k > 0:
        k = int(min(args.annotate_top_k, N))
        idx = np.argsort(-abs_d)[:k]
        for i in idx:
            ax.annotate(
                f"{abs_d[i]:.3f}",
                (x[i], y[i]),
                xytext=(4, 4),
                textcoords="offset points",
                fontsize=7,
                color="black",
                alpha=0.8,
            )

    # pied de figure
    foot = (
        r"$\Delta\phi$ calculé circulairement en radians (b − a mod $2\pi \rightarrow [-\pi,\pi)$). "
        r"Couleur = $|\Delta\phi|$. Hexbin = densité (si activé)." )
    fig.text(0.5, 0.02, foot, ha="center", fontsize=9)

    plt.tight_layout(rect=[0, 0.04, 1, 0.98])
    fig.savefig(args.out, dpi=args.dpi)
    print(f"Wrote: {args.out}")


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
