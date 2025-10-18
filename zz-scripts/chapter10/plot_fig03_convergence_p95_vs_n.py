#!/usr/bin/env python3
"""
plot_fig03_convergence_p95_vs_n.py

"""
from __future__ import annotations

# >>> AUTO-ARGS-SHIM >>>
try:
    args
except NameError:
    import argparse as _argparse
    import sys as _sys
    _shim = _argparse.ArgumentParser(add_help=False)
    # I/O & colonnes
    _shim.add_argument('--results')
    _shim.add_argument('--x-col'); _shim.add_argument('--y-col')
    _shim.add_argument('--sigma-col'); _shim.add_argument('--group-col')
    _shim.add_argument('--n-col'); _shim.add_argument('--p95-col')
    _shim.add_argument('--orig-col'); _shim.add_argument('--recalc-col')
    _shim.add_argument('--m1-col'); _shim.add_argument('--m2-col')
    # Export
    _shim.add_argument('--dpi'); _shim.add_argument('--out')
    _shim.add_argument('--format'); _shim.add_argument('--transparent', action='store_true')
    # Numériques/contrôles divers
    _shim.add_argument('--npoints'); _shim.add_argument('--hires2000', action='store_true')
    _shim.add_argument('--change-eps', dest='change_eps')
    _shim.add_argument('--ref-p95', dest='ref_p95')
    _shim.add_argument('--metric'); _shim.add_argument('--bins'); _shim.add_argument('--alpha')
    _shim.add_argument('--boot-iters', dest='boot_iters'); _shim.add_argument('--seed'); _shim.add_argument('--trim')
    _shim.add_argument('--minN', dest='minN'); _shim.add_argument('--point-size', dest='point_size')
    _shim.add_argument('--zoom-w', dest='zoom_w'); _shim.add_argument('--zoom-h', dest='zoom_h')
    _shim.add_argument('--abs', action='store_true', dest='abs')
    _shim.add_argument('--p95-ref', dest='ref_p95')
    _shim.add_argument('--B', dest='B'); _shim.add_argument('--M', dest='M'); _shim.add_argument('--outer', dest='outer')
    _shim.add_argument('--cmap')
    _shim.add_argument('--zoom-x', dest='zoom_x'); _shim.add_argument('--zoom-dx', dest='zoom_dx')
    _shim.add_argument('--scale-exp', dest='scale_exp')
    _shim.add_argument('--zoom-center-n', dest='zoom_center_n')
    _shim.add_argument('--inner', dest='inner')
    _shim.add_argument('--title', dest='title')
    _shim.add_argument('--zoom-y', dest='zoom_y'); _shim.add_argument('--zoom-dy', dest='zoom_dy')
    _shim.add_argument('--vclip', dest='vclip')
    _shim.add_argument('--angular', action='store_true')
    _shim.add_argument('--hist-scale', dest='hist_scale')
    _shim.add_argument('--threshold', dest='threshold')
    _shim.add_argument('--title-left',  dest='title_left')
    _shim.add_argument('--title-right', dest='title_right')
    _shim.add_argument('--hist-x', dest='hist_x')
    _shim.add_argument('--hist-y', dest='hist_y')
    _shim.add_argument('--figsize')
    # Nouveaux
    _shim.add_argument('--with-zoom', dest='with_zoom', action='store_true')
    _shim.add_argument('--gridsize', dest='gridsize')

    try:
        args, _unk = _shim.parse_known_args(_sys.argv[1:])
    except Exception:
        class _A: pass
        args = _A()

    _DEF = {
        'npoints': 50, 'hires2000': False, 'change_eps': 1e-6, 'ref_p95': 1e9,
        'metric': 'dp95', 'bins': 50, 'alpha': 0.7, 'boot_iters': 2000, 'trim': 0.0,
        'minN': 10, 'point_size': 10.0, 'zoom_w': 1.0, 'zoom_h': 1.0, 'abs': False,
        'B': 2000, 'M': None, 'outer': 500, 'cmap': 'viridis',
        'zoom_x': 0.0, 'zoom_dx': 1.0, 'scale_exp': 0.0,
        'zoom_center_n': None, 'inner': 2000, 'title': 'MCGT figure',
        'zoom_y': 0.0, 'zoom_dy': 1.0, 'vclip': '1,99', 'angular': False,
        'hist_scale': 1.0, 'threshold': 0.0, 'title_left': 'Left panel',
        'title_right': 'Right panel', 'hist_x': 0.0, 'hist_y': 0.0,
        'figsize': '6,4', 'with_zoom': False, 'gridsize': 60,
    }
    for _k, _v in _DEF.items():
        if not hasattr(args, _k) or getattr(args, _k) is None:
            try: setattr(args, _k, _v)
            except Exception: pass

    def _to_int(x):
        try: return int(x)
        except: return x
    def _to_float(x):
        try: return float(x)
        except: return x

    for _k in ('dpi','B','M','outer','bins','boot_iters','npoints','minN','inner','zoom_center_n','gridsize'):
        if hasattr(args,_k): setattr(args,_k, _to_int(getattr(args,_k)))
    for _k in ('alpha','trim','change_eps','point_size','zoom_w','zoom_h','zoom_x','zoom_dx','zoom_y','zoom_dy','scale_exp','hist_scale','threshold','hist_x','hist_y'):
        if hasattr(args,_k): setattr(args,_k, _to_float(getattr(args,_k)))
