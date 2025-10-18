#!/usr/bin/env python3
from __future__ import annotations

# --- cli global proxy v7 ---
import sys as _sys
import types as _types

try:
    args  # noqa: F821  # peut ne pas exister
except NameError:
    args = _types.SimpleNamespace()

_COMMON_DEFAULTS = {
    'p95_col': None,
    'm1_col': 'phi0',
    'm2_col': 'phi_ref_fpeak',
    'hires2000': False,
    'metric': 'dp95',
    'mincnt': 1,
    'gridsize': 60,
    'figsize': '8,6',
    'dpi': 300,
    'title': '',
    'title_left': '',
    'title_right': '',
    'hist_x': 0,
    'hist_y': 0,
    'hist_scale': 1.0,
    'with_zoom': False,
    'zoom_x': None,
    'zoom_y': None,
    'zoom_dx': None,
    'zoom_dy': None,
    'zoom_center_n': None,
    'cmap': 'viridis',
    'point_size': 10,
    'threshold': 0.0,
    'angular': False,
    'vclip': '0,100',
    'minN': 10,
    'scale_exp': 0,
    'ymin_coverage': 0.0,
    'ymax_coverage': 1.0,
}

def _v7_from_argv(flag_name: str):
    flag = '--' + flag_name.replace('_','-')
    for i,a in enumerate(_sys.argv):
        if a == flag and i+1 < len(_sys.argv):
            return _sys.argv[i+1]
        if a.startswith(flag + '='):
            return a.split('=',1)[1]
        if a == flag:
            return True
        if a == '--no-' + flag_name.replace('_','-'):
            return False
    return None

def _v7_cast(val):
    if isinstance(val, (bool, int, float)) or val is None:
        return val
    s = str(val)
    sl = s.lower()
    if sl in ('true','yes','y','1'): return True
    if sl in ('false','no','n','0'): return False
    try:
        if any(ch in s for ch in ('.','e','E')):
            return float(s)
        return int(s)
    except Exception:
        return s

class _ArgsProxy:
    def __init__(self, base):
        object.__setattr__(self, '_base', base)
    def __getattr__(self, name):
        if hasattr(self._base, name):
            return getattr(self._base, name)
        v = _v7_from_argv(name)
        if v is None:
            v = _COMMON_DEFAULTS.get(name, None)
        else:
            v = _v7_cast(v)
        setattr(self._base, name, v)
        return v
    def __setattr__(self, name, value):
        if name == '_base':
            object.__setattr__(self, name, value)
        else:
            setattr(self._base, name, value)
args = _ArgsProxy(args)
# --- end cli global proxy v7 ---

# --- util: safe cast helper ---
def _int_or_none(x):
    try:
        return None if x in (None, '', 'None') else int(x)
    except Exception:
        return None
# --- end util ---

# --- cli global proxy v7 coalesce defaults ---
try:
    args
except NameError:
    pass
else:
    if getattr(args, 'npoints', None) is None: args.npoints = 50
    if getattr(args, 'minN', None) is None: args.minN = 10
# --- end cli global proxy v7 coalesce defaults ---

# --- cli global proxy v7 local tweak ---
try:
    args
except NameError:
    pass
else:
    if not hasattr(args, 'npoints'): args.npoints = 50
# --- end cli global proxy v7 local tweak ---

# --- cli global backfill v6 ---

try:
    args  # noqa: F821  # peut ne pas exister
except NameError:
    args = _types.SimpleNamespace()

def _v6_arg_or_default(flag: str, default):
    # priorité au CLI si présent (sans supposer que le parser connaît le flag)
    for _j, _a in enumerate(_sys.argv):
        if _a == flag and _j + 1 < len(_sys.argv):
            return _sys.argv[_j + 1]
    return default

if not hasattr(args, 'p95_col'):
    args.p95_col = _v6_arg_or_default('--p95-col', None)
# --- end cli global backfill v6 ---

"""
plot_fig03b_coverage_bootstrap_vs_n.py

"""

# --- compat: ensure args.p95_col exists ---
if 'args' in globals() and not hasattr(args, 'p95_col'):
    args.p95_col = None  # trigger detect_p95_column(...)

# --- AUTO-FALLBACKS (ch10: fig03b) ---
try:
    args
except NameError:
    from argparse import Namespace as _NS
    args = _NS()
