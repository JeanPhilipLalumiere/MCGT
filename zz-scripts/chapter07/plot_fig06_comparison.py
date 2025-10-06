#!/usr/bin/env python3
import os
"""
plot_fig06_comparison.py

Figure 06 – Comparaison des invariants et dérivées
Chapitre 7 – Perturbations scalaires (MCGT)
"""

import json
import logging
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

# --- Logging ---
logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)

# --- Project root ---
ROOT = Path(__file__).resolve().parents[2]

# --- Paths (English names for directories and files) ---
DATA_DIR = ROOT / "zz-data" / "chapter07"
INV_CSV = DATA_DIR / "07_scalar_invariants.csv"
DCS2_CSV = DATA_DIR / "07_derivative_cs2_dk.csv"
DDPHI_CSV = DATA_DIR / "07_derivative_ddelta_phi_dk.csv"
META_JSON = DATA_DIR / "07_meta_perturbations.json"
FIG_OUT = ROOT / "zz-figures" / "chapter07" / "fig_06_comparison.png"

# --- Read k_split ---
with open(META_JSON, encoding="utf-8") as f:
    meta = json.load(f)
k_split = float(meta.get("x_split", 0.02))
logger.info("k_split = %.2e h/Mpc", k_split)

# --- Load data ---
df_inv = pd.read_csv(INV_CSV)
df_dcs2 = pd.read_csv(DCS2_CSV)
df_ddp = pd.read_csv(DDPHI_CSV)

k1, I1 = df_inv["k"].values, df_inv.iloc[:, 1].values
k2, dcs2 = df_dcs2["k"].values, df_dcs2.iloc[:, 1].values
k3, ddp = df_ddp["k"].values, df_ddp.iloc[:, 1].values

# Mask zeros for derivative of delta phi/phi
ddp_mask = np.ma.masked_where(np.abs(ddp) <= 0, np.abs(ddp))


# Function to annotate the plateau region
def zoom_plateau(ax, k, y):
    sel = k < k_split
    ysel = y[sel]
    if ysel.size == 0:
        return
    lo, hi = ysel.min(), ysel.max()
    ax.set_ylim(lo * 0.8, hi * 1.2)
    xm = k[sel][len(ysel) // 2]
    ym = np.sqrt(lo * hi)
    ax.text(
        xm,
        ym,
        "Plateau",
        ha="center",
        va="center",
        fontsize=7,
        bbox=dict(boxstyle="round", fc="white", alpha=0.7),
    )


# --- Create figure ---
fig, axs = plt.subplots(3, 1, figsize=(8, 14), sharex=True)

# 1) I₁ = c_s²/k
ax = axs[0]
ax.loglog(k1, I1, color="C0", label=r"$I_1 = c_s^2/k$")
ax.axvline(k_split, ls="--", color="k", lw=1)
zoom_plateau(ax, k1, I1)
ax.set_ylabel(r"$I_1(k)$", fontsize=10)
ax.legend(loc="upper right", fontsize=8, framealpha=0.8)
ax.grid(True, which="both", ls=":", linewidth=0.5)

# 2) |∂ₖ c_s²|
ax = axs[1]
ax.loglog(k2, np.abs(dcs2), color="C1", label=r"$|\partial_k c_s^2|$")
ax.axvline(k_split, ls="--", color="k", lw=1)
zoom_plateau(ax, k2, np.abs(dcs2))
ax.set_ylabel(r"$|\partial_k c_s^2|$", fontsize=10)
ax.legend(loc="upper right", fontsize=8, framealpha=0.8)
ax.grid(True, which="both", ls=":", linewidth=0.5)

# → Adjust upper limit to emphasize the peak
ymin, _ = ax.get_ylim()
ax.set_ylim(ymin, 1e1)

# 3) |∂ₖ(δφ/φ)|
ax = axs[2]
ax.loglog(
    k3,
    ddp_mask,
    color="C2",
    label=r"$|\partial_k(\delta\phi/\phi)|_{\mathrm{smooth}}$" )
ax.axvline(k_split, ls="--", color="k", lw=1)
zoom_plateau(ax, k3, ddp_mask)
ax.set_ylabel(r"$|\partial_k(\delta\phi/\phi)|$", fontsize=10)
ax.set_xlabel(r"$k\,[h/\mathrm{Mpc}]$", fontsize=10)
ax.legend(loc="upper right", fontsize=8, framealpha=0.8)
ax.grid(True, which="both", ls=":", linewidth=0.5)

# --- Title and layout ---
fig.suptitle("Comparaison des invariants et dérivées", fontsize=14)
fig.subplots_adjust(top=0.92, bottom=0.07, left=0.10, right=0.95, hspace=0.30)

# --- Save ---
FIG_OUT.parent.mkdir(parents=True, exist_ok=True)
fig.savefig(FIG_OUT, dpi=300)
logger.info("Figure saved → %s", FIG_OUT)
plt.close(fig)

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

    args = parserparser.add_argument(
        "--fmt",
        type=str,
        default=None,
        help="Format savefig (png, pdf, etc.)")
.parse_args()
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
