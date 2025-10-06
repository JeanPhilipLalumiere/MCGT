#!/usr/bin/env python3
import os
"""
plot_fig05_ddelta_phi_vs_k.py

Figure 05 — Dérivée lissée ∂ₖ(δφ/φ)(k)
Chapitre 7 – Perturbations scalaires MCGT
"""

from __future__ import annotations

import json
import logging
import sys
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.ticker import LogLocator

# --- Logging et style ---
logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")
plt.style.use("classic")

# --- Racine du projet pour importer mcgt si nécessaire ---
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

# --- Paths (English names for directories and files) ---
DATA_DIR = ROOT / "zz-data" / "chapter07"
CSV_DDK = DATA_DIR / "07_ddelta_phi_dk.csv"
JSON_META = DATA_DIR / "07_meta_perturbations.json"
FIG_DIR = ROOT / "zz-figures" / "chapter07"
FIG_OUT = FIG_DIR / "fig_05_ddelta_phi_vs_k.png"

# --- Lecture de k_split ---
if not JSON_META.exists():
    raise FileNotFoundError(f"Meta parameters not found: {JSON_META}")
meta = json.loads(JSON_META.read_text("utf-8"))
k_split = float(meta.get("x_split", 0.02))
logging.info("k_split = %.2e h/Mpc", k_split)

# --- Chargement des données ---
if not CSV_DDK.exists():
    raise FileNotFoundError(f"Data not found: {CSV_DDK}")
df = pd.read_csv(CSV_DDK, comment="#")
logging.info("Loaded %d points from %s", len(df), CSV_DDK.name)

k_vals = df["k"].to_numpy()
ddphi = df.iloc[:, 1].to_numpy()
abs_dd = np.abs(ddphi)

# --- Tracé ---
FIG_DIR.mkdir(parents=True, exist_ok=True)
fig, ax = plt.subplots(figsize=(8, 5), constrained_layout=True)

# Courbe
ax.loglog(k_vals, abs_dd, color="C2", lw=2,
          label=r"$|\partial_k(\delta\phi/\phi)|$")

# Repère k_split
ax.axvline(k_split, ls="--", color="gray", lw=1)
# Label k_split placé juste au-dessus de ymin
ymin, ymax = 1e-50, 1e-2
y_text = 10 ** (np.log10(ymin) + 0.05 * (np.log10(ymax) - np.log10(ymin)))
ax.text(
    k_split * 1.05,
    y_text,
    r"$k_{\rm split}$",
    ha="left",
    va="bottom",
    fontsize=9)

# Limites
ax.set_ylim(ymin, ymax)
ax.set_xlim(k_vals.min(), k_vals.max())

# Axes en log
ax.set_xscale("log")
ax.set_yscale("log")

# Labels
ax.set_xlabel(r"$k\,[h/\mathrm{Mpc}]$")
ax.set_ylabel(r"$|\partial_k(\delta\phi/\phi)|$")

# Tick Y explicites
yticks = [1e-50, 1e-40, 1e-30, 1e-20, 1e-10, 1e-2]
ax.set_yticks(yticks)
ax.set_yticklabels([f"$10^{{{int(np.log10(t))}}}$" for t in yticks])

# Grilles
ax.grid(which="major", ls=":", lw=0.5)
ax.grid(which="minor", ls=":", lw=0.3, alpha=0.7)

# Locators X
ax.xaxis.set_major_locator(LogLocator(base=10))
ax.xaxis.set_minor_locator(LogLocator(base=10, subs=(2, 5)))

# Légende
ax.legend(loc="upper right", frameon=False)

# Sauvegarde
fig.savefig(FIG_OUT, dpi=300)
plt.close(fig)
logging.info("Figure saved → %s", FIG_OUT)

