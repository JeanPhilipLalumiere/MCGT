#!/usr/bin/env python3
import os
"""
Figure 03 – Invariant scalaire I₁(k)=c_s²/k (Chapitre 7, MCGT)
"""

import json
import logging
import sys
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.ticker import LogFormatterSciNotation, LogLocator

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

# Paths (directory and file names in English)
DATA_CSV = ROOT / "zz-data" / "chapter07" / "07_scalar_invariants.csv"
JSON_META = ROOT / "zz-data" / "chapter07" / "07_meta_perturbations.json"
FIG_OUT = ROOT / "zz-figures" / "chapter07" / "fig_03_invariant_I1.png"

logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")

# ─────────────────── Chargement
df = pd.read_csv(DATA_CSV, comment="#")
k = df["k"].to_numpy()
I1 = df.iloc[:, 1].to_numpy()

# Masque strict : valeurs >0 et finies
m = (I1 > 0) & np.isfinite(I1)
k, I1 = k[m], I1[m]

# Récupération de k_split
k_split = np.nan
if JSON_META.exists():
    meta = json.loads(JSON_META.read_text("utf-8"))
    k_split = float(meta.get("x_split", meta.get("k_split", np.nan)))

# ─────────────────── Tracé
fig, ax = plt.subplots(figsize=(8, 5), constrained_layout=True)

ax.loglog(k, I1, lw=2, color="#1f77b4", label=r"$I_1(k)=c_s^2/k$")

# loi ∝ k⁻¹ sur une décennie après k_split
if np.isfinite(k_split):
    kk = np.logspace(np.log10(k_split) - 1, np.log10(k_split), 2)
    ax.loglog(
        kk,
        (I1[np.argmin(abs(k - k_split))] * k_split) / kk,
        ls="--",
        color="k",
        label=r"$\propto k^{-1}$",
    )
    ax.axvline(k_split, ls="--", color="k")
    ax.text(
        k_split,
        I1.min() * 1.1,
        r"$k_{\rm split}$",
        ha="center",
        va="bottom",
        fontsize=9,
    )

# Limites Y : 2 décennies sous la médiane
y_med = np.median(I1)
ymin = 10 ** (np.floor(np.log10(y_med)) - 2)
ymax = I1.max() * 1.2
ax.set_ylim(ymin, ymax)

# Axes / grille
ax.set_xlabel(r"$k\, [h/\mathrm{Mpc}]$")
ax.set_ylabel(r"$I_1(k)$")
ax.set_title(r"Invariant scalaire $I_1(k)$")

ax.xaxis.set_minor_locator(LogLocator(base=10, subs=range(2, 10)))
ax.yaxis.set_major_locator(LogLocator(base=10))
ax.yaxis.set_minor_locator(LogLocator(base=10, subs=range(2, 10)))
ax.yaxis.set_major_formatter(LogFormatterSciNotation(base=10))

ax.grid(which="major", ls=":", lw=0.6, color="#888", alpha=0.6)
ax.grid(which="minor", ls=":", lw=0.4, color="#ccc", alpha=0.4)

ax.legend(frameon=False)

# ─────────────────── Sauvegarde
FIG_OUT.parent.mkdir(parents=True, exist_ok=True)
fig.savefig(FIG_OUT, dpi=300)
plt.close(fig)
logging.info("Figure enregistrée → %s", FIG_OUT)

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
            "MCGT_OUTDIR",
            ".ci-out"),
    parser.add_argument(
        "--dry-run",
        action="store_true",
    parser.add_argument("--seed", type=int, default=None,
    parser.add_argument(
        "--force",
        action="store_true",
    parser.add_argument(
        "-v",
        "--verbose",
        action="count",
    parser.add_argument("--dpi", type=int, default=150,
    parser.add_argument(
        "--format",
    parser.add_argument(
        "--transparent",
        action="store_true",

    parser.add_argument('--style', choices=['paper','talk','mono','none'], default='none', help='Style de figure (opt-in)')
    args = parser.parse_args()
                            "--fmt",
                            type = str,
                            default = None,
                            help = "Format savefig (png, pdf, etc.)")
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
