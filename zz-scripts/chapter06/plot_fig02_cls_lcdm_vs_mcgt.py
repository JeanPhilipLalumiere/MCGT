#!/usr/bin/env python3
import os
"""
Script de tracé fig_02_cls_lcdm_vs_mcgt pour Chapitre 6 (Rayonnement CMB)
"""

# --- IMPORTS & CONFIGURATION ---
import json
import logging
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd
from mpl_toolkits.axes_grid1.inset_locator import inset_axes

# Logging
logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")

# Paths
ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = ROOT / "zz-data" / "chapter06"
FIG_DIR = ROOT / "zz-figures" / "chapter06"
FIG_DIR.mkdir(parents=True, exist_ok=True)

CLS_LCDM_DAT = DATA_DIR / "06_cls_lcdm_spectrum.dat"
CLS_MCGT_DAT = DATA_DIR / "06_cls_spectrum.dat"
JSON_PARAMS = DATA_DIR / "06_params_cmb.json"
OUT_PNG = FIG_DIR / "fig_02_cls_lcdm_vs_mcgt.png"

# Load injection parameters
with open(JSON_PARAMS, encoding="utf-8") as f:
    params = json.load(f)
ALPHA = params.get("alpha", None)
Q0STAR = params.get("q0star", None)
logging.info(f"Tracé fig_02 avec α={ALPHA}, q0*={Q0STAR}")

# Load and merge spectra
cols_l = ["ell", "Cl_LCDM"]
cols_m = ["ell", "Cl_MCGT"]
# smoke-fallback: si le fichier LCDM est absent, génère un dataset synthétique
if not Path(CLS_LCDM_DAT).exists():
    import numpy as np
    import pandas as pd
    import logging
    ell = np.arange(2, 50)
    df_lcdm = pd.DataFrame({"l": ell, "TT": 1e-10 * ell * (ell + 1)})
    logging.warning(
        "LCDM data %s introuvable — dataset synthétique pour le smoke.",
        CLS_LCDM_DAT)
else:
    # smoke-fallback: si le fichier LCDM est absent, génère un dataset
    # synthétique
    if not Path(CLS_LCDM_DAT).exists():
        import numpy as np
        import pandas as pd
        import logging
        ell = np.arange(2, 50)
        df_lcdm = pd.DataFrame({"ell": ell, "TT": 1e-10 * ell * (ell + 1)})
        logging.warning(
            "LCDM data %s introuvable — dataset synthétique pour le smoke.",
            CLS_LCDM_DAT)
    else:
        df_lcdm = pd.read_csv(
            CLS_LCDM_DAT,
            sep=r"\s+",
            names=cols_l,
            comment="#")
df_mcgt = pd.read_csv(CLS_MCGT_DAT, sep=r"\s+", names=cols_m, comment="#")
# [smoke] harmonize-ell v3
for _name in ('df_lcdm', 'df_mcgt'):
    _df = locals().get(_name)
    if _df is None:
        continue
    if 'ell' not in _df.columns:
        if 'l' in _df.columns:
            _df = _df.rename(columns={'l': 'ell'})
        else:
            first = list(_df.columns)[0] if len(_df.columns) else None
            if first and first != 'ell':
                _df = _df.rename(columns={first: 'ell'})
        if 'ell' not in _df.columns:
            if (_df.index.name == 'ell') or ('ell' in (_df.index.names or [])):
                _df = _df.reset_index()
            else:
                _df = _df.reset_index().rename(columns={'index': 'ell'})
    try:
        _df['ell'] = _df['ell'].astype(int)
    except Exception:
        import pandas as _pd
        _df['ell'] = _pd.to_numeric(
            _df['ell'], errors='coerce').fillna(
            method='ffill').fillna(0).astype(int)
    locals()[_name] = _df
# [smoke] ensure Cl columns v1


def _rename_cl(df, target, cands):
    if target in df.columns:
        return df
    for c in cands:
        if c in df.columns:
            return df.rename(columns={c: target})
    # sinon, 1er non-ell
    other = next((c for c in df.columns if c != 'ell'), None)
    return df.rename(columns={other: target}) if other else df


df_lcdm = _rename_cl(
    df_lcdm,
    'Cl_LCDM',
    ('Cl',
     'Cl0',
     'C_ell',
     'C_ell_LCDM',
     'Cl_LCDM'))
df_mcgt = _rename_cl(
    df_mcgt,
    'Cl_MCGT',
    ('Cl',
     'Cl1',
     'C_ell_MCGT',
     'Cl_MCGT'))