if not hasattr(args, 'ymin_coverage'): args.ymin_coverage = None
if not hasattr(args, 'ymax_coverage'): args.ymax_coverage = None
# --- END AUTO-FALLBACKS (ch10: fig03b) ---

# >>> AUTO-ARGS-SHIM >>>
try:
    args
except NameError:
    import argparse as _argparse
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
        # --- cli post-parse backfill (auto v2) ---
        import sys as _sys  # backfill
        try:
            args.p95_col
        except AttributeError:
            _val = None
            for _j, _a in enumerate(_sys.argv):
                if _a == '--p95-col' and _j + 1 < len(_sys.argv):
                    _val = _sys.argv[_j + 1]
                    break
            if _val is None:
                args.p95_col = None
            else:
                args.p95_col = _val
        # --- end cli post-parse backfill (auto v2) ---
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
import json
import os
import time
from dataclasses import dataclass

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from mpl_toolkits.axes_grid1.inset_locator import inset_axes

from zz_tools import common_io as ci

# ----------------------------- utilitaires ---------------------------------

def detect_p95_column(df: pd.DataFrame, hint: str | None) -> str:
    if hint and hint in df.columns:
        return hint
    for c in [
        "p95_20_300_recalc",
        "p95_20_300_circ",
        "p95_20_300",
        "p95_circ",
        "p95_recalc",
        "p95",
    ]:
        if c in df.columns:
            return c
    for c in df.columns:
        if "p95" in c.lower():
            return c
    raise KeyError("Aucune colonne p95 détectée (utiliser --p95-col).")

def wilson_err95(p: float, n: int) -> tuple[float, float]:
    """Retourne (err_bas, err_haut) Wilson 95% pour une proportion p sur n."""
    if n <= 0:
        return 0.0, 0.0
    z = 1.959963984540054  # 97.5e percentile
    denom = 1.0 + (z * z) / n
    center = (p + (z * z) / (2 * n)) / denom
    half = (z / denom) * np.sqrt((p * (1 - p) / n) + (z * z) / (4 * n * n))
    lo = max(0.0, center - half)
    hi = min(1.0, center + half)
    return (p - lo, hi - p)

def bootstrap_percentile_ci(
    vals: np.ndarray, B: int, rng: np.random.Generator, alpha: float = 0.05
) -> tuple[float, float]:
    """IC percentile (95% par défaut) pour la moyenne linéaire."""
    n = len(vals)
    boots = np.empty(B, dtype=float)
    for b in range(B):
        samp = rng.choice(vals, size=n, replace=True)
        boots[b] = float(np.mean(samp))
    lo = float(np.percentile(boots, 100 * (alpha / 2)))
    hi = float(np.percentile(boots, 100 * (1 - alpha / 2)))
    return lo, hi

def circ_mean_rad(angles: np.ndarray) -> float:
    """Moyenne circulaire d'angles (radians)."""
    z = np.mean(np.exp(1j * angles))
    return float(np.angle(z))

@dataclass
class RowRes:
    N: int
    coverage: float
    cov_err95_low: float
    cov_err95_high: float
    width_mean: float
    n_hits: int
    method: str

# ------------------------------- coeur --------------------------------------

