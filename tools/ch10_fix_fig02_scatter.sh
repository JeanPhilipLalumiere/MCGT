#!/usr/bin/env bash
set -euo pipefail

S="zz-scripts/chapter10"
F="$S/plot_fig02_scatter_phi_at_fpeak.py"

echo "[PATCH] Réécriture propre de $F (parser complet, aucune exécution hors main)"

cat > "$F" <<'PY'
#!/usr/bin/env python3
"""
plot_fig02_scatter_phi_at_fpeak.py

Nuage de points comparant phi_ref(f_peak) vs phi_MCGT(f_peak).
- Différence circulaire Δφ = wrap(phi_MCGT - phi_ref) dans [-π, π)
- Couleur = |Δφ|
- Hexbin optionnel
- Statistiques et IC bootstrap (95%) optionnels
"""

from __future__ import annotations

import argparse
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

TWOPI = 2.0 * np.pi

def wrap_pi(x: np.ndarray) -> np.ndarray:
    return (x + np.pi) % TWOPI - np.pi

def circ_diff(a: np.ndarray, b: np.ndarray) -> np.ndarray:
    return wrap_pi(b - a)

def circ_mean_rad(angles: np.ndarray) -> float:
    z = np.mean(np.exp(1j * angles))
    return float(np.angle(z))

def circ_std_rad(angles: np.ndarray) -> float:
    R = np.abs(np.mean(np.exp(1j * angles)))
    return float(np.sqrt(max(0.0, -2.0 * np.log(max(R, 1e-12)))))

def bootstrap_circ_mean_ci(angles: np.ndarray, B: int = 1000, seed: int = 12345):
    n = len(angles)
    theta_hat = circ_mean_rad(angles) if n else 0.0
    if n == 0 or B <= 0:
        return theta_hat, theta_hat, theta_hat
    rng = np.random.default_rng(seed)
    deltas = np.empty(B, dtype=float)
    for b in range(B):
        idx = rng.integers(0, n, size=n)
        th_b = circ_mean_rad(angles[idx])
        deltas[b] = wrap_pi(th_b - theta_hat)
    lo = np.percentile(deltas, 2.5)
    hi = np.percentile(deltas, 97.5)
    return wrap_pi(theta_hat), wrap_pi(theta_hat + lo), wrap_pi(theta_hat + hi)

def detect_column(df: pd.DataFrame, hint: str | None, candidates: list[str]) -> str:
    if hint and hint in df.columns:
        return hint
    for c in candidates:
        if c in df.columns:
            return c
    # recherche souple
    low = [c.lower() for c in df.columns]
    for cand in candidates:
        if cand.lower() in low:
            return df.columns[low.index(cand.lower())]
    raise KeyError(f"Colonne introuvable (hint={hint}, candidates={candidates})")

def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="Scatter phi_ref(f_peak) vs phi_MCGT(f_peak)")
    p.add_argument("--results", required=True, help="CSV d'entrée")
    p.add_argument("--out", required=True, help="PNG/PDF de sortie")
    p.add_argument("--x-col", default=None, help="Nom de la colonne phi_ref (auto-détection sinon)")
    p.add_argument("--y-col", default=None, help="Nom de la colonne phi_mcgt (auto-détection sinon)")
    p.add_argument("--group-col", default=None, help="Colonne de regroupement (facultatif, non utilisé pour la couleur)")
    p.add_argument("--alpha", type=float, default=0.7, help="Alpha du scatter")
    p.add_argument("--point-size", type=float, default=10.0, help="Taille des points")
    p.add_argument("--cmap", default="viridis", help="Colormap pour |Δφ|")
    p.add_argument("--dpi", type=int, default=300, help="DPI sortie")
    p.add_argument("--clip-pi", action="store_true", help="Axe X/Y dans [-π, π]")
    p.add_argument("--pi-ticks", action="store_true", help="Ticks colorbar à 0,π/4,π/2,3π/4,π")
    p.add_argument("--with-hexbin", action="store_true", help="Ajoute un fond hexbin (densité)")
    p.add_argument("--hexbin-gridsize", type=int, default=40, help="Grille hexbin")
    p.add_argument("--hexbin-alpha", type=float, default=0.35, help="Alpha hexbin")
    p.add_argument("--annotate-top-k", type=int, default=0, help="Annote les k pires |Δφ| (0=off)")
    p.add_argument("--p95-ref", type=float, default=1.0, help="Référence pour fraction |Δφ|<ref")
    p.add_argument("--boot-ci", type=int, default=0, help="Taille bootstrap pour IC (0=off)")
    p.add_argument("--seed", type=int, default=12345, help="Seed bootstrap")
    p.add_argument("--title", default="φ_ref(f_peak) vs φ_MCGT(f_peak)", help="Titre")
    return p

