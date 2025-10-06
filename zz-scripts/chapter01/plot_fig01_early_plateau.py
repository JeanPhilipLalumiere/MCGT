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
    args = parser.parse_args()

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


# [MCGT POSTPARSE EPILOGUE v1]
try:
    # On n agit que si un objet args existe au global
    if "args" in globals():
        import os
        import atexit
        # 1) Fallback via MCGT_OUTDIR si outdir est vide/None
        env_out = os.environ.get("MCGT_OUTDIR")
        if getattr(args, "outdir", None) in (None, "", False) and env_out:
            args.outdir = env_out
        # 2) Création sûre du répertoire s il est défini
        if getattr(args, "outdir", None):
            try:
                os.makedirs(args.outdir, exist_ok=True)
            except Exception:
                pass
        # 3) rcParams savefig si des attributs existent
        try:
            import matplotlib
            _rc = {}
            if hasattr(args, "dpi") and args.dpi:
                _rc["savefig.dpi"] = args.dpi
            if hasattr(args, "fmt") and args.fmt:
                _rc["savefig.format"] = args.fmt
            if hasattr(args, "transparent"):
                _rc["savefig.transparent"] = bool(args.transparent)
            if _rc:
                matplotlib.rcParams.update(_rc)
        except Exception:
            pass
        # 4) Copier automatiquement le dernier PNG vers outdir à la fin

        def _smoke_copy_latest():
            try:
                if not getattr(args, "outdir", None):
                    return
                import glob
                import os
                import shutil
                _ch = os.path.basename(os.path.dirname(__file__))
                _repo = os.path.abspath(
                    os.path.join(
                        os.path.dirname(__file__),
                        "..",
                        ".."))
                _default_dir = os.path.join(_repo, "zz-figures", _ch)
                pngs = sorted(
                    glob.glob(os.path.join(_default_dir, "*.png")),
                    key=os.path.getmtime,
                    reverse=True,
                )
                for _p in pngs:
                    if os.path.exists(_p):
                        _dst = os.path.join(args.outdir, os.path.basename(_p))
                        if not os.path.exists(_dst):
                            shutil.copy2(_p, _dst)
                        break
            except Exception:
                pass
        atexit.register(_smoke_copy_latest)
except Exception:
    # épilogue best-effort — ne doit jamais casser le script principal
    pass
