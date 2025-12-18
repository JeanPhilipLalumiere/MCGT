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
"""
plot_fig02_invariants_histogram.py

Fig. 02 – Histogramme des invariants adimensionnels (chapter 04).

- Lit : zz-data/chapter04/04_dimensionless_invariants.csv
- Construit log10(I2) et log10(|I3|) avec filtrage des valeurs non valides
- Trace les deux distributions sur des bins communs
- Sauvegarde : zz-figures/chapter04/04_fig_02_invariants_histogram.png
"""

from __future__ import annotations

import argparse
import logging
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd


# ---------- chemins par défaut ----------

ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = ROOT / "zz-data" / "chapter04"
FIG_DIR = ROOT / "zz-figures" / "chapter04"

DEF_CSV = DATA_DIR / "04_dimensionless_invariants.csv"
DEF_OUT = FIG_DIR / "04_fig_02_invariants_histogram.png"


# ---------- logging ----------

def setup_logger(level: str) -> logging.Logger:
    logging.basicConfig(
        level=getattr(logging, level),
        format="[%(asctime)s] [%(levelname)s] %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )
    return logging.getLogger("fig04_02_invariants")


# ---------- CLI ----------

def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description=(
            "Fig. 02 — Histogramme des invariants adimensionnels "
            "(log10(I2) et log10(|I3|))."
        )
    )
    p.add_argument(
        "--csv",
        type=Path,
        default=DEF_CSV,
        help=f"CSV des invariants (défaut: {DEF_CSV})",
    )
    p.add_argument(
        "--out",
        type=Path,
        default=DEF_OUT,
        help=f"Image de sortie (PNG, défaut: {DEF_OUT})",
    )
    p.add_argument(
        "--dpi",
        type=int,
        default=300,
        help="DPI de la figure (défaut: 300)",
    )
    p.add_argument(
        "--bins",
        type=int,
        default=40,
        help="Nombre de bins communs pour les deux histogrammes (défaut: 40)",
    )
    p.add_argument(
        "--log-level",
        choices=["DEBUG", "INFO", "WARNING", "ERROR"],
        default="INFO",
        help="Niveau de log (défaut: INFO)",
    )
    p.add_argument(
        "-v",
        "--verbose",
        action="count",
        default=0,
        help="Verbosity cumulable (-v → DEBUG).",
    )
    return p.parse_args()


# ---------- cœur du script ----------

def load_invariants(csv_path: Path, log: logging.Logger):
    if not csv_path.exists():
        raise SystemExit(f"CSV introuvable : {csv_path}")

    df = pd.read_csv(csv_path)

    if not {"I2", "I3"}.issubset(df.columns):
        raise SystemExit("Colonnes requises absentes dans le CSV (I2, I3).")

    I2 = df["I2"].to_numpy(float)
    I3 = df["I3"].to_numpy(float)

    m2 = np.isfinite(I2) & (I2 > 0.0)
    m3 = np.isfinite(I3) & (I3 != 0.0)

    if not m2.any():
        log.warning("Aucune valeur valide pour I2 > 0 ; histogramme I2 vide.")
        logI2 = np.array([], dtype=float)
    else:
        logI2 = np.log10(I2[m2])

    if not m3.any():
        log.warning("Aucune valeur non nulle pour I3 ; histogramme I3 vide.")
        logI3 = np.array([], dtype=float)
    else:
        logI3 = np.log10(np.abs(I3[m3]))

    log.info("Points valides : I2=%d, I3=%d", logI2.size, logI3.size)

    return logI2, logI3


def make_figure(logI2: np.ndarray, logI3: np.ndarray, bins: int, dpi: int):
    fig, ax = plt.subplots(figsize=(8.0, 5.0), dpi=dpi)

    if logI2.size == 0 and logI3.size == 0:
        ax.text(
            0.5,
            0.5,
            "Aucune donnée valide pour I2 / I3",
            ha="center",
            va="center",
            transform=ax.transAxes,
        )
        return fig

    all_vals = np.concatenate(
        [v for v in (logI2, logI3) if v.size > 0]
    )
    vmin, vmax = float(all_vals.min()), float(all_vals.max())
    if vmin == vmax:
        vmin -= 0.5
        vmax += 0.5

    edges = np.linspace(vmin, vmax, bins)

    if logI2.size > 0:
        ax.hist(
            logI2,
            bins=edges,
            density=True,
            alpha=0.7,
            label=r"$\log_{10} I_2$",
            color="C1",
        )
    if logI3.size > 0:
        ax.hist(
            logI3,
            bins=edges,
            density=True,
            alpha=0.7,
            # NOTE: on évite \lvert / \rvert → utilisation simple de |I_3|
            label=r"$\log_{10}\,|I_3|$",
            color="C2",
        )

    ax.set_xlabel(r"$\log_{10}(\mathrm{valeur\ de\ l'invariant})$")
    ax.set_ylabel("Densité normalisée")
    ax.set_title("Fig. 02 – Histogramme des invariants adimensionnels")
    ax.legend(fontsize="small")
    ax.grid(True, which="both", linestyle=":", linewidth=0.5)

    fig.subplots_adjust(left=0.08, right=0.98, bottom=0.10, top=0.92)
    return fig


def main():
    args = parse_args()

    # verbose (-v) force DEBUG, sinon on respecte --log-level
    level = args.log_level
    if args.verbose >= 1:
        level = "DEBUG"

    log = setup_logger(level)

    log.info("Lecture CSV : %s", args.csv)
    logI2, logI3 = load_invariants(args.csv, log)

    FIG_DIR.mkdir(parents=True, exist_ok=True)
    fig = make_figure(logI2, logI3, bins=args.bins, dpi=args.dpi)

    safe_save(args.out, dpi=args.dpi)
    log.info("Figure sauvegardée → %s", args.out)


if __name__ == "__main__":
    main()
