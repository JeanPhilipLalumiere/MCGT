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
"""Fig. 07 — Second invariant I2(k) – Chapitre 7.

- Lit un CSV 1D (k, invariant)
- Trace I2(k) en log-log avec repère k_split
- Sauvegarde 07_fig_07_invariant_i2.png

Remarque : on tente d'abord des noms de colonnes typiques (I2_cs2, I2, invariant_i2).
Si aucune n'est trouvée, on tombe en repli sur l'unique colonne numérique (hors 'k').
"""

import argparse
import json
import logging
from pathlib import Path
from typing import Optional, Sequence, List

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.ticker import LogLocator, FuncFormatter


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


def detect_value_column(
    df: pd.DataFrame,
    explicit: Optional[str],
    preferred: Sequence[str],
) -> str:
    """Choisit la colonne à utiliser pour I2(k).

    Priorité :
    1) `explicit` si fournie et présente
    2) première colonne trouvée dans `preferred`
    3) si une seule colonne numérique (hors 'k'), on la prend
    """
    cols = list(df.columns)

    if explicit:
        if explicit in df.columns:
            logging.info("Colonne explicite utilisée pour I2 : %s", explicit)
            return explicit
        else:
            raise KeyError(
                f"Colonne explicite '{explicit}' absente. Colonnes disponibles : {cols}"
            )

    # Essai sur la liste de préférences
    for name in preferred:
        if name in df.columns:
            logging.info("Colonne I2 détectée automatiquement : %s", name)
            return name

    # Fallback : unique colonne numérique (hors 'k')
    numeric_candidates: List[str] = []
    for c in df.columns:
        if c == "k":
            continue
        if np.issubdtype(df[c].dtype, np.number):
            numeric_candidates.append(c)

    if len(numeric_candidates) == 1:
        logging.warning(
            "Aucune des colonnes préférées pour I2 n'a été trouvée. "
            "Repli sur la seule colonne numérique disponible : %s",
            numeric_candidates[0],
        )
        return numeric_candidates[0]

    raise RuntimeError(
        "Impossible de déterminer la colonne I2 à tracer. "
        f"Colonnes : {cols}"
    )


def format_pow10(x: float, pos: int) -> str:
    if x <= 0 or not np.isfinite(x):
        return ""
    power = int(np.round(np.log10(x)))
    return rf"$10^{{{power}}}$"


# ---------------------------------------------------------------------------
# Coeur du tracé
# ---------------------------------------------------------------------------


def plot_invariant_i2(
    *,
    data_csv: Path,
    meta_json: Path,
    value_col: Optional[str],
    out_png: Path,
    dpi: int,
) -> None:
    logging.info("Début du tracé de la figure 07 – invariant I2(k)")
    logging.info("CSV données  : %s", data_csv)
    logging.info("JSON méta    : %s", meta_json)
    logging.info("Figure sortie: %s", out_png)

    if not meta_json.exists():
        raise FileNotFoundError(f"Méta-paramètres introuvables : {meta_json}")
    if not data_csv.exists():
        raise FileNotFoundError(f"CSV introuvable : {data_csv}")

    df = pd.read_csv(data_csv, comment="#")
    logging.info("Chargement CSV terminé : %d lignes", len(df))

    meta = json.loads(meta_json.read_text(encoding="utf-8"))
    k_split = float(meta.get("x_split", meta.get("k_split", 0.02)))
    logging.info("Lecture de k_split = %.2e [h/Mpc]", k_split)

    if "k" not in df.columns:
        raise KeyError(f"Colonne 'k' absente du CSV {data_csv} (colonnes: {list(df.columns)})")

    col = detect_value_column(
        df,
        explicit=value_col,
        preferred=["I2_cs2", "I2", "invariant_i2"],
    )

    k_vals = df["k"].to_numpy()
    i2_vals = df[col].to_numpy()

    # Masque : valeurs finies et strictement positives (pour log-log)
    mask = np.isfinite(k_vals) & np.isfinite(i2_vals) & (i2_vals > 0)
    if mask.sum() == 0:
        raise ValueError("Aucune valeur positive finie pour I2(k) après masquage.")

    k_vals = k_vals[mask]
    i2_vals = i2_vals[mask]

    # Bornes Y log à partir des données
    vmin = i2_vals.min()
    vmax = i2_vals.max()
    pmin = int(np.floor(np.log10(vmin)))
    pmax = int(np.ceil(np.log10(vmax)))
    yticks = [10.0**p for p in range(pmin, pmax + 1)]

    plt.style.use("classic")
    fig, ax = plt.subplots(figsize=(8, 5))

    ax.loglog(k_vals, i2_vals, color="C3", lw=2, label=r"$I_2(k)$")

    # Repère k_split
    ax.axvline(k_split, ls="--", color="k", lw=1)
    y_text = 10.0 ** (pmin + 0.05 * (pmax - pmin))
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

    # Limites
    ax.set_xlim(k_vals.min(), k_vals.max())
    ax.set_ylim(10.0**pmin, 10.0**pmax)

    # Labels / titre
    ax.set_xlabel(r"$k\,[h/\mathrm{Mpc}]$", fontsize=12)
    ax.set_ylabel(r"$I_2(k)$", fontsize=12)
    ax.set_title("Second scalar invariant $I_2(k)$", fontsize=14)

    # Grille + ticks
    ax.grid(which="major", ls=":", lw=0.5)
    ax.grid(which="minor", ls=":", lw=0.3, alpha=0.7)

    ax.xaxis.set_major_locator(LogLocator(base=10))
    ax.xaxis.set_minor_locator(LogLocator(base=10, subs=(2, 5)))

    ax.yaxis.set_major_locator(LogLocator(base=10.0, numticks=5))
    from matplotlib.ticker import NullLocator, NullFormatter
    ax.yaxis.set_minor_locator(NullLocator())
    ax.yaxis.set_minor_formatter(NullFormatter())
    ax.tick_params(axis="y", labelsize=10)
    ax.yaxis.set_major_formatter(FuncFormatter(format_pow10))
    ax.set_yticks(yticks)

    ax.legend(loc="best", frameon=False)

    out_png.parent.mkdir(parents=True, exist_ok=True)
    fig.tight_layout()
    safe_save(out_png, dpi=dpi)
    plt.close(fig)

    logging.info("Figure enregistrée : %s", out_png)
    logging.info("Tracé de la figure 07 terminé ✔")


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def build_arg_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        description="Fig. 07 — Second invariant I2(k) – Chapitre 7.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    p.add_argument(
        "--data-csv",
        default="zz-data/chapter07/07_scalar_invariants.csv",
        help="CSV contenant k et l'invariant I2(k).",
    )
    p.add_argument(
        "--meta-json",
        default="zz-data/chapter07/07_meta_perturbations.json",
        help="Fichier JSON contenant au moins 'x_split' ou 'k_split'.",
    )
    p.add_argument(
        "--out",
        default="zz-figures/chapter07/07_fig_07_invariant_i2.png",
        help="Chemin de sortie de la figure PNG.",
    )
    p.add_argument(
        "--value-col",
        default=None,
        help="Nom explicite de la colonne I2 (sinon auto-détection).",
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

    plot_invariant_i2(
        data_csv=data_csv,
        meta_json=meta_json,
        value_col=args.value_col,
        out_png=out_png,
        dpi=args.dpi,
    )


if __name__ == "__main__":
    main()