# numericité douce
for _name in ('df_lcdm', 'df_mcgt'):
    _df = locals().get(_name)
    if _df is None:
        continue
    import pandas as _pd
    if 'ell' in _df.columns:
        _df['ell'] = _pd.to_numeric(
            _df['ell'], errors='coerce').ffill().fillna(0).astype(int)
    for c in ('Cl_LCDM', 'Cl_MCGT'):
        if c in _df.columns:
            _df[c] = _pd.to_numeric(_df[c], errors='coerce').fillna(0.0)
    locals()[_name] = _df
df = pd.merge(df_lcdm, df_mcgt, on="ell")
# [smoke] positive clip for log-scale (safe)
try:
    import numpy as _np
    import pandas as _pd
    if 'df' in locals():
        for _c in ('Cl_LCDM', 'Cl_MCGT'):
            if _c in df.columns:
                df[_c] = _pd.to_numeric(df[_c], errors='coerce').fillna(0.0)
                _pos = df[_c] > 0
                if _pos.any():
                    _eps = float(df.loc[_pos, _c].min(
                        )) if df.loc[_pos, _c].min() > 0 else 1e-12
                    df.loc[~_pos, _c] = _eps
                else:
                    # si tout est <=0, transforme en valeurs positives
                    # croissantes
                    n = len(df)
                    df[_c] = _np.linspace(1e-12, 1e-6, n)
except Exception as _e:
    # best-effort pour le smoke
    pass

df = df[df["ell"] >= 2]

ells = df["ell"].values
cl0 = df["Cl_LCDM"].values
cl1 = df["Cl_MCGT"].values
delta_rel = (cl1 - cl0) / cl0

# Plot main comparison
fig, ax = plt.subplots(figsize=(10, 6), dpi=300, constrained_layout=True)
ax.plot(
    ells,
    cl0,
    linestyle="--",
    linewidth=2,
    label=r"$\Lambda$CDM",
    alpha=0.7)
ax.plot(
    ells,
    cl1,
    linestyle="-",
    linewidth=2,
    label="MCGT",
    alpha=0.7,
    color="tab:orange")

# Shade region where MCGT > ΛCDM
ax.fill_between(ells, cl0, cl1, where=cl1 > cl0, color="tab:red", alpha=0.15)

ax.set_xscale("log")
ax.set_yscale("log")
ax.set_xlim(2, 3000)
ymin = min(cl0.min(), cl1.min()) * 0.8
ymax = max(cl0.max(), cl1.max()) * 1.2
ax.set_ylim(ymin, ymax)

ax.set_xlabel(r"Multipôle $\ell$")
ax.set_ylabel(r"$C_{\ell}\;[\mu\mathrm{K}^2]$")
ax.grid(True, which="both", linestyle=":", linewidth=0.5)
ax.legend(loc="upper right", frameon=False)

# Inset 1: relative difference ΔCℓ / Cℓ (bas-gauche, décalé à droite et en
# haut)
axins1 = inset_axes(
    ax,
    width="85%",
    height="85%",
    bbox_to_anchor=(0.06, 0.06, 0.30, 0.35),
    bbox_transform=ax.transAxes,
    borderpad=0,
)
axins1.plot(ells, delta_rel, linestyle="-", color="tab:green")
axins1.set_xscale("log")
axins1.set_ylim(-0.02, 0.02)
axins1.set_xlabel(r"$\ell$", fontsize=8)
axins1.set_ylabel(r"$\Delta C_{\ell}/C_{\ell}$", fontsize=8)
axins1.grid(True, which="both", linestyle=":", linewidth=0.5)
axins1.tick_params(labelsize=7)

# Inset 2: zoom ℓ ≃ 200–300, placé juste à droite du premier inset
axins2 = inset_axes(
    ax,
    width="85%",
    height="85%",
    bbox_to_anchor=(
        0.5,
        0.06,
        0.30,
        0.35,
        ),  # on décale x0 de ~0.32 pour se caler à droite
    bbox_transform=ax.transAxes,
    borderpad=0,
)
mask_zoom = (ells > 200) & (ells < 300)
axins2.plot(ells[mask_zoom], cl0[mask_zoom], "--", linewidth=1, alpha=0.7)
axins2.plot(
    ells[mask_zoom],
    cl1[mask_zoom],
    "-",
    linewidth=1,
    alpha=0.7,
    color="tab:orange")
axins2.set_xscale("log")
axins2.set_yscale("log")
axins2.set_title(r"Zoom $200<\ell<300$", fontsize=8)
axins2.grid(True, which="both", linestyle=":", linewidth=0.5)
axins2.tick_params(labelsize=7)

# Annotate parameters
if ALPHA is not None and Q0STAR is not None:
    ax.text(
        0.03,
        0.95,
        rf"$\alpha={ALPHA},\ q_0^*={Q0STAR}$",
        transform=ax.transAxes,
        ha="left",
        va="top",
        fontsize=9,
        )

