#!/usr/bin/env python3
"""Fig. 02 – Diagramme de calibration P_ref vs P_calc"""

from pathlib import Path
import argparse
import os
import sys
import traceback

import matplotlib.pyplot as plt
import pandas as pd
from scipy.interpolate import interp1d

# Références de base (identiques à l’ancienne version)
BASE = Path(__file__).resolve().parents[2]
DATA_REF = BASE / "zz-data" / "chapter01" / "01_timeline_milestones.csv"
DATA_OPT = BASE / "zz-data" / "chapter01" / "01_optimized_data.csv"

# Nom canonique pour la figure (aligné sur la convention 01_fig_XX_*)
DEFAULT_FIGNAME = "01_fig_02_logistic_calibration"


def make_figure(output_path: Path, dpi: int = 300, transparent: bool = False, verbose: int = 0) -> None:
    """Construit la figure de calibration P_ref vs P_calc.

    Logique scientifique identique à la version originale :
    - lecture des mêmes fichiers
    - même interpolation P_calc(T) sur la grille de ref
    - même tracé log–log + droite d'identité
    """
    if verbose:
        print(f"[plot_fig02_logistic_calibration] lecture DATA_REF={DATA_REF}")
        print(f"[plot_fig02_logistic_calibration] lecture DATA_OPT={DATA_OPT}")
        print(f"[plot_fig02_logistic_calibration] sortie -> {output_path}")

    df_ref = pd.read_csv(DATA_REF)
    df_opt = pd.read_csv(DATA_OPT)

    interp = interp1d(df_opt["T"], df_opt["P_calc"], fill_value="extrapolate")
    P_calc_ref = interp(df_ref["T"])

    fig, ax = plt.subplots(dpi=dpi)
    ax.loglog(df_ref["P_ref"], P_calc_ref, "o", label="Données calibration")

    minv = min(df_ref["P_ref"].min(), P_calc_ref.min())
    maxv = max(df_ref["P_ref"].max(), P_calc_ref.max())
    ax.plot([minv, maxv], [minv, maxv], "--", label="Identité (y = x)")

    ax.set_xlabel(r"$P_{\mathrm{ref}}$")
    ax.set_ylabel(r"$P_{\mathrm{calc}}$")
    ax.set_title("Fig. 02 – Calibration log–log")
    ax.grid(True, which="both", ls=":", lw=0.5)
    ax.legend()

    fig.subplots_adjust(left=0.04, right=0.98, bottom=0.06, top=0.96)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(output_path, transparent=transparent)


def main(argv=None) -> None:
    parser = argparse.ArgumentParser(
        description="Standard CLI seed (non-intrusif) pour Fig. 02 – calibration P_ref vs P_calc."
    )
    parser.add_argument(
        "--outdir",
        default=os.environ.get("MCGT_OUTDIR", "zz-figures/chapter01"),
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

    args = parser.parse_args(argv)

    # Résolution de outdir par rapport à la racine du repo (comme les anciens scripts)
    outdir = Path(args.outdir)
    if not outdir.is_absolute():
        outdir = BASE / outdir

    outdir.mkdir(parents=True, exist_ok=True)
    output_path = outdir / f"{DEFAULT_FIGNAME}.{args.format}"

    if args.dry_run:
        print(f"[plot_fig02_logistic_calibration] DRY-RUN -> {output_path}")
        return

    if output_path.exists() and not args.force:
        if args.verbose:
            print(
                f"[plot_fig02_logistic_calibration] sortie existe déjà, utilise --force pour écraser : {output_path}"
            )
        return

    try:
        make_figure(output_path=output_path, dpi=args.dpi, transparent=args.transparent, verbose=args.verbose)
    except Exception as e:
        print(f"[plot_fig02_logistic_calibration] erreur: {e}", file=sys.stderr)
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
