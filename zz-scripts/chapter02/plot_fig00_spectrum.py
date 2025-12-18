#!/usr/bin/env python3
"""Fig. 00 – Spectre primordial P_R(k; α) pour quelques valeurs de α."""
from __future__ import annotations

import argparse
import hashlib
import os
import shutil
import sys
import tempfile
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "zz-scripts" / "chapter02"))

from primordial_spectrum import P_R  # noqa: E402

FIG_BASENAME = "02_fig_00_spectrum"
DEFAULT_CHAPTER_OUTDIR = ROOT / "zz-figures" / "chapter02"


def _sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()


def safe_save(filepath, fig=None, **savefig_kwargs):
    path = Path(filepath)
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        with tempfile.NamedTemporaryFile(delete=False, suffix=path.suffix) as tmp:
            tmp_path = Path(tmp.name)
        try:
            if fig is not None:
                fig.savefig(tmp_path, **savefig_kwargs)
            else:
                plt.savefig(tmp_path, **savefig_kwargs)
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
        plt.savefig(path, **savefig_kwargs)
    return True


def main(args: argparse.Namespace) -> None:
    # Dossier de sortie : priorité à l'argument, sinon $MCGT_OUTDIR, sinon zz-figures/chapter02
    outdir_str = args.outdir or os.environ.get("MCGT_OUTDIR") or str(DEFAULT_CHAPTER_OUTDIR)
    outdir = Path(outdir_str).expanduser()
    outdir.mkdir(parents=True, exist_ok=True)

    fname = f"{FIG_BASENAME}.{args.format}"
    output_path = outdir / fname

    if args.verbose:
        print(f"[plot_fig00_spectrum] outdir       = {outdir}")
        print(f"[plot_fig00_spectrum] output_path = {output_path}")

    if args.dry_run:
        if args.verbose:
            print("[plot_fig00_spectrum] dry-run -> aucune figure générée.")
        return

    # --- Logique scientifique inchangée ---
    # Grille de k et valeurs de alpha
    k = np.logspace(-4, 2, 100)
    alphas = [0.0, 0.05, 0.1]

    # Création de la figure
    fig, ax = plt.subplots(figsize=(6, 4))

    for alpha in alphas:
        ax.loglog(k, P_R(k, alpha), label=f"α = {alpha}")

    ax.set_xlabel("k [h·Mpc⁻¹]")
    ax.set_ylabel("P_R(k; α)", labelpad=12)
    ax.set_title("Spectre primordial MCGT")
    ax.legend(loc="upper right")
    ax.grid(True, which="both", linestyle="--", linewidth=0.5)

    fig.subplots_adjust(left=0.04, right=0.98, bottom=0.06, top=0.96)

    safe_save(
        output_path,
        dpi=args.dpi,
        transparent=args.transparent,
    )
    plt.close(fig)

    if args.verbose:
        print("[plot_fig00_spectrum] done.")


if __name__ == "__main__":

    def _mcgt_cli_seed() -> None:
        import traceback

        parser = argparse.ArgumentParser(
            description="Standard CLI seed (non-intrusif) pour Fig. 00 – spectre primordial MCGT.",
        )

        default_outdir = os.environ.get("MCGT_OUTDIR") or str(DEFAULT_CHAPTER_OUTDIR)
        parser.add_argument(
            "--outdir",
            default=default_outdir,
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

        try:
            main(args)
        except SystemExit:
            raise
        except Exception as e:  # noqa: BLE001
            print(f"[CLI seed] main() a levé: {e}", file=sys.stderr)
            traceback.print_exc()
            sys.exit(1)

    _mcgt_cli_seed()