def main() -> None:
    args = build_parser().parse_args()

    df = pd.read_csv(args.results)
    x_candidates = ["phi_ref_fpeak", "phi_ref", "phi_ref_f_peak", "phi_ref_at_fpeak", "phi_reference"]
    y_candidates = ["phi_mcgt_fpeak", "phi_mcgt", "phi_mcg", "phi_mcg_at_fpeak", "phi_MCGT"]

    xcol = detect_column(df, args.x_col, x_candidates)
    ycol = detect_column(df, args.y_col, y_candidates)

    cols = [xcol, ycol] + ([args.group_col] if (args.group_col and args.group_col in df.columns) else [])
    sub = df[cols].dropna().copy()
    x = sub[xcol].astype(float).values
    y = sub[ycol].astype(float).values

    dphi = circ_diff(x, y)
    abs_d = np.abs(dphi)
    N = len(abs_d)

    mean_abs = float(np.mean(abs_d)) if N else 0.0
    median_abs = float(np.median(abs_d)) if N else 0.0
    p95_abs = float(np.percentile(abs_d, 95)) if N else 0.0
    max_abs = float(np.max(abs_d)) if N else 0.0
    frac_below = float(np.mean(abs_d < args.p95_ref)) if N else 0.0

    cmean = circ_mean_rad(dphi) if N else 0.0
    cstd  = circ_std_rad(dphi) if N else 0.0
    if args.boot_ci > 0 and N > 0:
        cmean_hat, ci_lo, ci_hi = bootstrap_circ_mean_ci(dphi, B=args.boot_ci, seed=args.seed)
    else:
        cmean_hat, ci_lo, ci_hi = cmean, cmean, cmean
    half_arc = 0.5 * float(np.abs(wrap_pi(ci_hi - ci_lo)))

    plt.style.use("classic")
    fig, ax = plt.subplots(figsize=(8, 8))

    if args.with_hexbin and N > 0:
        ax.hexbin(x, y, gridsize=args.hexbin_gridsize, mincnt=1, cmap="Greys",
                  alpha=args.hexbin_alpha, linewidths=0, zorder=0)

    sc = ax.scatter(x, y, c=abs_d, s=args.point_size, alpha=args.alpha,
                    cmap=args.cmap, edgecolor="none", zorder=1)

    if args.clip_pi:
        ax.set_xlim(-np.pi, np.pi)
        ax.set_ylim(-np.pi, np.pi)
    else:
        if N > 0:
            xmin, xmax = np.min(x), np.max(x)
            ymin, ymax = np.min(y), np.max(y)
            pad_x = 0.03 * (xmax - xmin) if xmax > xmin else 0.1
            pad_y = 0.03 * (ymax - ymin) if ymax > ymin else 0.1
            ax.set_xlim(xmin - pad_x, xmax + pad_x)
            ax.set_ylim(ymin - pad_y, ymax + pad_y)

    ax.set_aspect("equal", adjustable="box")
    lo = min(ax.get_xlim()[0], ax.get_ylim()[0])
    hi = max(ax.get_xlim()[1], ax.get_ylim()[1])
    ax.plot([lo, hi], [lo, hi], color="gray", linestyle="--", lw=1.2, zorder=2)

    ax.set_xlabel(f"{xcol} [rad]")
    ax.set_ylabel(f"{ycol} [rad]")
    ax.set_title(args.title, fontsize=15)

    cbar = fig.colorbar(sc, ax=ax)
    cbar.set_label(r"$|\Delta\phi|$ [rad]")
    if args.pi_ticks:
        ticks = [0.0, np.pi/4, np.pi/2, 3*np.pi/4, np.pi]
        cbar.set_ticks(ticks)
        cbar.set_ticklabels(["0", r"$\pi/4$", r"$\pi/2$", r"$3\pi/4$", r"$\pi$"])

    stat_lines = [
        f"N = {N}",
        f"|Δφ| mean = {mean_abs:.3f}",
        f"median = {median_abs:.3f}",
        f"p95 = {p95_abs:.3f}",
        f"max = {max_abs:.3f}",
        f"|Δφ| < {args.p95_ref:.4f} : {100*frac_below:.2f}%",
        f"circ-mean(Δφ) = {cmean_hat:.3f} rad",
        f"95% CI arc ≈ ± {half_arc:.3f} rad" if args.boot_ci>0 and N>0 else "95% CI arc: n/a",
        f"circ-std(Δφ) = {cstd:.3f} rad",
    ]
    bbox = dict(boxstyle="round", fc="white", ec="black", lw=1, alpha=0.95)
    ax.text(0.02, 0.98, "\n".join(stat_lines), transform=ax.transAxes, fontsize=9,
            va="top", ha="left", bbox=bbox, zorder=5)

    if args.annotate_top_k and args.annotate_top_k > 0 and N > 0:
        k = int(min(args.annotate_top_k, N))
        idx = np.argsort(-abs_d)[:k]
        for i in idx:
            ax.annotate(f"{abs_d[i]:.3f}", (x[i], y[i]),
                        xytext=(4, 4), textcoords="offset points",
                        fontsize=7, color="black", alpha=0.8)

    fig.subplots_adjust(left=0.10, right=0.98, top=0.95, bottom=0.10)
    fig.savefig(args.out, dpi=args.dpi)
    print(f"Wrote: {args.out}")

