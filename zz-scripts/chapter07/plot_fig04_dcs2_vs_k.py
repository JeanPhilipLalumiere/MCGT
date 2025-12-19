#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import shutil
import tempfile
from pathlib import Path as _SafePath

import matplotlib.pyplot as plt

plt.rcParams.update(
    {
        "figure.autolayout": True,
        "figure.figsize": (10, 6),
        "axes.titlepad": 25,
        "axes.labelpad": 15,
        "savefig.bbox": "tight",
        "savefig.pad_inches": 0.3,
        "font.family": "serif",
    }
)

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

#!/usr/bin/env python3
r"""
plot_fig04_dcs2_vs_k.py

Figure 04 – Dérivée lissée ∂c_s²/∂k
Chapitre 7 – Perturbations scalaires MCGT.

Trace |∂_k c_s²| en fonction de k, avec un repère vertical à k_split.
"""

import argparse
import json
import logging
from pathlib import Path
from typing import Optional, Sequence

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.ticker import FuncFormatter, LogLocator


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def setup_logging(verbose: int = 0) -> None:
    if verbose >= 2:
        level = logging.DEBUG
    elif verbose == 1:
        level = logging.INFO
    else:
        level = logging.WARNING
    logging.basicConfig(level=level, format="[%(levelname)s] %(message)s")


def detect_project_root() -> Path:
    try:
        return Path(__file__).resolve().parents[2]
    except NameError:
        return Path.cwd()


def detect_value_column(df: pd.DataFrame) -> str:
    """
    Pour 07_dcs2_vs_k.csv :
      - on s'attend à 'k' + une colonne numérique pour dcs2/dk.
    On choisit :
      1) la 2e colonne si elle est numérique,
      2) sinon la première colonne numérique ≠ 'k'.
    """
    cols = list(df.columns)
    logging.debug("Colonnes CSV: %s", cols)

    if len(cols) >= 2 and pd.api.types.is_numeric_dtype(df[cols[1]]):
        logging.info("Colonne '%s' utilisée (2e colonne du CSV)", cols[1])
        return cols[1]

    candidates = [
        c for c in cols if c != "k" and pd.api.types.is_numeric_dtype(df[c])
    ]
    if len(candidates) == 1:
        logging.info(
            "Colonne numérique '%s' sélectionnée automatiquement pour dcs2/dk", candidates[0]
        )
        return candidates[0]

    logging.error(
        "Impossible de déterminer la colonne dcs2/dk.\n"
        "Colonnes disponibles : %s\n"
        "Candidats numériques hors 'k' : %s",
        cols,
        candidates,
    )
    raise RuntimeError(
        f"Impossible de déterminer la colonne dcs2/dk "
        f"(colonnes: {cols}, candidats: {candidates})"
    )


# ---------------------------------------------------------------------------
# Core
# ---------------------------------------------------------------------------