def main():
    p = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    p.add_argument("--results", required=True, help="CSV avec colonne p95.")
    p.add_argument("--p95-col", default=None, help="Nom exact de la colonne p95.")
    p.add_argument(
        "--out",
        default="zz-figures/chapter10/10_fig_03_b_coverage_bootstrap_vs_n.png",
        help="PNG de sortie",
    )
    p.add_argument(
        "--outer",
        type=int,
        default=400,
        help="Nombre de réplicats externes (couverture).",
    )
    p.add_argument(
        "--M",
        type=int,
        default=None,
        help="Alias de --outer (si précisé, remplace --outer).",
    )
    p.add_argument(
        "--inner", type=int, default=2000, help="Nombre de réplicats internes (IC)."
    )
    p.add_argument(
        "--alpha", type=float, default=0.05, help="Niveau d'erreur pour IC (ex. 0.05)."
    )
    p.add_argument("--npoints", type=int, default=10, help="Nombre de points N.")
    p.add_argument("--minN", type=int, default=100, help="Plus petit N.")
    p.add_argument("--seed", type=int, default=12345, help="Seed RNG.")
    p.add_argument("--dpi", type=int, default=300, help="DPI PNG.")
    p.add_argument(
        "--ymin-coverage", type=float, default=None, help="Ymin panneau couverture."
    )
    p.add_argument(
        "--ymax-coverage", type=float, default=None, help="Ymax panneau couverture."
    )
    p.add_argument(
        "--title-left",
        default="Couverture IC vs N (estimateur: mean)",
        help="Titre panneau gauche.",
    )
    p.add_argument(
        "--title-right", default="Largeur d'IC vs N", help="Titre panneau droit."
    )
    p.add_argument(
        "--hires2000",
        action="store_true",
        help="Utiliser outer=2000, inner=2000 (ne change pas les défauts globaux).",
    )
    p.add_argument(
        "--angular",
        action="store_true",
        help="Active l'encart comparant moyenne linéaire vs moyenne circulaire (p95 en radians).",
    )
    p.add_argument(
        "--make-sensitivity",
        action="store_true",
        help="Produit une figure annexe de sensibilité (coverage vs outer/inner).",
    )
    p.add_argument(
        "--sens-mode",
        choices=["outer", "inner"],
        default="outer",
        help="Paramètre de sensibilité (outer ou inner).",
    )
    p.add_argument(
        "--sens-N",
        type=int,
        default=None,
        help="N fixe utilisé pour la sensibilité (défaut: N max du dataset).",
    )
    p.add_argument(
        "--sens-B-list",
        default="100,200,400,800,1200,2000",
        help="Liste de B séparés par virgules pour la sensibilité.",
    )
    args = p.parse_args()
    # --- cli post-parse backfill (auto v2) ---
    try:
        args.p95_col
    except AttributeError:
        _val = None
        for _j, _a in enumerate(_sys.argv):
            if _a == '--p95-col' and _j + 1 < len(_sys.argv):
                _val = _sys.argv[_j + 1]
                break
        if _val is None:
            args.p95_col = None
        else:
            args.p95_col = _val
    # --- end cli post-parse backfill (auto v2) ---

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
vals_all = df[p95_col].dropna().astype(float).values
Mtot = len(vals_all)
if Mtot == 0:
        raise SystemExit("Aucune donnée p95.")
print(f"[INFO] Dataset M={Mtot}, p95_col={p95_col}")

if args.hires2000:
        args.outer = 2000
        args.inner = 2000
        if args.M is None:
            args.M = 2000
        print("[INFO] Mode haute précision: outer=2000, inner=2000")

minN = max(10, int(args.minN))
N_list = np.unique(np.linspace(minN, Mtot, args.npoints, dtype=int))
if N_list[-1] != Mtot:
        N_list = np.append(N_list, Mtot)
print(f"[INFO] N_list = {N_list.tolist()}")

outer_for_cov = int(args.M) if args.M is not None else int(args.outer)
print(
        f"[INFO] outer={outer_for_cov}, inner={args.inner}, alpha={args.alpha}, seed={args.seed}"
    )

rng = np.random.default_rng(args.seed)
ref_value_lin = float(np.mean(vals_all))
ref_value_circ = float(circ_mean_rad(vals_all)) if args.angular else None

results: list[RowRes] = []
for idx, N in enumerate(N_list, start=1):
        hits = 0
        widths = np.empty(outer_for_cov, dtype=float)
        for b in range(outer_for_cov):
            samp = rng.choice(vals_all, size=int(N), replace=True)
            lo, hi = bootstrap_percentile_ci(samp, args.inner, rng, alpha=args.alpha)
            widths[b] = hi - lo
            if (ref_value_lin >= lo) and (ref_value_lin <= hi):
                hits += 1
        p_hat = hits / outer_for_cov
        e_lo, e_hi = wilson_err95(p_hat, outer_for_cov)
        results.append(
            RowRes(
                N=int(N),
                coverage=float(p_hat),
                cov_err95_low=float(e_lo),
                cov_err95_high=float(e_hi),
                width_mean=float(np.mean(widths)),
                n_hits=int(hits),
                method="percentile",
            )
        )
        print(
            f"[{idx}/{len(N_list)}] N={N:5d}  coverage={p_hat:0.3f}  width_mean={np.mean(widths):0.5f} rad"
        )