# [MCGT POSTPARSE EPILOGUE v2] (best-effort, no-op si indisponible)
try:
    import os, sys
    _here = os.path.abspath(os.path.dirname(__file__))
    _zz = os.path.abspath(os.path.join(_here, ".."))
    if _zz not in sys.path:
        sys.path.insert(0, _zz)
    from _common.postparse import apply as _mcgt_postparse_apply
except Exception:
    def _mcgt_postparse_apply(*_a, **_k):  # noqa: N802
        pass
try:
    if __name__ == "__main__":
        _mcgt_postparse_apply(None, caller_file=__file__)
except Exception:
    pass

if __name__ == "__main__":
    main()
PY

echo "[TEST] --help (doit passer sans exécuter de plotting)"
python3 "$F" --help >/dev/null

echo "[SMOKE] Relance le smoke minimal pour fig02 + l'ancien smoke global"
O="zz-out/chapter10"
D="zz-data/chapter10"
mkdir -p "$O"
python3 "$F" --results "$D/dummy_results.csv" --out "$O/fig02.png" --alpha 0.6 --pi-ticks --dpi 120

# Relance le smoke global s'il existe, sinon fait un --help sur tout
if [[ -x tools/ch10_smoke.sh ]]; then
  bash tools/ch10_smoke.sh
else
  echo "[CHECK] --help sur les autres scripts"
  for f in \
    plot_fig01_iso_p95_maps.py \
    plot_fig03_convergence_p95_vs_n.py \
    plot_fig03b_bootstrap_coverage_vs_n.py \
    plot_fig04_scatter_p95_recalc_vs_orig.py \
    plot_fig05_hist_cdf_metrics.py \
    plot_fig06_residual_map.py \
    plot_fig07_synthesis.py
  do
    python3 "$S/$f" --help >/dev/null
  done
fi

echo "[DONE] fig02 corrigée + smoke OK."
