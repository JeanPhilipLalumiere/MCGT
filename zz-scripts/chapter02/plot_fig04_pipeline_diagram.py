#!/usr/bin/env python3
import os
"""Fig. 04 – Schéma de la chaîne de calibration – Chapitre 2"""

from pathlib import Path

import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch

# Paths
ROOT = Path(__file__).resolve().parents[2]
FIG_DIR = ROOT / "zz-figures" / "chapter02"
FIG_DIR.mkdir(parents=True, exist_ok=True)

fig, ax = plt.subplots(figsize=(8, 4), dpi=300)
ax.axis("off")

# Define steps (text, x-center, y-center)
steps = [
    ("Lecture des jalons\n$(T_i, P_{\\rm ref})$", 0.1, 0.5),
    ("Interpolation & intégration\n(02_P_vs_T_grid_data.dat)", 0.35, 0.5),
    ("Optimisation\n(segmentation & pénalités)", 0.6, 0.5),
    ("Export JSON &\nécarts", 0.85, 0.5),
]
width, height = 0.2, 0.15

# Draw boxes and texts
for text, xc, yc in steps:
    box = FancyBboxPatch(
        (xc - width / 2, yc - height / 2),
        width,
        height,
        boxstyle="round,pad=0.3",
        edgecolor="black",
        facecolor="white",
    )
    ax.add_patch(box)
    ax.text(xc, yc, text, ha="center", va="center", fontsize=8)

# Draw arrows
for i in range(len(steps) - 1):
    x0 = steps[i][1] + width / 2
    x1 = steps[i + 1][1] - width / 2
    y = steps[i][2]
    ax.annotate(
        "", xy=(
            x1, y), xytext=(
            x0, y), arrowprops=dict(
                arrowstyle="->", lw=1))

plt.title("Fig. 04 – Schéma de la chaîne de calibration\nChapitre 2", pad=20)
plt.tight_layout()
plt.savefig(FIG_DIR / "fig_04_schema_pipeline.png")

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
