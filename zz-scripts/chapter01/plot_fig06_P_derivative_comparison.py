#!/usr/bin/env python3
import os
# Fig.06 comparative dP/dT initial vs optimisé (lissé)
from pathlib import Path

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
plt.tight_layout()

out = (
    Path(__file__).resolve().parents[2]
    / "zz-figures"
    / "chapter01"
    / "fig_06_comparison.png"
)
plt.savefig(out)

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
    help="Thème MCGT commun (opt-in)")
.parse_args()
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