# === MCGT CLI SEED v2 ===
if __name__ == "__main__":
    def _mcgt_cli_seed():
        import os
        import argparse
        import sys
        import traceback

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Standard CLI seed (non-intrusif).")
    parser.add_argument(
        "--outdir",
        default=os.environ.get(
            "MCGT_OUTDIR",
            ".ci-out"),
        help="Dossier de sortie (par défaut: .ci-out)")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Ne rien écrire, juste afficher les actions.")
    parser.add_argument("--seed", type=int, default=None,
                        help="Graine aléatoire (optionnelle).")
    parser.add_argument(
        "--force",
        action="store_true",
        help="Écraser les sorties existantes si nécessaire.")
    parser.add_argument(
        "-v",
        "--verbose",
        action="count",
        default=0,
        help="Verbosity cumulable (-v, -vv).")
    parser.add_argument("--dpi", type=int, default=150,
                        help="Figure DPI (default: 150)")
    parser.add_argument(
        "--format",
        choices=[
            "png",
            "pdf",
            "svg"],
        default="png",
        help="Figure format")
    parser.add_argument(
        "--transparent",
        action="store_true",
        help="Transparent background")

    args = parser.parse_args()
    try:
    os.makedirs(args.outdir, exist_ok=True)
    os.environ["MCGT_OUTDIR"] = args.outdir
    import matplotlib as mpl
    mpl.rcParams["savefig.dpi"] = args.dpi
    mpl.rcParams["savefig.format"] = args.format
    mpl.rcParams["savefig.transparent"] = args.transparent
    except Exception:
    pass
    _main = globals().get("main")
    if callable(_main):
    try:
    _main(args)
    except SystemExit:
    raise
    except Exception as e:
    print(f"[CLI seed] main() a levé: {e}", file=sys.stderr)
    traceback.print_exc()
    sys.exit(1)
    _mcgt_cli_seed()

# [MCGT POSTPARSE EPILOGUE v1]
try:
    # On n agit que si un objet args existe au global
    if "args" in globals():
        import os
        import atexit
        # 1) Fallback via MCGT_OUTDIR si outdir est vide/None
        env_out = os.environ.get("MCGT_OUTDIR")
        if getattr(args, "outdir", None) in (None, "", False) and env_out:
            args.outdir = env_out
        # 2) Création sûre du répertoire s il est défini
        if getattr(args, "outdir", None):
            try:
                os.makedirs(args.outdir, exist_ok=True)
            except Exception:
                pass
        # 3) rcParams savefig si des attributs existent
        try:
            import matplotlib
            _rc = {}
            if hasattr(args, "dpi") and args.dpi:
                _rc["savefig.dpi"] = args.dpi
            if hasattr(args, "fmt") and args.fmt:
                _rc["savefig.format"] = args.fmt
            if hasattr(args, "transparent"):
                _rc["savefig.transparent"] = bool(args.transparent)
            if _rc:
                matplotlib.rcParams.update(_rc)
        except Exception:
            pass
        # 4) Copier automatiquement le dernier PNG vers outdir à la fin

        def _smoke_copy_latest():
            try:
                if not getattr(args, "outdir", None):
                    return
                import glob
                import os
                import shutil
                _ch = os.path.basename(os.path.dirname(__file__))
                _repo = os.path.abspath(
                    os.path.join(
                        os.path.dirname(__file__),
                        "..",
                        ".."))
                _default_dir = os.path.join(_repo, "zz-figures", _ch)
                pngs = sorted(
                    glob.glob(os.path.join(_default_dir, "*.png")),
                    key=os.path.getmtime,
                    reverse=True,
                )
                for _p in pngs:
                    if os.path.exists(_p):
                        _dst = os.path.join(args.outdir, os.path.basename(_p))
                        if not os.path.exists(_dst):
                            shutil.copy2(_p, _dst)
                        break
            except Exception:
                pass
        atexit.register(_smoke_copy_latest)
except Exception:
    # épilogue best-effort — ne doit jamais casser le script principal
    pass
