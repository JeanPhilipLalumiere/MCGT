#!/usr/bin/env python3
"""Fig. 01 – Pipeline de génération des données CMB (Chapitre 6)."""

from pathlib import Path
import logging

import matplotlib.pyplot as plt
from matplotlib.patches import FancyArrowPatch, Rectangle

# Racine du projet et dossier de sortie par défaut
ROOT = Path(__file__).resolve().parents[2]
DEFAULT_OUTDIR = ROOT / "zz-figures" / "chapter06"

logger = logging.getLogger(__name__)


def main(args) -> None:
    """Construit et sauvegarde le schéma du dataflow CMB."""

    # --- Logging ---
    level = logging.INFO if args.verbose else logging.WARNING
    logging.basicConfig(level=level, format="[%(levelname)s] %(message)s")

    # --- Résolution de l'outdir ---
    outdir = Path(args.outdir) if args.outdir else DEFAULT_OUTDIR
    outdir.mkdir(parents=True, exist_ok=True)
    out_path = outdir / f"06_fig_01_cmb_dataflow_diagram.{args.format}"

    if args.dry_run:
        logger.info("[dry-run] Schéma CMB serait enregistré -> %s", out_path)
        return

    # --- Figure setup ---
    fig, ax = plt.subplots(figsize=(10, 6), dpi=args.dpi)
    ax.axis("off")
    fig.suptitle(
        "Pipeline de génération des données CMB (Chapitre 6)",
        fontsize=14,
        fontweight="bold",
        y=0.96,
    )

    # --- Block parameters ---
    W, H = 0.26, 0.20  # largeur/hauteur des blocs
    Ymid = 0.45        # position centrale en Y
    DY = 0.25          # décalage vertical standard

    # --- Blocks definitions ---
    blocks = {
        "in": (0.05, Ymid, "pdot_plateau_z.dat", "#d7d7d7"),
        "scr": (0.36, Ymid, "generate_chapter06_data.py", "#a9dfbf"),
        "data": (
            0.67,
            Ymid + DY,
            "06_cls_*.dat\n06_delta_*.csv\n06_delta_rs_*.csv\n"
            "06_cmb_chi2_scan2D.csv\n06_params_cmb.json",
            "#d7d7d7",
        ),
        "fig": (
            0.67,
            Ymid - DY,
            "fig_02.png\nfig_03.png\nfig_04.png\nfig_05.png",
            "#d7d7d7",
        ),
    }

    # --- Draw blocks ---
    for x, y, label, color in blocks.values():
        ax.add_patch(Rectangle((x, y), W, H, facecolor=color, edgecolor="k", lw=1.2))
        ax.text(
            x + W / 2,
            y + H / 2,
            label,
            ha="center",
            va="center",
            fontsize=8,
            family="monospace",
        )

    # --- Arrow helpers ---
    def east_center(x, y):
        return (x + W, y + H / 2)

    def west_center(x, y):
        return (x, y + H / 2)

    def draw_arrow(start, end, text, x_off=0, y_off=0):
        ax.add_patch(
            FancyArrowPatch(
                start, end, arrowstyle="-|>", mutation_scale=15, lw=1.3, color="k"
            )
        )
        xm = 0.5 * (start[0] + end[0]) + x_off
        ym = 0.5 * (start[1] + end[1]) + y_off
        ax.text(xm, ym, text, ha="center", va="center", fontsize=9)

    # --- Draw arrows with adjusted offsets (identique à ta version) ---
    draw_arrow(
        east_center(*blocks["in"][:2]),
        west_center(*blocks["scr"][:2]),
        "1. Lecture pdot",
        y_off=-DY / 1.8,
    )

    draw_arrow(
        east_center(*blocks["scr"][:2]),
        west_center(*blocks["data"][:2]),
        "2. Génération données",
        x_off=+DY / 3,
        y_off=-DY / 8,
    )

    draw_arrow(
        east_center(*blocks["scr"][:2]),
        west_center(*blocks["fig"][:2]),
        "3. Export PNG",
        x_off=+DY / 4,
        y_off=+DY / 8,
    )

    # --- Finalize and save ---
    fig.subplots_adjust(left=0.04, right=0.98, bottom=0.06, top=0.96)
    fig.savefig(out_path, dpi=args.dpi, transparent=args.transparent)
    logger.info("Schéma enregistré → %s", out_path)


if __name__ == "__main__":
    def _mcgt_cli_seed():
        import argparse
        import os
        import sys
        import traceback

        parser = argparse.ArgumentParser(
            description=(
                "Standard CLI seed (non-intrusif) pour Fig. 01 – "
                "pipeline de génération des données CMB (Chapitre 6)."
            )
        )
        parser.add_argument(
            "--outdir",
            default=None,
            help=(
                "Dossier de sortie (par défaut: zz-figures/chapter06 "
                "ou $MCGT_OUTDIR)."
            ),
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
            help="Graine aléatoire (optionnelle, non utilisée ici).",
        )
        parser.add_argument(
            "--force",
            action="store_true",
            help="Écraser les sorties existantes si nécessaire (non strictement utilisé).",
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
            help="Format de sortie (par défaut: png).",
        )
        parser.add_argument(
            "--transparent",
            action="store_true",
            help="Fond transparent pour la figure.",
        )

        args = parser.parse_args()

        try:
            # Résolution de l'outdir (ENV prioritaire, puis défaut chapitre 6)
            if args.outdir is None:
                env_outdir = os.environ.get("MCGT_OUTDIR")
                if env_outdir:
                    args.outdir = env_outdir
                else:
                    args.outdir = str(DEFAULT_OUTDIR)
            os.environ["MCGT_OUTDIR"] = args.outdir

            import matplotlib as mpl
            mpl.rcParams["savefig.dpi"] = args.dpi
            mpl.rcParams["savefig.format"] = args.format
            mpl.rcParams["savefig.transparent"] = args.transparent
        except Exception:
            pass

        try:
            main(args)
        except SystemExit:
            raise
        except Exception as e:
            print(f"[CLI seed] main() a levé: {e}", file=sys.stderr)
            traceback.print_exc()
            sys.exit(1)

    _mcgt_cli_seed()
