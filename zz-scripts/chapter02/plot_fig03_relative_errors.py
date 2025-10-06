#!/usr/bin/env python3
import os
"""Fig. 03 – Écarts relatifs $\varepsilon_i$ – Chapitre 2"""

from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd

# Paths
ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = ROOT / "zz-data" / "chapter02"
FIG_DIR = ROOT / "zz-figures" / "chapter02"
FIG_DIR.mkdir(parents=True, exist_ok=True)

# Load data
df = pd.read_csv(DATA_DIR / "02_timeline_milestones.csv")
T = df["T"]
eps = df["epsilon_i"]
cls = df["classe"]

# Masks
primary = cls == "primaire"
order2 = cls != "primaire"

# Plot
plt.figure(dpi=300)
plt.scatter(
    T[primary],
    eps[primary],
    marker="o",
    label="Jalons primaires",
    color="black" )
plt.scatter(
    T[order2],
    eps[order2],
    marker="s",
    label="Jalons ordre 2",
    color="grey")
plt.xscale("log")
plt.yscale("symlog", linthresh=1e-3)
# Threshold lines
plt.axhline(
    0.01,
    linestyle="--",
    linewidth=0.8,
    color="blue",
    label="Seuil 1%")
plt.axhline(-0.01, linestyle="--", linewidth=0.8, color="blue")
plt.axhline(0.10, linestyle=":", linewidth=0.8, color="red", label="Seuil 10%")
plt.axhline(-0.10, linestyle=":", linewidth=0.8, color="red")
plt.xlabel("T (Gyr)")
plt.ylabel(r"$\varepsilon_i$")
plt.title("Fig. 03 – Écarts relatifs $\varepsilon_i$ – Chapitre 2")
plt.grid(True, which="both", linestyle=":", linewidth=0.5)
plt.legend()
plt.tight_layout()
plt.savefig(FIG_DIR / "fig_03_relative_errors.png")

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

    parser.add_argument('--style', choices=['paper','talk','mono','none'], default='none', help='Style de figure (opt-in)')
    args = parser.parse_args()
                            "--fmt",
                            type=str,
                            default=None,
                            help="Format savefig (png, pdf, etc.)")
parser.add_argument(
    "--style",
    choices=[
        "paper",
        "talk",
        "mono",
        "none"],
    default=None,
    help="Thème MCGT commun (opt-in)").parse_args()
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
