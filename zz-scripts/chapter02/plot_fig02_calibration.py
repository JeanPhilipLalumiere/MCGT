import hashlib
import shutil
import tempfile
import matplotlib.pyplot as _plt
from pathlib import Path as _SafePath

def _sha256(path: _SafePath) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()

def safe_save(filepath, fig=None, **savefig_kwargs):
    path = _SafePath(filepath)
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        with tempfile.NamedTemporaryFile(delete=False, suffix=path.suffix) as tmp:
            tmp_path = _SafePath(tmp.name)
        try:
            if fig is not None:
                fig.savefig(tmp_path, **savefig_kwargs)
            else:
                _plt.savefig(tmp_path, **savefig_kwargs)
            if _sha256(tmp_path) == _sha256(path):
                tmp_path.unlink()
                return False
            shutil.move(tmp_path, path)
            return True
        finally:
            if tmp_path.exists():
                tmp_path.unlink()
    if fig is not None:
        fig.savefig(path, **savefig_kwargs)
    else:
        _plt.savefig(path, **savefig_kwargs)
    return True

#!/usr/bin/env python3
"""Fig. 02 – Diagramme de calibration (P_calc vs P_ref) – Chapitre 2"""

import os
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd

plt.rcParams.update(
    {
        "figure.autolayout": True,
        "figure.figsize": (10, 6),
        "axes.titlepad": 20,
        "axes.labelpad": 12,
        "savefig.bbox": "tight",
        "font.family": "serif",
    }
)

# Racine du projet
ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = ROOT / "zz-data" / "chapter02"
DEFAULT_OUTDIR = ROOT / "zz-figures" / "chapter02"

# Nom canonique de la figure (cohérent avec le manifest/plan de rebuild)
FIG_STEM = "02_fig_02_calibration"


def main(args) -> None:
    """Génère la figure de calibration P_calc vs P_ref (Chapitre 2)."""
    # Résolution du dossier de sortie : priorité à MCGT_OUTDIR, sinon --outdir, sinon DEFAULT_OUTDIR
    outdir_env = os.environ.get("MCGT_OUTDIR")
    outdir = Path(outdir_env if outdir_env else args.outdir).resolve()
    outdir.mkdir(parents=True, exist_ok=True)

    data_file = DATA_DIR / "02_timeline_milestones.csv"

    if args.verbose:
        print(f"[plot_fig02_calibration] DATA_FILE={data_file}")
        print(f"[plot_fig02_calibration] OUTDIR={outdir}")

    # Lecture des données
    df = pd.read_csv(data_file)
    P_ref = df["P_ref"]
    P_calc = df["P_opt"]

    if args.dry_run:
        return

    # Tracé de la figure (log–log comme dans la version originale)
    fig, ax = plt.subplots()  # dpi géré via rcParams / args.dpi
    ax.scatter(P_ref, P_calc, marker="o", color="grey", label="Nodes")

    lim_min = min(P_ref.min(), P_calc.min())
    lim_max = max(P_ref.max(), P_calc.max())
    ax.plot([lim_min, lim_max], [lim_min, lim_max], "--", color="black", label="Identity")

    ax.set_xscale("log")
    ax.set_yscale("log")
    ax.set_xlabel("Reference Value")
    ax.set_ylabel("Calculated Value")
    ax.set_title("Calibration Diagram - Chapter 2")
    ax.grid(True, which="both", linestyle=":", linewidth=0.5)
    ax.legend()

    fig.subplots_adjust(left=0.04, right=0.98, bottom=0.06, top=0.96)

    out_path = outdir / f"{FIG_STEM}.{args.format}"
    safe_save(out_path, dpi=args.dpi, transparent=args.transparent)

    if args.verbose:
        print(f"[plot_fig02_calibration] sortie -> {out_path}")


# === MCGT CLI SEED v2 (homogène avec ch01) ===
if __name__ == "__main__":
    import argparse
    import sys
    import traceback

    import matplotlib as mpl

    parser = argparse.ArgumentParser(
        description="Standard CLI seed (non-intrusif) pour Fig. 02 – calibration P_calc vs P_ref (Chapitre 2)."
    )
    parser.add_argument(
        "--outdir",
        default=str(DEFAULT_OUTDIR),
        help="Dossier de sortie (par défaut: zz-figures/chapter02 ou $MCGT_OUTDIR).",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Ne rien écrire, juste afficher les actions.",
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=None,
        help="Graine aléatoire (optionnelle, non utilisée ici, pour homogénéité).",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Écraser les sorties existantes si nécessaire.",
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="count",
        default=0,
        help="Verbosity cumulable (-v, -vv).",
    )
    parser.add_argument(
        "--dpi",
        type=int,
        default=300,
        help="Figure DPI (default: 300).",
    )
    parser.add_argument(
        "--format",
        choices=["png", "pdf", "svg"],
        default="png",
        help="Figure format (default: png).",
    )
    parser.add_argument(
        "--transparent",
        action="store_true",
        help="Fond transparent pour la figure.",
    )

    args = parser.parse_args()

    # Config globale Matplotlib pour homogénéité
    mpl.rcParams["savefig.dpi"] = args.dpi
    mpl.rcParams["savefig.format"] = args.format
    mpl.rcParams["savefig.transparent"] = args.transparent

    try:
        main(args)
    except SystemExit:
        raise
    except Exception as e:
        print(f"[CLI seed] main() a levé: {e}", file=sys.stderr)
        traceback.print_exc()
        sys.exit(1)
