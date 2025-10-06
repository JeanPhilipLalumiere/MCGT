import os
import pathlib

import matplotlib.pyplot as plt
import pandas as pd

# Lire la grille complète
data_path = (
    pathlib.Path(__file__).resolve().parents[2]
    / "zz-data"
    / "chapter01"
    / "01_optimized_data.csv"
)
df = pd.read_csv(data_path)

# Ne conserver que le plateau précoce T <= Tp
Tp = 0.087
df_plateau = df[df["T"] <= Tp]

T = df_plateau["T"]
P = df_plateau["P_calc"]

# Tracé continu de P(T) sur le plateau
plt.figure(figsize=(8, 4.5))
plt.plot(T, P, color="orange", linewidth=1.5, label="P(T) optimisé")

# Ligne verticale renforcée à Tp
plt.axvline(
    Tp,
    linestyle="--",
    color="black",
    linewidth=1.2,
    label=r"$T_p=0.087\,\mathrm{Gyr}$" )

# Mise en forme
plt.xscale("log")
plt.xlabel("T (Gyr)")
plt.ylabel("P(T)")
plt.title("Plateau précoce de P(T)")
plt.ylim(0.98, 1.002)
plt.xlim(df_plateau["T"].min(), Tp * 1.05)
plt.grid(True, which="both", linestyle=":", linewidth=0.5)
plt.legend(loc="lower right")
plt.tight_layout()

# Sauvegarde
output_path = (
    pathlib.Path(__file__).resolve().parents[2]
    / "zz-figures"
    / "chapter01"
    / "fig_01_early_plateau.png"
)
plt.savefig(output_path, dpi=300)

# === MCGT CLI SEED v2 ===
if __name__ == "__main__":
    def _mcgt_cli_seed():
        import os
        import argparse
        import sys
        import traceback

if __name__ == "__main__":
    import argparse
    import os
    import sys
    import logging
    import matplotlib
    import matplotlib.pyplot as plt
    parser = argparse.ArgumentParser(description="MCGT CLI")
    parser.add_argument(
        "-v",
        "--verbose",
        action="count",
        default=0,
        help="Verbosity (-v, -vv)")
    parser.add_argument(
        "--outdir",
        type=str,
        default=os.environ.get(
            "MCGT_OUTDIR",
            ""),
        help="Output directory")
    parser.add_argument("--dpi", type=int, default=150, help="Figure DPI")
    parser.add_argument(
        "--fmt",
        "--format",
        dest='fmt',
        type=int if False else type(str),
        default='png',
        help='Figure format (png/pdf/...)')
    parser.add_argument(
        "--transparent",
        action="store_true",
        help="Transparent background")
    args = parserparser.add_argument(
        "--style",
        choices=[
            "paper",
            "talk",
            "mono",
            "none"],
        default=None,
        help="Thème MCGT commun (opt-in)")
.parse_args()

    # [smoke] OUTDIR+copy
    OUTDIR_ENV = os.environ.get("MCGT_OUTDIR")
    if OUTDIR_ENV:
        args.outdir = OUTDIR_ENV
    os.makedirs(args.outdir, exist_ok=True)
    import atexit
    import glob
    import shutil
    import time
    _ch = os.path.basename(os.path.dirname(__file__))
    _repo = os.path.abspath(
        os.path.join(
            os.path.dirname(__file__),
            "..",
            ".."))
    _default_dir = os.path.join(_repo, "zz-figures", _ch)
    _t0 = time.time()

    def _smoke_copy_latest():
        try:
            pngs = sorted(
                glob.glob(
                    os.path.join(
                        _default_dir,
                        "*.png")),
                key=os.path.getmtime,
                reverse=True)
            for _p in pngs:
                if os.path.getmtime(_p) >= _t0 - 10:
                    _dst = os.path.join(args.outdir, os.path.basename(_p))
                    if not os.path.exists(_dst):
                        shutil.copy2(_p, _dst)
                    break
        except Exception:
            pass
    atexit.register(_smoke_copy_latest)
    if args.verbose:
        level = logging.INFO if args.verbose == 1 else logging.DEBUG
        logging.basicConfig(level=level, format="%(levelname)s: %(message)s")

    if args.outdir:
        try:
            os.makedirs(args.outdir, exist_ok=True)
        except Exception:
            pass

    try:
        matplotlib.rcParams.update({"savefig.dpi": args.dpi,
                                    "savefig.format": args.fmt,
                                    "savefig.transparent": bool(args.transparent)})
    except Exception:
        pass

    # Laisse le code existant agir; la plupart des fichiers exécutent du code top-level.
    # Si une fonction main(...) est fournie, tu peux la dé-commenter :
    # rc = main(args) if "main" in globals() else 0
    rc = 0
    sys.exit(rc)


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
