from _common import cli as C
import argparse
#!/usr/bin/env python3
# fichier : zz-scripts/chapter01/plot_fig06_P_derivative_comparison.py
# répertoire : zz-scripts/chapter01
import os
# Fig.06 comparative dP/dT initial vs optimisé (lissé)
from pathlib import Path

from _common.cli import add_common_plot_args, finalize_plot_from_args, init_logging

import matplotlib.pyplot as plt
import pandas as pd

base = Path(__file__).resolve().parents[2] / "zz-data" / "chapter01"
df_init = pd.read_csv(base / "01_P_derivative_initial.csv")
df_opt = pd.read_csv(base / "01_P_derivative_optimized.csv")

T_i, dP_i = df_init["T"], df_init["dP_dT"]
T_o, dP_o = df_opt["T"], df_opt["dP_dT"]

plt.figure(figsize=(8, 4.5), dpi=300)
plt.plot(T_i, dP_i, "--", color="gray", label=r"$\dot P_{\rm init}$ (lissé)")
plt.plot(T_o, dP_o, "-", color="orange", label=r"$\dot P_{\rm opt}$ (lissé)")
plt.xscale("log")
plt.xlabel("T (Gyr)")
plt.ylabel(r"$\dot P\,(\mathrm{Gyr}^{-1})$")
plt.title(r"Fig. 06 – $\dot{P}(T)$ initial vs optimisé")
plt.grid(True, which="both", linestyle=":", linewidth=0.5)
plt.legend(loc="center right")
fig.subplots_adjust(left=0.04, right=0.98, bottom=0.06, top=0.96)

out = (
Path(__file__).resolve().parents[2]
/ "zz-figures"
/ "chapter01"
/ "fig_06_comparison.png"
)
# [mcgt-homog] plt.savefig(out)

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