def plot_dcs2_vs_k(
    *,
    data_csv: Path,
    meta_json: Path,
    out_png: Path,
    dpi: int = 300,
) -> None:
    """Trace |∂_k c_s²| en fonction de k, en log-log."""

    logging.info("Début du tracé de la figure 04 – dcs2/dk vs k")
    logging.info("CSV dérivée : %s", data_csv)
    logging.info("JSON méta   : %s", meta_json)
    logging.info("Figure out  : %s", out_png)

    if not meta_json.exists():
        logging.error("Fichier méta introuvable : %s", meta_json)
        raise FileNotFoundError(meta_json)
    meta = json.loads(meta_json.read_text(encoding="utf-8"))
    k_split = float(meta.get("x_split", 0.02))
    logging.info("k_split = %.2e h/Mpc", k_split)

    if not data_csv.exists():
        logging.error("CSV introuvable : %s", data_csv)
        raise FileNotFoundError(data_csv)

    df = pd.read_csv(data_csv, comment="#")
    logging.info("Loaded %d points from %s", len(df), data_csv.name)
    if "k" not in df.columns:
        raise KeyError(f"Colonne 'k' absente du CSV {data_csv} (colonnes: {list(df.columns)})")

    val_col = detect_value_column(df)

    k_vals = df["k"].to_numpy(dtype=float)
    dcs2 = df[val_col].to_numpy(dtype=float)

    # Filtre log-log : k>0, |dcs2|>0, finites
    mask = np.isfinite(k_vals) & np.isfinite(dcs2) & (k_vals > 0) & (np.abs(dcs2) > 0)
    k_vals = k_vals[mask]
    dcs2 = dcs2[mask]
    logging.info("Points retenus après filtrage : %d", k_vals.size)

    if k_vals.size == 0:
        raise ValueError("Aucun point valide pour tracer |∂_k c_s²| en log-log.")

    plt.style.use("classic")
    plt.rc("font", family="serif")

    out_png.parent.mkdir(parents=True, exist_ok=True)
    fig, ax = plt.subplots(figsize=(8, 5), dpi=dpi)

    # Tracé de |∂ₖ c_s²|
    ax.loglog(
        k_vals,
        np.abs(dcs2),
        color="C1",
        lw=2,
        label=r"$\partial_k c_s^2$",
    )

    # Ligne verticale k_split
    ax.axvline(k_split, color="k", ls="--", lw=1, label=r"$k_{\rm split}$")
    ax.text(
        0.5,
        0.08,
        r"$k_{\rm split}$",
        transform=ax.transAxes,
        ha="center",
        va="bottom",
        fontweight="bold",
        bbox=dict(facecolor="white", alpha=0.8),
    )

    # Labels et titre
    ax.set_xlabel(r"$k$ [h/Mpc]", labelpad=12, fontsize=12)
    ax.set_ylabel(r"$|\partial_k\,c_s^2|$", fontsize=12)
    ax.set_title(r"Smoothed derivative $\partial_k\,c_s^2(k)$", fontsize=14)
    # Positionnement manuel du label X pour éviter tout chevauchement
    ax.text(
        0.5,
        -0.18,
        r"$k$ [h/Mpc]",
        transform=ax.transAxes,
        ha="center",
        va="top",
        fontsize=12,
    )

    # Grilles
    ax.grid(which="major", ls=":", lw=0.6)
    ax.grid(which="minor", ls=":", lw=0.3, alpha=0.7)

    # Locators pour axes log
    ax.xaxis.set_major_locator(LogLocator(base=10))
    ax.xaxis.set_minor_locator(LogLocator(base=10, subs=(2, 5)))
    ax.yaxis.set_major_locator(LogLocator(base=10))
    ax.yaxis.set_minor_locator(LogLocator(base=10, subs=(2, 5)))

    # Formatter pour afficher les puissances de 10
    def pow_fmt(x, pos):
        if x <= 0 or not np.isfinite(x):
            return ""
        return rf"$10^{{{int(np.log10(x))}}}$"

    ax.xaxis.set_major_formatter(FuncFormatter(pow_fmt))
    ax.yaxis.set_major_formatter(FuncFormatter(pow_fmt))

    # Limite Y inf pour aérer un peu
    ymin, ymax = ax.get_ylim()
    if ymin <= 0:
        ymin = 1e-8
    ax.set_ylim(max(1e-8, ymin), ymax)

    ax.legend(loc="best", frameon=False)
    fig.subplots_adjust(bottom=0.25, top=0.90, left=0.15, right=0.95)
    safe_save(out_png, dpi=dpi)
    plt.close(fig)
    logging.info("Figure enregistrée : %s", out_png)
    logging.info("Tracé de la figure 04 terminé ✔")


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def build_arg_parser() -> argparse.ArgumentParser:
    root = detect_project_root()
    default_data = root / "zz-data" / "chapter07" / "07_dcs2_vs_k.csv"
    default_meta = root / "zz-data" / "chapter07" / "07_meta_perturbations.json"
    default_out = root / "zz-figures" / "chapter07" / "07_fig_04_dcs2_vs_k.png"

    p = argparse.ArgumentParser(
        description=(
            "Figure 04 – |∂_k c_s²|(k).\n"
            "Lit un CSV avec colonnes k + dcs2/dk et génère la figure PNG."
        ),
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    p.add_argument(
        "--data-csv",
        default=str(default_data),
        help="CSV contenant 'k' et la dérivée dcs2/dk.",
    )
    p.add_argument(
        "--meta-json",
        default=str(default_meta),
        help="JSON méta (k_split/x_split).",
    )
    p.add_argument(
        "--out",
        default=str(default_out),
        help="Chemin de sortie de la figure PNG.",
    )
    p.add_argument(
        "--dpi",
        type=int,
        default=300,
        help="Résolution de la figure.",
    )
    p.add_argument(
        "-v",
        "--verbose",
        action="count",
        default=0,
        help="Verbosity cumulable (-v, -vv).",
    )
    return p


def main(argv: Optional[Sequence[str]] = None) -> None:
    parser = build_arg_parser()
    args = parser.parse_args(argv)

    setup_logging(args.verbose)

    data_csv = Path(args.data_csv)
    meta_json = Path(args.meta_json)
    out_png = Path(args.out)

    plot_dcs2_vs_k(
        data_csv=data_csv,
        meta_json=meta_json,
        out_png=out_png,
        dpi=args.dpi,
    )


if __name__ == "__main__":
    main()
