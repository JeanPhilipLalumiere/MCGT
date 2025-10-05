import os
# ruff: noqa: E402
import sys
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np

# Ajouter le module primordial_spectrum au PYTHONPATH
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "zz-scripts" / "chapter02"))

from primordial_spectrum import P_R

# Grille de k et valeurs de alpha
k = np.logspace(-4, 2, 100)
alphas = [0.0, 0.05, 0.1]

# Création de la figure
fig, ax = plt.subplots(figsize=(6, 4))

for alpha in alphas:
    ax.loglog(k, P_R(k, alpha), label=f"α = {alpha}")

ax.set_xlabel("k [h·Mpc⁻¹]")
ax.set_ylabel("P_R(k; α)", labelpad=12)  # labelpad pour décaler plus à droite
ax.set_title("Spectre primordial MCGT")
ax.legend(loc="upper right")
ax.grid(True, which="both", linestyle="--", linewidth=0.5)

# Ajuster les marges pour que tout soit visible
plt.tight_layout()

# Sauvegarde
OUT = ROOT / "zz-figures" / "chapter02" / "fig_00_spectrum.png"
OUT.parent.mkdir(parents=True, exist_ok=True)
plt.savefig(OUT, dpi=300)
print(f"Figure enregistrée → {OUT}")

# === MCGT CLI SEED v2 ===
if __name__ == "__main__":
    def _mcgt_cli_seed():
        import os, argparse, sys, traceback

if __name__ == "__main__":
    import argparse, os, sys, logging
    import matplotlib
    import matplotlib.pyplot as plt
    parser = argparse.ArgumentParser(description="MCGT CLI")
    parser.add_argument("-v","--verbose", action="count", default=0, help="Verbosity (-v, -vv)")
    parser.add_argument("--outdir", type=str, default=os.environ.get("MCGT_OUTDIR",""), help="Output directory")
    parser.add_argument("--dpi", type=int, default=150, help="Figure DPI")
    parser.add_argument("--fmt", type=str, default="png", help="Figure format (png/pdf/...)")
    parser.add_argument("--transparent", action="store_true", help="Transparent background")
    args = parser.parse_args()

    if args.verbose:
        level = logging.INFO if args.verbose==1 else logging.DEBUG
        logging.basicConfig(level=level, format="%(levelname)s: %(message)s")

    if args.outdir:
        try:
            os.makedirs(args.outdir, exist_ok=True)
        except Exception:
            pass

    try:
        matplotlib.rcParams.update({"savefig.dpi": args.dpi, "savefig.format": args.fmt, "savefig.transparent": bool(args.transparent)})
    except Exception:
        pass

    # Laisse le code existant agir; la plupart des fichiers exécutent du code top-level.
    # Si une fonction main(...) est fournie, tu peux la dé-commenter :
    # rc = main(args) if "main" in globals() else 0
    rc = 0
    sys.exit(rc)

