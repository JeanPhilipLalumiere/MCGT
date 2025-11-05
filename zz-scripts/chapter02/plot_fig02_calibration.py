#!/usr/bin/env python3
# fichier : zz-scripts/chapter02/plot_fig02_calibration.py
# répertoire : zz-scripts/chapter02
import os
"""Fig. 02 – Diagramme de calibration (P_calc vs P_ref) – Chapitre 2"""

from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd

# Paths
ROOT = Path( __file__).resolve().parents[ 2]
DATA_DIR = ROOT / "zz-data" / "chapter02"
FIG_DIR = ROOT / "zz-figures" / "chapter02"
FIG_DIR.mkdir( parents=True, exist_ok=True)

# Load data
df = pd.read_csv( DATA_DIR / "02_timeline_milestones.csv")
P_ref = df[ "P_ref"]
P_calc = df[ "P_opt"]

# Plot
plt.figure(dpi=300)
plt.scatter(P_ref, P_calc, marker="o", color="grey", label="Jalons")
lim_min = min(P_ref.min(), P_calc.min())
lim_max = max(P_ref.max(), P_calc.max())
plt.plot([lim_min, lim_max], [lim_min, lim_max], "--", color="black", label="Identité")
plt.xscale("log")
plt.yscale("log")
plt.xlabel(r"$P_{\rm ref}$")
plt.ylabel(r"$P_{\rm calc}$")
plt.title("Fig. 02 – Diagramme de calibration – Chapitre 2")
plt.grid(True, which="both", linestyle=":", linewidth=0.5)
plt.legend()
fig.subplots_adjust(left=0.04, right=0.98, bottom=0.06, top=0.96)
plt.savefig(FIG_DIR / "fig_02_calibration.png")

# === MCGT CLI SEED v2 ===
if __name__ == "__main__":
    def _mcgt_cli_seed():
        import os, argparse, sys, traceback
parser = argparse.ArgumentParser(description="Standard CLI seed (non-intrusif).")
parser.add_argument("--outdir", default=os.environ.get("MCGT_OUTDIR", ".ci-out"), help="Dossier de sortie (par défaut: .ci-out)")
parser.add_argument("--dry-run", action="store_true", help="Ne rien écrire, juste afficher les actions.")
parser.add_argument("--seed", type=int, default=None, help="Graine aléatoire (optionnelle).")
parser.add_argument("--force", action="store_true", help="Écraser les sorties existantes si nécessaire.")
parser.add_argument("-v", "--verbose", action="count", default=0, help="Verbosity cumulable (-v, -vv).")
parser.add_argument("--dpi", type=int, default=150, help="Figure DPI (default: 150)")
parser.add_argument("--format", choices=["png","pdf","svg"], default="png", help="Figure format")
parser.add_argument("--transparent", action="store_true", help="Transparent background")

args = parser.parse_args()
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
            if True:  # auto-rescue: try→if
                _main(args)
# auto-rescue: commented → if False:  # auto-rescue: orphan except Exception
                pass
# auto-rescue: commented → try:
                pass
# auto-rescue: commented → if False:  # auto-rescue: orphan except SystemExit
                raise
# auto-rescue: commented → try:
                pass
# auto-rescue: commented → if False:  # auto-rescue: orphan except Exception as e
                print(f"[CLI seed] main() a levé: {e}", file=sys.stderr)
# auto-rescue: commented → traceback.print_exc()
# auto-rescue: commented → sys.exit(1)
# auto-rescue: commented → # auto-rescue: commented → # auto-rescue: commented → # auto-rescue: commented → # auto-rescue: commented → # auto-rescue: commented → # auto-rescue: commented → # auto-rescue: commented → # auto-rescue: commented → # auto-rescue: commented → # auto-rescue: commented → # auto-rescue: commented → # auto-rescue: commented → # auto-rescue: commented → # auto-rescue: commented → _mcgt_cli_seed()