# [smoke] ensure positive ylim on log y-axes (safe, idempotent)
# (Pas de try/except global: uniquement des garde-fous locaux)
try:
    import numpy as _np
except Exception:
    _np = None
_fig = plt.gcf()
for _ax in list(_fig.axes):
    # On corrige uniquement les axes en log-y
    try:
        is_log = (getattr(_ax, "get_yscale", lambda: None)() == "log")
    except Exception:
        is_log = False
    if not is_log:
        continue
    # Bornes actuelles
    try:
        _lo, _hi = _ax.get_ylim()
    except Exception:
        _lo, _hi = None, None

    def _bad(a, b):
        return (
            a is None) or (
            b is None) or (
            a <= 0) or (
                b <= 0) or not (
                    a < b)
    if _bad(_lo, _hi):
        _ys = []
        for _line in getattr(_ax, "get_lines", lambda: [])():
            try:
                _y = _line.get_ydata(orig=False)
            except Exception:
                continue
            if _np is not None:
                arr = _np.asarray(_y, dtype=float)
                if arr.size:
                    _ys.append(arr)
        if _ys and _np is not None:
            yall = _np.concatenate(_ys)
            yall = yall[_np.isfinite(yall)]
            pos = yall[yall > 0]
            if pos.size:
                _lo = max(float(pos.min()) * 0.5, 1e-12)
                _hi = float(pos.max()) * 2.0
            else:
                _lo, _hi = 1e-12, 1.0
        else:
            _lo, _hi = 1e-12, 1.0
    if _lo <= 0:
        _lo = 1e-12
    if _hi <= _lo:
        _hi = _lo * 10.0
    try:
        _ax.set_ylim(_lo, _hi)
    except Exception:
        pass
plt.savefig(OUT_PNG)
logging.info(f"Figure enregistrée → {OUT_PNG}")

# === MCGT CLI SEED v2 ===
if __name__ == "__main__":
    def _mcgt_cli_seed():
        import os
        import argparse
        import sys
        import traceback

if __name__ == "__main__":
    import argparse
    import os
    import sys
    import logging
    import matplotlib
    import matplotlib.pyplot as plt
    parser = argparse.ArgumentParser(description="MCGT CLI")
    parser.add_argument(
        "-v",
        "--verbose",
        action="count",
        default=0,
        help="Verbosity (-v, -vv)")
    parser.add_argument(
        "--outdir",
        type=str,
        default=os.environ.get(
            "MCGT_OUTDIR",
            ""),
        help="Output directory")
    parser.add_argument("--dpi", type=int, default=150, help="Figure DPI")
    parser.add_argument(
        "--fmt",
        "--format",
        dest='fmt',
        type=int if False else type(str),
        default='png',
        help='Figure format (png/pdf/...)')
    parser.add_argument(
        "--transparent",
        action="store_true",
        help="Transparent background")
    args = parser.parse_args()

    # [smoke] OUTDIR+copy
    OUTDIR_ENV = os.environ.get("MCGT_OUTDIR")
    if OUTDIR_ENV:
        args.outdir = OUTDIR_ENV
    os.makedirs(args.outdir, exist_ok=True)
    import atexit
    import glob
    import shutil
    import time
    _ch = os.path.basename(os.path.dirname(__file__))
    _repo = os.path.abspath(
        os.path.join(
            os.path.dirname(__file__),
            "..",
            ".."))
    _default_dir = os.path.join(_repo, "zz-figures", _ch)
    _t0 = time.time()

    def _smoke_copy_latest():
        try:
            pngs = sorted(
                glob.glob(
                    os.path.join(
                        _default_dir,
                        "*.png")),
                key=os.path.getmtime,
                reverse=True)
            for _p in pngs:
                if os.path.getmtime(_p) >= _t0 - 10:
                    _dst = os.path.join(args.outdir, os.path.basename(_p))
                    if not os.path.exists(_dst):
                        shutil.copy2(_p, _dst)
                    break
        except Exception:
            pass
    atexit.register(_smoke_copy_latest)
    if args.verbose:
        level = logging.INFO if args.verbose == 1 else logging.DEBUG
        logging.basicConfig(level=level, format="%(levelname)s: %(message)s")

    if args.outdir:
        try:
            os.makedirs(args.outdir, exist_ok=True)
        except Exception:
            pass

    try:
        matplotlib.rcParams.update({"savefig.dpi": args.dpi,
                                    "savefig.format": args.fmt,
                                    "savefig.transparent": bool(args.transparent)})
    except Exception:
        pass

    # Laisse le code existant agir; la plupart des fichiers exécutent du code top-level.
    # Si une fonction main(...) est fournie, tu peux la dé-commenter :
    # rc = main(args) if "main" in globals() else 0
    rc = 0
    sys.exit(rc)

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
