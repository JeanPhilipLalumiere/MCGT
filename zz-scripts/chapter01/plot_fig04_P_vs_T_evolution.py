#!/usr/bin/env python3
import os
"""Fig. 04 – Évolution de P(T) : initial vs optimisé"""

from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd

# Configuration des chemins
base = Path(__file__).resolve().parents[2]
init_csv = base / "zz-data" / "chapter01" / "01_initial_grid_data.dat"
opt_csv = base / "zz-data" / "chapter01" / \
    "01_optimized_data_and_derivatives.csv"
output_file = base / "zz-figures" / "chapter01" / "fig_04_P_vs_T_evolution.png"

# Lecture des données
df_init = pd.read_csv(init_csv)
df_opt = pd.read_csv(opt_csv)
T_init = df_init["T"]
P_init = df_init["P"]
T_opt = df_opt["T"]
P_opt = df_opt["P"]

# Tracé de la figure
plt.figure(dpi=300)
plt.plot(T_init, P_init, "--", color="grey", label=r"$P_{\rm init}(T)$")
plt.plot(T_opt, P_opt, "-", color="orange", label=r"$P_{\rm opt}(T)$")
plt.xscale("log")
plt.yscale("linear")
plt.xlabel("T (Gyr)")
plt.ylabel("P(T)")
plt.title("Fig. 04 – Évolution de P(T) : initial vs optimisé")
plt.grid(True, which="both", linestyle=":", linewidth=0.5)
plt.legend()
plt.tight_layout()
plt.savefig(output_file)

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

    args = parser.parse_args()
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