plt.style.use("classic")
fig = plt.figure(figsize=(15, 6))
gs = fig.add_gridspec(1, 2, width_ratios=[5, 3], wspace=0.25)
ax1 = fig.add_subplot(gs[0, 0])
ax2 = fig.add_subplot(gs[0, 1])

xN = [r.N for r in results]
yC = [r.coverage for r in results]
yerr_low = [r.cov_err95_low for r in results]
yerr_high = [r.cov_err95_high for r in results]
ax1.errorbar(
        xN,
        yC,
        yerr=[yerr_low, yerr_high],
        fmt="o-",
        lw=1.6,
        ms=6,
        color="tab:blue",
        ecolor="tab:blue",
        elinewidth=1.0,
        capsize=3,
        label="Couverture empirique",
    )
ax1.axhline(
        1 - args.alpha, color="crimson", ls="--", lw=1.5, label="Niveau nominal 95%"
    )

ax1.set_xlabel("Taille d'échantillon N")
ax1.set_ylabel("Couverture (IC 95% contient la référence)")
ax1.set_title(args.title_left)
if (args.ymin_coverage is not None) or (args.ymax_coverage is not None):
        ymin = (
            args.ymin_coverage if args.ymin_coverage is not None else ax1.get_ylim()[0]
        )
        ymax = (
            args.ymax_coverage if args.ymax_coverage is not None else ax1.get_ylim()[1]
        )
        ax1.set_ylim(ymin, ymax)
ax1.legend(loc="lower right", frameon=True)

txt = (
        f"N = {Mtot}\n"
        f"mean(ref) = {ref_value_lin:0.3f} rad\n"
        f"outer B = {outer_for_cov}, inner B = {args.inner}\n"
        f"seed = {args.seed}\n"
        f"note: IC = percentile (inner bootstrap)"
    )
ax1.text(
        0.02,
        0.97,
        txt,
        transform=ax1.transAxes,
        va="top",
        ha="left",
        bbox=dict(boxstyle="round", fc="white", ec="black", alpha=0.95),
    )

if args.angular:
        inset = inset_axes(
            ax1,
            width="33%",
            height="27%",
            loc="lower left",
            bbox_to_anchor=(0.04, 0.08, 0.33, 0.27),
            bbox_transform=ax1.transAxes,
            borderpad=0.5,
        )
        bars = [ref_value_lin, ref_value_circ]
        inset.bar([0, 1], bars)
        inset.set_xticks([0, 1])
        inset.set_xticklabels(["mean\n(lin)", "mean\n(circ)"])
        inset.set_title("Référence N=max", fontsize=9)
        inset.set_ylabel("[rad]", fontsize=8)
        inset.tick_params(axis="both", labelsize=8)

ax2.plot(xN, [r.width_mean for r in results], "-", lw=2.0, color="tab:green")
ax2.set_xlabel("Taille d'échantillon N")
ax2.set_ylabel("Largeur moyenne de l'IC 95% [rad]")
ax2.set_title(args.title_right)

fig.subplots_adjust(left=0.08, right=0.98, top=0.92, bottom=0.18, wspace=0.25)

foot = (
        f"Bootstrap imbriqué: outer={outer_for_cov}, inner={args.inner}. "
        f"Référence = estimateur({Mtot}) = {ref_value_lin:0.3f} rad. Seed={args.seed}."
    )
fig.text(0.5, 0.012, foot, ha="center", fontsize=10)

os.makedirs(os.path.dirname(args.out), exist_ok=True)
fig.savefig(args.out, dpi=args.dpi)
print(f"[OK] Figure écrite: {args.out}")

manifest_path = os.path.splitext(args.out)[0] + ".manifest.json"
manifest = {
        "script": "plot_fig03b_coverage_bootstrap_vs_n.py",
        "generated_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "inputs": {"results": args.results, "p95_col": p95_col},
        "params": {
            "outer": int(outer_for_cov),
            "inner": int(args.inner),
            "alpha": float(args.alpha),
            "seed": _int_or_none(args.seed),
            "minN": int(args.minN),
            "npoints": int(args.npoints),
            "ymin_coverage": (
                None if args.ymin_coverage is None else float(args.ymin_coverage)
            ),
            "ymax_coverage": (
                None if args.ymax_coverage is None else float(args.ymax_coverage)
            ),
            "angular_inset": bool(args.angular),
        },
        "ref_value_linear_rad": float(ref_value_lin),
        "ref_value_circular_rad": (
            None if ref_value_circ is None else float(ref_value_circ)
        ),
        "N_list": [int(x) for x in np.asarray(N_list).tolist()],
        "results": [
            {
                "N": int(r.N),
                "coverage": float(r.coverage),
                "coverage_err95_low": float(r.cov_err95_low),
                "coverage_err95_high": float(r.cov_err95_high),
                "width_mean_rad": float(r.width_mean),
                "hits": int(r.n_hits),
                "method": r.method,
            }
            for r in results
        ],
        "figure_path": args.out,
    }
