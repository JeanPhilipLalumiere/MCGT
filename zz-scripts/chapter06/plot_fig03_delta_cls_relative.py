#!/usr/bin/env python3
import os
"""
Script de tracé fig_03_delta_cls_rel pour Chapitre 6 (Rayonnement CMB)
───────────────────────────────────────────────────────────────
Tracé de la différence relative ΔCℓ/Cℓ en fonction du multipôle ℓ,
avec annotation des paramètres MCGT (α, q0star).
"""

# --- IMPORTS & CONFIGURATION ---
import json
import logging
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

# Logging
logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")

# Paths
ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = ROOT / "zz-data" / "chapter06"
FIG_DIR = ROOT / "zz-figures" / "chapter06"
DELTA_CLS_REL_CSV = DATA_DIR / "06_delta_cls_relative.csv"
JSON_PARAMS = DATA_DIR / "06_params_cmb.json"
OUT_PNG = FIG_DIR / "fig_03_delta_cls_rel.png"
FIG_DIR.mkdir(parents=True, exist_ok=True)

# Load injection parameters
with open(JSON_PARAMS, encoding="utf-8") as f:
    params = json.load(f)
ALPHA = params.get("alpha", None)
Q0STAR = params.get("q0star", None)
logging.info(f"Tracé fig_03 avec α={ALPHA}, q0*={Q0STAR}")

# Load data
df = pd.read_csv(DELTA_CLS_REL_CSV)
ells = df["ell"].values
delta_rel = df["delta_Cl_rel"].values

# Plot
fig, ax = plt.subplots(figsize=(10, 6), dpi=300)
ax.plot(
    ells,
    delta_rel,
    linestyle="-",
    linewidth=2,
    color="tab:green",
    label=r"$\Delta C_\ell/C_\ell$",
)
ax.axhline(0, color="black", linestyle="--", linewidth=1)

ax.set_xscale("log")
ax.set_xlim(2, 3000)
ymax = np.max(np.abs(delta_rel)) * 1.1
ax.set_ylim(-ymax, ymax)

ax.set_xlabel(r"Multipôle $\ell$")
ax.set_ylabel(r"$\Delta C_{\ell}/C_{\ell}$")
ax.grid(True, which="both", linestyle=":", linewidth=0.5)
ax.legend(frameon=False, loc="upper right")

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

plt.tight_layout()
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