# <<< AUTO-ARGS-SHIM <<<

import argparse

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from mpl_toolkits.axes_grid1.inset_locator import inset_axes

from zz_tools import common_io as ci

def detect_p95_column(df: pd.DataFrame, hint: str | None):
    if hint and hint in df.columns:
        return hint
    for c in [
        "p95_20_300_recalc",
        "p95_20_300_circ",
        "p95_20_300",
        "p95_circ",
        "p95_recalc",
    ]:
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
    return float(np.mean(a[k : n - k]))

def compute_bootstrap_convergence(
    p95: np.ndarray, N_list: np.ndarray, B: int, seed: int, trim_alpha: float
):
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
        mean_est[i] = ests_mean.mean()
        median_est[i] = ests_median.mean()
        tmean_est[i] = ests_tmean.mean()
        mean_low[i], mean_high[i] = np.percentile(ests_mean, [2.5, 97.5])
        median_low[i], median_high[i] = np.percentile(ests_median, [2.5, 97.5])
        tmean_low[i], tmean_high[i] = np.percentile(ests_tmean, [2.5, 97.5])

    return (
        mean_est,
        mean_low,
        mean_high,
        median_est,
        median_low,
        median_high,
        tmean_est,
        tmean_low,
        tmean_high,
    )

def main():
    p = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    p.add_argument("--results", required=True, help="CSV results (with p95 column)")
    p.add_argument(
        "--p95-col", default=None, help="Nom de la colonne p95 (auto si omis)"
    )
    p.add_argument(
        "--out",
        default="zz-figures/chapter10/10_fig_03_convergence_p95_vs_n.png",
        help="PNG de sortie",
    )
    p.add_argument("--B", type=int, default=2000, help="Nombre de réplicats bootstrap")
    p.add_argument("--seed", type=int, default=12345, help="Seed RNG")
    p.add_argument("--dpi", type=int, default=150, help="DPI PNG")
    p.add_argument("--npoints", type=int, default=100, help="Nb de valeurs N évaluées")
    p.add_argument(
        "--trim",
        type=float,
        default=0.05,
        help="Proportion tronquée de chaque côté (trimmed mean)",
    )
    p.add_argument(
        "--zoom-center-n", type=int, default=None, help="Centre en N (par défaut ~M/2)"
    )
    p.add_argument(
        "--zoom-w",
        type=float,
        default=0.35,
        help="Largeur de base de l'encart (fraction figure)",
    )
    p.add_argument(
        "--zoom-h",
        type=float,
        default=0.20,
        help="Hauteur de base de l'encart (fraction figure)",
    )
    args = p.parse_args()

    df = pd.read_csv(args.results)
try:
    df
except NameError:
    import pandas as _pd
    _res = None
    try:
        _res = args.results
    except Exception:
        for _j,_a in enumerate(_sys.argv):
            if _a == "--results" and _j+1 < len(_sys.argv):
                _res = _sys.argv[_j+1]
                break
    if _res is None:
        raise RuntimeError("Cannot infer --results (no args and no --results in argv)")
    df = _pd.read_csv(_res)
df = ci.ensure_fig02_cols(df)
p95_col = detect_p95_column(df, args.p95_col)
p95 = df[p95_col].dropna().astype(float).values
M = len(p95)
if M == 0:
        raise SystemExit("Aucun p95 disponible dans le fichier.")

minN = max(10, int(max(10, M * 0.01)))
N_list = np.unique(np.linspace(minN, M, args.npoints, dtype=int))
if N_list[-1] != M:
        N_list = np.append(N_list, M)

ref_mean = float(np.mean(p95))
_ref_median = float(np.median(p95))
_ref_tmean = trimmed_mean(p95, args.trim)

print(
        f"[INFO] Bootstrap convergence: M={M}, B={args.B}, points={len(N_list)}, seed={args.seed}, trim={args.trim:.3f}"
    )
(
        mean_est,
        mean_low,
        mean_high,
        median_est,
        median_low,
        median_high,
        tmean_est,
        tmean_low,
        tmean_high,
    ) = compute_bootstrap_convergence(p95, N_list, args.B, args.seed, args.trim)

final_i = np.where(N_list == M)[0][0] if (N_list == M).any() else -1
final_mean, final_mean_ci = (
        mean_est[final_i],
        (mean_low[final_i], mean_high[final_i]),
    )
