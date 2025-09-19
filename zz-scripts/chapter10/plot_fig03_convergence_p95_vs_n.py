#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
tracer_fig03_convergence_p95_vs_n.py

Trace la convergence d’estimateurs de p95 (mean, median, trimmed mean) en fonction
de la taille d’échantillon N, avec IC 95% (bootstrap percentile).
Produit un PNG.

Exemple:
python zz-scripts/chapter10/tracer_fig03_convergence_p95_vs_n.py \
  --results zz-data/chapter10/10_mc_results.circ.csv \
  --p95-col p95_20_300_recalc \
  --out zz-figures/chapter10/fig_03_convergence_p95_vs_n.png \
  --B 2000 --seed 12345 --dpi 150
"""
from __future__ import annotations
import argparse
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from mpl_toolkits.axes_grid1.inset_locator import inset_axes


def detect_p95_column(df: pd.DataFrame, hint: str | None):
    if hint and hint in df.columns:
        return hint
    for c in ["p95_20_300_recalc", "p95_20_300_circ", "p95_20_300", "p95_circ", "p95_recalc"]:
        if c in df.columns:
            return c
    for c in df.columns:
        if "p95" in c.lower():
            return c
    raise KeyError("Aucune colonne 'p95' détectée dans le fichier results.")


def trimmed_mean(arr: np.ndarray, alpha: float) -> float:
    """Moyenne tronquée bilatérale: retire alpha de chaque côté (mod 2π déjà géré en amont)."""
    if alpha <= 0:
        return float(np.mean(arr))
    n = len(arr)
    k = int(np.floor(alpha * n))
    if 2 * k >= n:
        return float(np.mean(arr))
    a = np.sort(arr)
    return float(np.mean(a[k:n - k]))


def compute_bootstrap_convergence(p95: np.ndarray, N_list: np.ndarray, B: int, seed: int, trim_alpha: float):
    rng = np.random.default_rng(seed)
    npoints = len(N_list)

    mean_est = np.empty(npoints)
    mean_low = np.empty(npoints)
    mean_high = np.empty(npoints)

    median_est = np.empty(npoints)
    median_low = np.empty(npoints)
    median_high = np.empty(npoints)

    tmean_est = np.empty(npoints)
    tmean_low = np.empty(npoints)
    tmean_high = np.empty(npoints)

    for i, N in enumerate(N_list):
        ests_mean = np.empty(B)
        ests_median = np.empty(B)
        ests_tmean = np.empty(B)
        for b in range(B):
            samp = rng.choice(p95, size=N, replace=True)
            ests_mean[b] = np.mean(samp)
            ests_median[b] = np.median(samp)
            ests_tmean[b] = trimmed_mean(samp, trim_alpha)
        # point estimators = moyenne des estimates bootstrap
        mean_est[i] = ests_mean.mean()
        median_est[i] = ests_median.mean()
        tmean_est[i] = ests_tmean.mean()
        # IC percentile
        mean_low[i], mean_high[i] = np.percentile(ests_mean, [2.5, 97.5])
        median_low[i], median_high[i] = np.percentile(ests_median, [2.5, 97.5])
        tmean_low[i], tmean_high[i] = np.percentile(ests_tmean, [2.5, 97.5])

    return (mean_est, mean_low, mean_high,
            median_est, median_low, median_high,
            tmean_est, tmean_low, tmean_high)


def main():
    p = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    p.add_argument("--results", required=True, help="CSV results (with p95 column)")
    p.add_argument("--p95-col", default=None, help="Nom de la colonne p95 (auto si omis)")
    p.add_argument("--out", default="fig_03_convergence_p95_vs_n.png", help="PNG de sortie")
    p.add_argument("--B", type=int, default=2000, help="Nombre de réplicats bootstrap")
    p.add_argument("--seed", type=int, default=12345, help="Seed RNG")
    p.add_argument("--dpi", type=int, default=150, help="DPI PNG")
    p.add_argument("--npoints", type=int, default=100, help="Nb de valeurs N évaluées")
    p.add_argument("--trim", type=float, default=0.05, help="Proportion tronquée de chaque côté (trimmed mean)")
    # paramètres du zoom (on conserve vos positions/taille)
    p.add_argument("--zoom-center-n", type=int, default=None, help="Centre en N (par défaut ~M/2)")
    p.add_argument("--zoom-w", type=float, default=0.35, help="Largeur de base de l'encart (fraction figure)")
    p.add_argument("--zoom-h", type=float, default=0.20, help="Hauteur de base de l'encart (fraction figure)")
    args = p.parse_args()

    # Lecture
    df = pd.read_csv(args.results)
    p95_col = detect_p95_column(df, args.p95_col)
    p95 = df[p95_col].dropna().astype(float).values
    M = len(p95)
    if M == 0:
        raise SystemExit("Aucun p95 disponible dans le fichier.")

    # Grille N
    minN = max(10, int(max(10, M * 0.01)))
    N_list = np.unique(np.linspace(minN, M, args.npoints, dtype=int))
    if N_list[-1] != M:
        N_list = np.append(N_list, M)

    # Références plein-échantillon
    ref_mean = float(np.mean(p95))
    ref_median = float(np.median(p95))
    ref_tmean = trimmed_mean(p95, args.trim)

    print(f"[INFO] Bootstrap convergence: M={M}, B={args.B}, points={len(N_list)}, seed={args.seed}, trim={args.trim:.3f}")
    (mean_est, mean_low, mean_high,
     median_est, median_low, median_high,
     tmean_est, tmean_low, tmean_high) = compute_bootstrap_convergence(p95, N_list, args.B, args.seed, args.trim)

    # Résumés finaux (pour boîte)
    final_i = np.where(N_list == M)[0][0] if (N_list == M).any() else -1
    final_mean, final_mean_ci = mean_est[final_i], (mean_low[final_i], mean_high[final_i])
    final_median, final_median_ci = median_est[final_i], (median_low[final_i], median_high[final_i])
    final_tmean, final_tmean_ci = tmean_est[final_i], (tmean_low[final_i], tmean_high[final_i])

    # Plot
    plt.style.use("classic")
    fig, ax = plt.subplots(figsize=(14, 6))

    # IC 95% pour la moyenne (zone bleue)
    ax.fill_between(N_list, mean_low, mean_high, color='tab:blue', alpha=0.18, label="IC 95% (bootstrap, mean)")
    # Estimateurs
    ax.plot(N_list, mean_est,   color='tab:blue',   lw=2.0, label="Estimateur (mean)")
    ax.plot(N_list, median_est, color='tab:orange', lw=1.6, ls='--', label="Estimateur (median)")
    ax.plot(N_list, tmean_est,  color='tab:green',  lw=1.6, ls='-.', label=f"Estimateur (trimmed mean, α={args.trim:.2f})")

    # Ligne de référence (mean plein-échantillon)
    ax.axhline(ref_mean, color='crimson', lw=2, label=f"Estimation à N={M} (mean réf)")

    ax.set_xlim(0, M)
    ax.set_xlabel("Taille d'échantillon N")
    ax.set_ylabel(f"estimateur de p95_20_300_recalc [rad]")
    ax.set_title(f"Convergence de l'estimation de {p95_col}", fontsize=15)

    # Légende
    leg = ax.legend(loc="lower right", frameon=True, fontsize=10)
    leg.set_zorder(5)

    # ----- Inset (on respecte vos positions/tailles) -----
    base_w, base_h = args.zoom_w, args.zoom_h
    inset_w = base_w * 1.5
    inset_h = base_h * 2.3
    center_n = args.zoom_center_n if args.zoom_center_n is not None else int(M * 0.5)
    win_frac = 0.25
    win_n = int(max(10, M * win_frac))
    xin0 = max(0, center_n - win_n // 2)
    xin1 = min(M, center_n + win_n // 2)

    sel = (N_list >= xin0) & (N_list <= xin1)
    if np.sum(sel) == 0:
        sel = slice(len(N_list)//3, 2*len(N_list)//3)
        ylo = np.min(mean_low[sel]); yhi = np.max(mean_high[sel])
    else:
        ylo = float(np.nanmin(mean_low[sel])); yhi = float(np.nanmax(mean_high[sel]))
    ypad = 0.02 * (yhi - ylo) if (yhi - ylo) > 0 else 0.005
    yin0, yin1 = ylo - ypad, yhi + ypad

    inset_x = 0.62 - inset_w / 2.0
    inset_y = 0.18
    inset_ax = inset_axes(ax,
                          width=f"{inset_w*100}%", height=f"{inset_h*100}%",
                          bbox_to_anchor=(inset_x, inset_y, inset_w, inset_h),
                          bbox_transform=fig.transFigure,
                          loc='lower left', borderpad=1)

    sel_idx = (N_list >= xin0) & (N_list <= xin1)
    inset_ax.fill_between(N_list[sel_idx], mean_low[sel_idx], mean_high[sel_idx], color='tab:blue', alpha=0.18)
    inset_ax.plot(N_list[sel_idx], mean_est[sel_idx],   color='tab:blue',   lw=1.5)
    inset_ax.plot(N_list[sel_idx], median_est[sel_idx], color='tab:orange', lw=1.2, ls='--')
    inset_ax.plot(N_list[sel_idx], tmean_est[sel_idx],  color='tab:green',  lw=1.2, ls='-.')
    inset_ax.axhline(ref_mean, color='crimson', lw=1.0, ls='--')
    inset_ax.set_xlim(xin0, xin1)
    inset_ax.set_ylim(yin0, yin1)
    inset_ax.set_title("zoom (mean)", fontsize=10)
    inset_ax.tick_params(axis='both', which='major', labelsize=8)
    inset_ax.grid(False)

    # Boîte synthèse (en bas à droite, au-dessus de la légende)
    stat_lines = [
        f"N = {M}",
        f"mean = {final_mean:.3f}  (95% CI [{final_mean_ci[0]:.3f}, {final_mean_ci[1]:.3f}])",
        f"median = {final_median:.3f}  (95% CI [{final_median_ci[0]:.3f}, {final_median_ci[1]:.3f}])",
        f"trimmed mean (α={args.trim:.2f}) = {final_tmean:.3f}  "
        f"(95% CI [{final_tmean_ci[0]:.3f}, {final_tmean_ci[1]:.3f}])",
        f"bootstrap = percentile, B = {args.B}, seed = {args.seed}",
    ]
    bbox = dict(boxstyle="round", fc="white", ec="black", lw=1, alpha=0.95)
    ax.text(0.98, 0.28, "\n".join(stat_lines),
            transform=ax.transAxes, fontsize=9,
            va='bottom', ha='right', bbox=bbox, zorder=20)

    # Footnote
    fig.text(0.5, 0.02,
             f"Bootstrap (B={args.B}, percentile) sur {M} échantillons. "
             f"Estimateurs tracés = mean (solid), median (dashed), trimmed mean (dash-dot, α={args.trim:.2f}).",
             ha='center', fontsize=9)

    plt.tight_layout(rect=[0, 0.05, 1, 0.97])
    fig.savefig(args.out, dpi=args.dpi)
    print(f"Wrote: {args.out}")


if __name__ == "__main__":
    main()
