#!/usr/bin/env python3
import os
"""Fig. 01 – Évolution de P(T) – Chapitre 2 (Validation chronologique)"""

from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

# Paths
ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = ROOT / "zz-data" / "chapter02"
FIG_DIR = ROOT / "zz-figures" / "chapter02"
FIG_DIR.mkdir(parents=True, exist_ok=True)

# Load data
T_dense, P_dense = np.loadtxt(
    DATA_DIR / "02_P_vs_T_grid_data.dat", unpack=True)
results = pd.read_csv(DATA_DIR / "02_timeline_milestones.csv")
T_ref = results["T"]
P_ref = results["P_ref"]

# Plot
plt.figure(dpi=300)
plt.plot(T_dense, P_dense, "-", label=r"$P_{\rm calc}(T)$", color="orange")
plt.scatter(
    T_ref,
    P_ref,
    marker="o",
    label=r"$P_{\rm ref}(T_i)$",
    color="grey")
plt.xscale("log")
plt.yscale("log")
plt.xlabel("T (Gyr)")
plt.ylabel("P(T)")
plt.title("Fig. 01 – Évolution de P(T) – Chapitre 2")
plt.grid(True, which="both", linestyle=":", linewidth=0.5)
plt.legend()
plt.tight_layout()
plt.savefig(FIG_DIR / "fig_01_P_vs_T_evolution.png")

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