final_median, final_median_ci = (
        median_est[final_i],
        (median_low[final_i], median_high[final_i]),
    )
final_tmean, final_tmean_ci = (
        tmean_est[final_i],
        (tmean_low[final_i], tmean_high[final_i]),
    )

plt.style.use("classic")
fig, ax = plt.subplots(figsize=(14, 6))

ax.fill_between(
        N_list,
        mean_low,
        mean_high,
        color="tab:blue",
        alpha=0.18,
        label="IC 95% (bootstrap, mean)",
    )
ax.plot(N_list, mean_est, color="tab:blue", lw=2.0, label="Estimateur (mean)")
ax.plot(
        N_list,
        median_est,
        color="tab:orange",
        lw=1.6,
        ls="--",
        label="Estimateur (median)",
    )
ax.plot(
        N_list,
        tmean_est,
        color="tab:green",
        lw=1.6,
        ls="-.",
        label=f"Estimateur (trimmed mean, α={args.trim:.2f})",
    )

ax.axhline(ref_mean, color="crimson", lw=2, label=f"Estimation à N={M} (mean réf)")

ax.set_xlim(0, M)
ax.set_xlabel("Taille d'échantillon N")
ax.set_ylabel(f"estimateur de {p95_col} [rad]")
ax.set_title(f"Convergence de l'estimation de {p95_col}", fontsize=15)

leg = ax.legend(loc="lower right", frameon=True, fontsize=10)
leg.set_zorder(5)

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
        sel = slice(len(N_list) // 3, 2 * len(N_list) // 3)
        ylo = np.min(mean_low[sel])
        yhi = np.max(mean_high[sel])
else:
        ylo = float(np.nanmin(mean_low[sel]))
        yhi = float(np.nanmax(mean_high[sel]))
ypad = 0.02 * (yhi - ylo) if (yhi - ylo) > 0 else 0.005
yin0, yin1 = ylo - ypad, yhi + ypad

inset_x = 0.62 - inset_w / 2.0
inset_y = 0.18
inset_ax = inset_axes(
        ax,
        width=f"{inset_w * 100}%",
        height=f"{inset_h * 100}%",
        bbox_to_anchor=(inset_x, inset_y, inset_w, inset_h),
        bbox_transform=fig.transFigure,
        loc="lower left",
        borderpad=1,
    )

sel_idx = (N_list >= xin0) & (N_list <= xin1)
inset_ax.fill_between(
        N_list[sel_idx],
        mean_low[sel_idx],
        mean_high[sel_idx],
        color="tab:blue",
        alpha=0.18,
    )
inset_ax.plot(N_list[sel_idx], mean_est[sel_idx], color="tab:blue", lw=1.5)
inset_ax.plot(
        N_list[sel_idx], median_est[sel_idx], color="tab:orange", lw=1.2, ls="--"
    )
inset_ax.plot(
        N_list[sel_idx], tmean_est[sel_idx], color="tab:green", lw=1.2, ls="-."
    )
inset_ax.axhline(ref_mean, color="crimson", lw=1.0, ls="--")
inset_ax.set_xlim(xin0, xin1)
inset_ax.set_ylim(yin0, yin1)
inset_ax.set_title("zoom (mean)", fontsize=10)
inset_ax.tick_params(axis="both", which="major", labelsize=8)
inset_ax.grid(False)

stat_lines = [
        f"N = {M}",
        f"mean = {final_mean:.3f}  (95% CI [{final_mean_ci[0]:.3f}, {final_mean_ci[1]:.3f}])",
        f"median = {final_median:.3f}  (95% CI [{final_median_ci[0]:.3f}, {final_median_ci[1]:.3f}])",
        f"trimmed mean (α={args.trim:.2f}) = {final_tmean:.3f}  "
        f"(95% CI [{final_tmean_ci[0]:.3f}, {final_tmean_ci[1]:.3f}])",
        f"bootstrap = percentile, B = {args.B}, seed = {args.seed}",
    ]
bbox = dict(boxstyle="round", fc="white", ec="black", lw=1, alpha=0.95)
ax.text(
        0.98,
        0.28,
        "\n".join(stat_lines),
        transform=ax.transAxes,
        fontsize=9,
        va="bottom",
        ha="right",
        bbox=bbox,
        zorder=20,
    )

fig.text(
        0.5,
        0.02,
        f"Bootstrap (B={args.B}, percentile) sur {M} échantillons. "
        f"Estimateurs tracés = mean (solid), median (dashed), trimmed mean (dash-dot, α={args.trim:.2f}).",
        ha="center",
        fontsize=9,
    )

fig.subplots_adjust(left=0.04, right=0.98, bottom=0.06, top=0.96)
fig.savefig(args.out, dpi=args.dpi)
print(f"Wrote: {args.out}")

if __name__ == "__main__":
    main()
