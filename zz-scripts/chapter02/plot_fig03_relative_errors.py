#!/usr/bin/env python3
"""
Fig. 03 – Écarts relatifs ε_i – Chapitre 2

Nuage de points des écarts relatifs ε_i en fonction de T (Gyr),
avec distinction jalons primaires / ordre 2 et seuils 1 % / 10 %.

Entrée par défaut :
    zz-data/chapter02/02_timeline_milestones.csv

Sortie par défaut :
    zz-figures/chapter02/02_fig_03_relative_errors.png
"""

from __future__ import annotations

import argparse
import hashlib
import logging
import shutil
import tempfile
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


# ---------------------------------------------------------------------------
# Chemins de base
# ---------------------------------------------------------------------------
ROOT = Path(__file__).resolve().parents[2]
DEF_CSV = ROOT / "zz-data" / "chapter02" / "02_timeline_milestones.csv"
DEF_OUT = ROOT / "zz-figures" / "chapter02" / "02_fig_03_relative_errors.png"


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


# ---------------------------------------------------------------------------
# Logger
# ---------------------------------------------------------------------------
def setup_logger(verbosity: int) -> logging.Logger:
    if verbosity <= 0:
        level = logging.WARNING
    elif verbosity == 1:
        level = logging.INFO
    else:
        level = logging.DEBUG

    logging.basicConfig(
        level=level,
        format="[%(asctime)s] [%(levelname)s] %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )
    return logging.getLogger("fig03_relative_errors")


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------
def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Fig. 03 – Écarts relatifs ε_i – Chapitre 2"
    )
    parser.add_argument(
        "--timeline-csv",
        type=Path,
        default=DEF_CSV,
        help="CSV des jalons (par défaut: zz-data/chapter02/02_timeline_milestones.csv)",
    )
    parser.add_argument(
        "--out",
        type=Path,
        default=DEF_OUT,
        help="Image de sortie (par défaut: zz-figures/chapter02/02_fig_03_relative_errors.png)",
    )
    parser.add_argument(
        "--dpi",
        type=int,
        default=300,
        help="Résolution de la figure (DPI, défaut: 300)",
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="count",
        default=0,
        help="Verbosity cumulable (-v, -vv).",
    )
    return parser.parse_args(argv)


# ---------------------------------------------------------------------------
# Coeur du script
# ---------------------------------------------------------------------------
def main(argv: list[str] | None = None) -> None:
    args = parse_args(argv)
    log = setup_logger(args.verbose)

    csv_path: Path = args.timeline_csv
    out_path: Path = args.out

    if not csv_path.exists():
        raise SystemExit(f"CSV introuvable : {csv_path}")

    out_path.parent.mkdir(parents=True, exist_ok=True)

    log.info("Lecture des données depuis %s", csv_path)
    df = pd.read_csv(csv_path)

    # Colonnes attendues
    for col in ["T", "epsilon_i", "classe"]:
        if col not in df.columns:
            raise SystemExit(f"Colonne manquante dans {csv_path} : {col}")

    T = pd.to_numeric(df["T"], errors="coerce")
    eps = pd.to_numeric(df["epsilon_i"], errors="coerce")
    cls = df["classe"].astype(str)

    # Masque de validité de base
    m_valid = T.notna() & eps.notna()
    T = T[m_valid]
    eps = eps[m_valid]
    cls = cls[m_valid]

    # Masks de classe
    m_primary = cls == "primaire"
    m_order2 = cls != "primaire"

    log.debug("Points primaires : %d", int(m_primary.sum()))
    log.debug("Points ordre 2  : %d", int(m_order2.sum()))

    # ------------------------------------------------------------------
    # Figure
    # ------------------------------------------------------------------
    fig, ax = plt.subplots(figsize=(7.0, 5.0), dpi=args.dpi)

    ax.scatter(
        T[m_primary],
        eps[m_primary],
        marker="o",
        label="Primary nodes",
        color="black",
    )
    ax.scatter(
        T[m_order2],
        eps[m_order2],
        marker="s",
        label="Secondary nodes",
        color="grey",
    )

    ax.set_xscale("log")
    ax.set_yscale("symlog", linthresh=1e-3)

    # Lignes de seuil
    ax.axhline(
        0.01,
        linestyle="--",
        linewidth=0.8,
        color="blue",
        label="1% threshold",
    )
    ax.axhline(-0.01, linestyle="--", linewidth=0.8, color="blue")
    ax.axhline(
        0.10,
        linestyle=":",
        linewidth=0.8,
        color="red",
        label="10% threshold",
    )
    ax.axhline(-0.10, linestyle=":", linewidth=0.8, color="red")

    ax.set_xlabel(r"$T$ [Gyr]")
    ax.set_ylabel(r"$\varepsilon_i$")
    ax.set_title(r"Relative Errors $\varepsilon_i$ - Chapter 2")

    ax.grid(True, which="both", linestyle=":", linewidth=0.5, alpha=0.7)
    ax.legend()

    fig.subplots_adjust(left=0.12, right=0.98, bottom=0.10, top=0.93)

    safe_save(out_path, dpi=args.dpi, bbox_inches="tight")
    log.info("Figure enregistrée → %s", out_path)


if __name__ == "__main__":
    main()
