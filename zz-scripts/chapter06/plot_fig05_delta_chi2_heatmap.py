#!/usr/bin/env python3
"""
Script de tracé fig_05_heatmap_delta_chi2 pour Chapitre 6 (Rayonnement CMB)
───────────────────────────────────────────────────────────────
Affiche la carte de chaleur 2D de Δχ² en fonction de α et q0star.
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
DATA_CSV = DATA_DIR / "06_cmb_chi2_scan2D.csv"
JSON_PARAMS = DATA_DIR / "06_params_cmb.json"
OUT_PNG = FIG_DIR / "fig_05_heatmap_delta_chi2.png"
FIG_DIR.mkdir(parents=True, exist_ok=True)

# Load injection parameters for annotation
with open(JSON_PARAMS, encoding="utf-8") as f:
    params = json.load(f)
ALPHA = params.get("alpha", None)
Q0STAR = params.get("q0star", None)
logging.info(f"Tracé fig_05 avec α={ALPHA}, q0*={Q0STAR}")

# Load scan 2D data
df = pd.read_csv(DATA_CSV)
alphas = np.sort(df["alpha"].unique())
q0s = np.sort(df["q0star"].unique())

# Pivot into matrix
chi2_mat = (
    df.pivot(index="q0star", columns="alpha", values="chi2").loc[q0s, alphas].values
)

# Compute cell edges for pcolormesh
da = alphas[1] - alphas[0]
dq = q0s[1] - q0s[0]
alpha_edges = np.concatenate([alphas - da / 2, [alphas[-1] + da / 2]])
q0_edges = np.concatenate([q0s - dq / 2, [q0s[-1] + dq / 2]])

# Create figure
fig, ax = plt.subplots(figsize=(10, 6), dpi=300)
pcm = ax.pcolormesh(alpha_edges, q0_edges, chi2_mat, shading="auto", cmap="viridis")
cbar = fig.colorbar(pcm, ax=ax, label=r"$\Delta\chi^2$")

# Aesthetics
ax.set_title(
    r"Carte de chaleur $\Delta\chi^2$ (Chapitre 6)", fontsize=14, fontweight="bold"
)
ax.set_xlabel(r"$\alpha$")
ax.set_ylabel(r"$q_0^*$")
ax.grid(which="major", linestyle=":", linewidth=0.5)
ax.grid(which="minor", linestyle=":", linewidth=0.3)
ax.minorticks_on()

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
logging.info(f"Carte de chaleur enregistrée → {OUT_PNG}")

# === MCGT CLI SEED v1 ===
if __name__ == "__main__":
    def _mcgt_cli_seed():
        import os, argparse, sys, traceback
        parser = argparse.ArgumentParser(description="Standard CLI seed (non-intrusif).")
        parser.add_argument("--outdir", default=os.environ.get("MCGT_OUTDIR", ".ci-out"), help="Dossier de sortie (par défaut: .ci-out)")
        parser.add_argument("--dry-run", action="store_true", help="Ne rien écrire, juste afficher les actions.")
        parser.add_argument("--seed", type=int, default=None, help="Graine aléatoire (optionnelle).")
        parser.add_argument("--force", action="store_true", help="Écraser les sorties existantes si nécessaire.")
        parser.add_argument("-v", "--verbose", action="count", default=0, help="Verbosity cumulable (-v, -vv).")
        args = parser.parse_args()
        try:
            os.makedirs(args.outdir, exist_ok=True)
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



# === MCGT:CLI-SHIM-BEGIN ===
# Idempotent. Expose: --out/--dpi/--format/--transparent/--style/--verbose
# Ne modifie pas la logique existante : parse_known_args() au module-scope.

def _mcgt_cli_shim_parse_known():
    import argparse, sys
    p = argparse.ArgumentParser(add_help=False)
    p.add_argument("--out", type=str, default=None, help="Chemin de sortie (optionnel).")
    p.add_argument("--dpi", type=int, default=None, help="DPI de sortie (optionnel).")
    p.add_argument("--format", type=str, default=None, choices=["png","pdf","svg"], help="Format de sortie.")
    p.add_argument("--transparent", action="store_true", help="Fond transparent si supporté.")
    p.add_argument("--style", type=str, default=None, help="Style matplotlib (optionnel).")
    p.add_argument("--verbose", action="store_true", help="Verbosité accrue.")
    args, _ = p.parse_known_args(sys.argv[1:])
    try:
        import matplotlib as _mpl
        if args.style:
            import matplotlib.pyplot as _plt  # force init si besoin
            _mpl.style.use(args.style)
        if args.dpi and hasattr(_mpl, "rcParams"):
            _mpl.rcParams["figure.dpi"] = int(args.dpi)
    except Exception:
        # Ne jamais casser le producteur si style/DPI échoue.
        pass
    return args

try:
    MCGT_CLI = _mcgt_cli_shim_parse_known()
except Exception:
    MCGT_CLI = None
# === MCGT:CLI-SHIM-END ===

