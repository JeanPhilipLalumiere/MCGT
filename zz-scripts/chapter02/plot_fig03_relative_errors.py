# === [HELP-SHIM v1] ===
try:
    import sys, os, argparse
    if any(a in ('-h','--help') for a in sys.argv[1:]):
        os.environ.setdefault('MPLBACKEND','Agg')
        parser = argparse.ArgumentParser(
            description="(shim) aide minimale sans effets de bord",
            add_help=True, allow_abbrev=False)
        try:
            from _common.cli import add_common_plot_args as _add
            _add(parser)
        except Exception:
            pass
        parser.add_argument('--out', help='fichier de sortie', default=None)
        parser.add_argument('--dpi', type=int, default=150)
        parser.add_argument('--log-level', choices=['DEBUG','INFO','WARNING','ERROR'], default='INFO')
        parser.print_help()
        sys.exit(0)
except SystemExit:
    raise
except Exception:
    pass
# === [/HELP-SHIM v1] ===

from _common import cli as C
import argparse
#!/usr/bin/env python3
# fichier : zz-scripts/chapter02/plot_fig03_relative_errors.py
# répertoire : zz-scripts/chapter02
import os
"""Fig. 03 – Écarts relatifs $\varepsilon_i$ – Chapitre 2"""

from pathlib import Path

from _common.cli import add_common_plot_args, finalize_plot_from_args, init_logging

import matplotlib.pyplot as plt
import pandas as pd

import matplotlib.pyplot as plt
import pandas as pd

# Paths
ROOT = Path( __file__).resolve().parents[ 2]
DATA_DIR = ROOT / "zz-data" / "chapter02"
FIG_DIR = ROOT / "zz-figures" / "chapter02"
FIG_DIR.mkdir( parents=True, exist_ok=True)

# Load data
df = pd.read_csv( DATA_DIR / "02_timeline_milestones.csv")
T = df[ "T"]
eps = df[ "epsilon_i"]
cls = df[ "classe"]

# Masks
primary = cls == "primaire"
order2 = cls != "primaire"

# Plot
plt.figure(dpi=300)
plt.scatter(
T[primary], eps[primary], marker="o", label="Jalons primaires", color="black"
)
plt.scatter(T[order2], eps[order2], marker="s", label="Jalons ordre 2", color="grey")
plt.xscale("log")
plt.yscale("symlog", linthresh=1e-3)
# Threshold lines
plt.axhline(0.01, linestyle="--", linewidth=0.8, color="blue", label="Seuil 1%")
plt.axhline(-0.01, linestyle="--", linewidth=0.8, color="blue")
plt.axhline(0.10, linestyle=":", linewidth=0.8, color="red", label="Seuil 10%")
plt.axhline(-0.10, linestyle=":", linewidth=0.8, color="red")
plt.xlabel("T (Gyr)")
plt.ylabel(r"$\varepsilon_i$")
plt.title("Fig. 03 – Écarts relatifs $\varepsilon_i$ – Chapitre 2")
plt.grid(True, which="both", linestyle=":", linewidth=0.5)
plt.legend()
fig.subplots_adjust(left=0.04, right=0.98, bottom=0.06, top=0.96)
# [mcgt-homog] plt.savefig(FIG_DIR / "fig_03_relative_errors.png")

# === MCGT CLI SEED v2 ===
if __name__ == "__main__":
    def _mcgt_cli_seed():
        import os, argparse, sys, traceback
parser = argparse.ArgumentParser(
# add_common_plot_args(parser)
description="Standard CLI seed (non-intrusif).")
add_common_plot_args(parser)
parser.add_argument("--outdir", default=os.environ.get("MCGT_OUTDIR", ".ci-out"), help="Dossier de sortie (par défaut: .ci-out)")
parser.add_argument("--dry-run", action="store_true", help="Ne rien écrire, juste afficher les actions.")
parser.add_argument("--seed", type=int, default=None, help="Graine aléatoire (optionnelle).")
parser.add_argument("--force", action="store_true", help="Écraser les sorties existantes si nécessaire.")
parser.add_argument("-v", "--verbose", action="count", default=0, help="Verbosity cumulable (-v, -vv).")
parser.add_argument("--dpi", type=int, default=150, help="Figure DPI (default: 150)")
parser.add_argument("--format", choices=["png","pdf","svg"], default="png", help="Figure format")
parser.add_argument("--transparent", action="store_true", help="Transparent background")
parser.add_argument("--out", default="plot.png", help="output image path")
parser.add_argument("--figsize", default="9,6", help="figure size W,H (inches)")
# [autofix] disabled top-level parse: args = parser.parse_args()
try:
            os.makedirs(args.outdir, exist_ok=True)
except Exception:
            pass
os.environ["MCGT_OUTDIR"] = args.outdir
import matplotlib as mpl
mpl.rcParams["savefig.dpi"] = args.dpi
mpl.rcParams["savefig.format"] = args.format
mpl.rcParams["savefig.transparent"] = args.transparent
try:
            pass
except Exception:
            pass
_main = globals().get("main")
if callable(_main):
            if True:
                _main(args)
                pass
                pass
                raise
                pass
                print(f"[CLI seed] main() a levé: {e}", file=sys.stderr)

__mcgt_out = finalize_plot_from_args(args)
def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="(autofix)",)
    C.add_common_plot_args(p)
    return p