with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)
print(f"[OK] Manifest écrit: {manifest_path}")

if args.make_sensitivity:
        mode = args.sens_mode
        sensN = int(args.sens_N) if args.sens_N is not None else int(N_list[-1])
        B_list = [int(x.strip()) for x in args.sens_B_list.split(",") if x.strip()]
        print(f"[INFO] Sensibilité: mode={mode}, N={sensN}, B_list={B_list}")

        rng2 = np.random.default_rng(args.seed + 7)
        cov_list, lo_list, hi_list = [], [], []

        for B in B_list:
            if mode == "outer":
                hits = 0
                for b in range(B):
                    samp = rng2.choice(vals_all, size=sensN, replace=True)
                    lo, hi = bootstrap_percentile_ci(
                        samp, args.inner, rng2, alpha=args.alpha
                    )
                    if (ref_value_lin >= lo) and (ref_value_lin <= hi):
                        hits += 1
                p_hat = hits / B
                e_lo, e_hi = wilson_err95(p_hat, B)
            else:
                hits = 0
                for b in range(outer_for_cov):
                    samp = rng2.choice(vals_all, size=sensN, replace=True)
                    lo, hi = bootstrap_percentile_ci(samp, B, rng2, alpha=args.alpha)
                    if (ref_value_lin >= lo) and (ref_value_lin <= hi):
                        hits += 1
                p_hat = hits / outer_for_cov
                e_lo, e_hi = wilson_err95(p_hat, outer_for_cov)

            cov_list.append(float(p_hat))
            lo_list.append(float(e_lo))
            hi_list.append(float(e_hi))
            print(f"[SENS] B={B:4d}  coverage={p_hat:0.3f}")

        figS, axS = plt.subplots(figsize=(7.5, 4.2))
        axS.errorbar(
            B_list,
            cov_list,
            yerr=[lo_list, hi_list],
            fmt="o-",
            color="tab:blue",
            ecolor="tab:blue",
            capsize=3,
            lw=1.6,
            ms=6,
            label="Couverture empirique",
        )
        axS.axhline(
            1 - args.alpha, color="crimson", ls="--", lw=1.5, label="Niveau nominal 95%"
        )
        axS.set_xlabel("B (outer)" if mode == "outer" else "B (inner)")
        axS.set_ylabel("Couverture (IC 95% contient la référence)")
        axS.set_title(
            f"Sensibilité de la couverture vs {'outer' if mode == 'outer' else 'inner'}  (N={sensN})"
        )
        axS.legend(loc="lower right", frameon=True)
        fig.subplots_adjust(left=0.04, right=0.98, bottom=0.06, top=0.96)
        out_sens = os.path.splitext(args.out)[0] + f"_sensitivity_{mode}.png"
        figS.savefig(out_sens, dpi=args.dpi)
        print(f"[OK] Figure annexe écrite: {out_sens}")

        manifest_sens = {
            "script": "plot_fig03b_coverage_bootstrap_vs_n.py",
            "annex": "sensitivity",
            "generated_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            "mode": mode,
            "N": int(sensN),
            "B_list": [int(b) for b in B_list],
            "coverage": [float(c) for c in cov_list],
            "err95_low": [float(e) for e in lo_list],
            "err95_high": [float(e) for e in hi_list],
            "figure_path": out_sens,
        }
        sens_path = os.path.splitext(out_sens)[0] + ".manifest.json"
        with open(sens_path, "w", encoding="utf-8") as f:
            json.dump(manifest_sens, f, indent=2)
        print(f"[OK] Manifest annexe écrit: {sens_path}")

if __name__ == "__main__":
    main()
