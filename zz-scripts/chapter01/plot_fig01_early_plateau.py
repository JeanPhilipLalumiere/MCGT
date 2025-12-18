#!/usr/bin/env python3
"""
Fig. 01 – Plateau précoce de P(T)
"""

from __future__ import annotations

import argparse
import os
import sys
import traceback
import hashlib
import shutil
import tempfile
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd

plt.rcParams.update(
    {
        "figure.autolayout": True,
        "figure.figsize": (10, 6),
        "axes.titlesize": 14,
        "axes.titlepad": 20,
        "axes.labelsize": 12,
        "axes.labelpad": 12,
        "savefig.bbox": "tight",
        "savefig.pad_inches": 0.2,
        "font.family": "serif",
    }
)

# --- Paths de base (homogènes chapitre 01) ---
ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = ROOT / "zz-data" / "chapter01"
FIG_DIR = ROOT / "zz-figures" / "chapter01"

DATA_FILE = DATA_DIR / "01_optimized_data.csv"
DEFAULT_FIG_NAME = "01_fig_01_early_plateau.png"


def _sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()


def safe_save(filepath: Path | str, fig, **savefig_kwargs) -> bool:
    """
    Sauvegarde en évitant de toucher le mtime si le rendu est identique.
    Retourne True si le fichier a changé, False sinon.
    """
    path = Path(filepath)
    path.parent.mkdir(parents=True, exist_ok=True)

    if path.exists():
        with tempfile.NamedTemporaryFile(delete=False, suffix=path.suffix) as tmp:
            tmp_path = Path(tmp.name)
        try:
            fig.savefig(tmp_path, **savefig_kwargs)
            if _sha256(tmp_path) == _sha256(path):
                tmp_path.unlink()
                return False
            shutil.move(tmp_path, path)
            return True
        finally:
            if tmp_path.exists():
                tmp_path.unlink()

    fig.savefig(path, **savefig_kwargs)
    return True


def main(args: argparse.Namespace) -> None:
    """
    Génère la figure du plateau précoce de P(T).

    La logique scientifique est identique à la version originale :
    - lecture de 01_optimized_data.csv
    - sélection T <= Tp avec Tp = 0.087
    - tracé P_calc(T) en orange + ligne verticale à Tp
    """

    # Dossier de sortie canonique : zz-figures/chapter01 par défaut
    outdir_str = args.outdir or os.environ.get("MCGT_OUTDIR") or str(FIG_DIR)
    outdir = Path(outdir_str).resolve()
    outdir.mkdir(parents=True, exist_ok=True)
    output_path = outdir / DEFAULT_FIG_NAME

    if args.verbose:
        print(f"[plot_fig01_early_plateau] DATA_FILE = {DATA_FILE}")
        print(f"[plot_fig01_early_plateau] outdir     = {outdir}")
        print(f"[plot_fig01_early_plateau] output     = {output_path}")

    # Lecture des données
    df = pd.read_csv(DATA_FILE)

    # Ne conserver que le plateau précoce T <= Tp
    Tp = 0.087
    df_plateau = df[df["T"] <= Tp].copy()

    T = df_plateau["T"]
    P = df_plateau["P_calc"]

    # Tracé : même esthétique que l’original
    fig, ax = plt.subplots(figsize=(8, 4.5))

    ax.plot(T, P, color="orange", linewidth=1.5, label="P(T) optimisé")

    # Ligne verticale renforcée à Tp
    ax.axvline(
        Tp,
        linestyle="--",
        color="black",
        linewidth=1.2,
        label=r"$T_p=0.087\,\mathrm{Gyr}$",
    )

    # Mise en forme
    ax.set_xscale("log")
    ax.set_xlabel(r"$T$ [Gyr]")
    ax.set_ylabel(r"$P(T)$ [arbitrary units]")
    ax.set_title("Early Plateau of P(T)")
    ax.set_ylim(0.98, 1.002)
    ax.set_xlim(df_plateau["T"].min(), Tp * 1.05)
    ax.grid(True, which="both", linestyle=":", linewidth=0.5)
    ax.legend(loc="lower right")

    fig.subplots_adjust(left=0.04, right=0.98, bottom=0.06, top=0.96)

    if args.dry_run and not args.force:
        if args.verbose:
            print(
                f"[plot_fig01_early_plateau] dry-run: figure NON écrite (cible: {output_path})"
            )
        return

    changed = safe_save(
        output_path,
        fig,
        dpi=args.dpi,
        format=args.format,
        transparent=args.transparent,
    )

    if args.verbose:
        status = "enregistrée" if changed else "inchangée (hash identique)"
        print(f"[plot_fig01_early_plateau] figure {status} → {output_path}")


# === MCGT CLI SEED v2 (homogène) ===
def _mcgt_cli_seed() -> None:
    parser = argparse.ArgumentParser(
        description=(
            "Standard CLI seed (non-intrusif) pour "
            "Fig. 01 – plateau précoce de P(T)."
        )
    )
    parser.add_argument(
        "--outdir",
        default=os.environ.get("MCGT_OUTDIR", ""),
        help="Dossier de sortie (par défaut: zz-figures/chapter01 ou $MCGT_OUTDIR).",
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

    # Config globale Matplotlib
    import matplotlib as mpl

    mpl.rcParams["savefig.dpi"] = args.dpi
    mpl.rcParams["savefig.format"] = args.format
    mpl.rcParams["savefig.transparent"] = args.transparent

    # Outdir dans l’environnement pour homogénéité
    outdir_env = args.outdir or str(FIG_DIR)
    os.makedirs(outdir_env, exist_ok=True)
    os.environ["MCGT_OUTDIR"] = outdir_env

    try:
        main(args)
    except SystemExit:
        raise
    except Exception as e:
        print(f"[CLI seed] main() a levé: {e}", file=sys.stderr)
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    _mcgt_cli_seed()
