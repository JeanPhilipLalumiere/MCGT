#!/usr/bin/env python3
"""Fig. 05 – Invariant adimensionnel I1(T)"""

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

# Base du projet
BASE = Path(__file__).resolve().parents[2]


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

# Fichier de données (identique à la version originale)
DATA_FILE = BASE / "zz-data" / "chapter01" / "01_dimensionless_invariants.csv"

# Convention de sortie pour la figure publique
# (homogène avec les checks de rebuild : 01_fig_05_i1_vs_t.png)
DEFAULT_FIGNAME = "01_fig_05_i1_vs_t"

# Dossier de sortie par défaut :
#   - $MCGT_OUTDIR si présent
#   - sinon zz-figures/chapter01
DEFAULT_OUTDIR = Path(
    os.environ.get("MCGT_OUTDIR", BASE / "zz-figures" / "chapter01")
)


def make_figure(
    outdir: Path,
    dpi: int = 300,
    fmt: str = "png",
    transparent: bool = False,
    verbose: int = 0,
    dry_run: bool = False,
) -> Path:
    """
    Génère la figure I1(T) dans le dossier donné.

    La logique scientifique est celle de la version originale :
      - on lit 01_dimensionless_invariants.csv
      - on trace I1(T) en log-log
    """
    outdir = Path(outdir)
    outdir.mkdir(parents=True, exist_ok=True)

    output_path = outdir / f"{DEFAULT_FIGNAME}.{fmt}"

    if verbose:
        print(f"[plot_fig05_I1_vs_T] lecture DATA_FILE={DATA_FILE}")
        print(f"[plot_fig05_I1_vs_T] sortie -> {output_path}")

    if dry_run:
        return output_path

    # === Partie scientifique (inchangée sur le fond) ===
    df = pd.read_csv(DATA_FILE)
    T = df["T"]
    I1 = df["I1"]

    # On explicite fig/ax pour éviter le bug 'fig' non défini
    fig, ax = plt.subplots(dpi=dpi)
    ax.plot(T, I1, color="orange", label=r"$I_1 = P(T)/T$")
    ax.set_xscale("log")
    ax.set_yscale("log")
    ax.set_xlabel("T (Gyr)")
    ax.set_ylabel(r"$I_1$")
    ax.set_title("Fig. 05 – Invariant adimensionnel $I_1$ en fonction de $T$")
    ax.grid(True, which="both", ls=":", lw=0.5)
    ax.legend()

    fig.subplots_adjust(left=0.04, right=0.98, bottom=0.06, top=0.96)
    changed = safe_save(output_path, fig, transparent=transparent)
    if verbose:
        status = "enregistrée" if changed else "inchangée (hash identique)"
        print(f"[plot_fig05_I1_vs_T] figure {status} → {output_path}")

    return output_path


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(
        description="Standard CLI seed (non-intrusif) pour Fig. 05 – invariant adimensionnel I1(T)."
    )
    parser.add_argument(
        "--outdir",
        default=str(DEFAULT_OUTDIR),
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
        help="Écraser les sorties existantes si nécessaire (non utilisé explicitement, "
             "mais conservé pour homogénéité CLI).",
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

    try:
        make_figure(
            outdir=Path(args.outdir),
            dpi=args.dpi,
            fmt=args.format,
            transparent=args.transparent,
            verbose=args.verbose or 0,
            dry_run=args.dry_run,
        )
    except Exception as e:
        print(f"[plot_fig05_I1_vs_T] ERREUR : {e}", file=sys.stderr)
        traceback.print_exc()
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
