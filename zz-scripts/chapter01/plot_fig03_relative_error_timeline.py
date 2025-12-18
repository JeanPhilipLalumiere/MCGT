#!/usr/bin/env python3
"""Fig. 03 – Écarts relatifs ε_i"""

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

BASE = Path(__file__).resolve().parents[2]
DATA_FILE = BASE / "zz-data" / "chapter01" / "01_relative_error_timeline.csv"
DEFAULT_FIGNAME = "01_fig_03_relative_error_timeline"


def _sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()


def safe_save(filepath: Path | str, fig, **savefig_kwargs) -> bool:
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


def make_figure(output_path: Path, dpi: int = 300, transparent: bool = False, verbose: int = 0) -> None:
    """Construit la figure des écarts relatifs ε_i.

    Logique identique à la version originale :
    - lecture du même CSV
    - même tracé (points orange, symlog, seuils ±1%)
    """
    if verbose:
        print(f"[plot_fig03_relative_error_timeline] lecture DATA_FILE={DATA_FILE}")
        print(f"[plot_fig03_relative_error_timeline] sortie -> {output_path}")

    df = pd.read_csv(DATA_FILE)
    T = df["T"]
    eps = df["epsilon"]

    fig, ax = plt.subplots(dpi=dpi)
    ax.plot(T, eps, "o", color="orange", label="ε_i")

    ax.set_xscale("log")
    ax.set_yscale("symlog", linthresh=1e-4)

    # Seuil ±1 %
    ax.axhline(0.01, linestyle="--", color="grey", linewidth=1, label="Seuil ±1 %")
    ax.axhline(-0.01, linestyle="--", color="grey", linewidth=1)

    ax.set_xlabel("T (Gyr)")
    ax.set_ylabel("ε (écart relatif)")
    ax.set_title("Fig. 03 – Écarts relatifs (échelle symlog)")
    ax.grid(True, which="both", linestyle=":", linewidth=0.5)
    ax.legend()

    fig.subplots_adjust(left=0.04, right=0.98, bottom=0.06, top=0.96)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    changed = safe_save(output_path, fig, transparent=transparent)
    if verbose:
        status = "enregistrée" if changed else "inchangée (hash identique)"
        print(f"[plot_fig03_relative_error_timeline] figure {status} → {output_path}")


def main(argv=None) -> None:
    parser = argparse.ArgumentParser(
        description="Standard CLI seed (non-intrusif) pour Fig. 03 – écarts relatifs ε_i."
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

    outdir = Path(args.outdir)
    if not outdir.is_absolute():
        outdir = BASE / outdir

    outdir.mkdir(parents=True, exist_ok=True)
    output_path = outdir / f"{DEFAULT_FIGNAME}.{args.format}"

    if args.dry_run:
        print(f"[plot_fig03_relative_error_timeline] DRY-RUN -> {output_path}")
        return

    if output_path.exists() and not args.force:
        if args.verbose:
            print(
                f"[plot_fig03_relative_error_timeline] sortie existe déjà, utilise --force pour écraser : {output_path}"
            )
        return

    try:
        make_figure(output_path=output_path, dpi=args.dpi, transparent=args.transparent, verbose=args.verbose)
    except Exception as e:
        print(f"[plot_fig03_relative_error_timeline] erreur: {e}", file=sys.stderr)
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
