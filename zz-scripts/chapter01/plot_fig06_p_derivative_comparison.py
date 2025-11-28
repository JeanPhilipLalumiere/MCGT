#!/usr/bin/env python3
"""Fig. 06 – Comparaison des dérivées dP/dT – Chapitre 1.

Ce script compare la dérivée dP/dT pour la solution initiale et la solution
optimisée, en utilisant le *même* dataset agrégé P(T) que la Fig. 04.

On NE dépend plus d'un nom unique comme
    01_donnees_optimisees_et_derivees.csv
mais on scanne tous les 01_*.csv de zz-data/chapter01 et on choisit celui qui :

    - contient une colonne temporelle (T, T_Gyr, temps, …)
    - contient au moins deux colonnes P-like (nom avec 'p' ou 'press', numériques)

Les dérivées dP/dT sont reconstruites numériquement via np.gradient.

Sortie :

    zz-figures/chapter01/01_fig_06_p_derivative_comparison.png
"""

from __future__ import annotations

import argparse
import logging
from pathlib import Path
from typing import Iterable, Optional, Sequence, Tuple

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = ROOT / "zz-data" / "chapter01"
FIG_DIR = ROOT / "zz-figures" / "chapter01"
OUT_PNG = FIG_DIR / "01_fig_06_p_derivative_comparison.png"

FIG_DIR.mkdir(parents=True, exist_ok=True)


# ---------------------------------------------------------------------------
# Logging & helpers
# ---------------------------------------------------------------------------
def _setup_logging(verbose: int = 0) -> None:
    if verbose >= 2:
        level = logging.DEBUG
    elif verbose == 1:
        level = logging.INFO
    else:
        level = logging.WARNING
    logging.basicConfig(level=level, format="[%(levelname)s] %(message)s")


def _detect_col(
    df: pd.DataFrame,
    label: str,
    candidates: Sequence[str],
    *,
    numeric_only: bool = False,
    exclude: Iterable[str] = (),
) -> str:
    """Détecte une colonne par liste de candidats + heuristique."""
    lower_map = {c.lower(): c for c in df.columns}
    exclude_lower = {e.lower() for e in exclude}

    # Candidats explicites
    for cand in candidates:
        key = cand.lower()
        if key in lower_map and key not in exclude_lower:
            col = lower_map[key]
            if numeric_only and not pd.api.types.is_numeric_dtype(df[col]):
                continue
            logging.info("Colonne %s détectée : %s", label, col)
            return col

    # Première numérique non exclue
    if numeric_only:
        for col in df.columns:
            if col.lower() in exclude_lower:
                continue
            if pd.api.types.is_numeric_dtype(df[col]):
                logging.info(
                    "Colonne %s détectée (heuristique numérique) : %s", label, col
                )
                return col

    # Fallback : première colonne non exclue
    for col in df.columns:
        if col.lower() in exclude_lower:
            continue
        logging.info("Colonne %s (fallback générique) : %s", label, col)
        return col

    raise RuntimeError(f"Impossible de détecter une colonne pour {label}")


def _score_pt_file(path: Path) -> Tuple[int, Optional[Tuple[str, str, str]]]:
    """Score un CSV 01_*.csv pour dP/dT, même logique que Fig. 04.

    Retourne (score, (col_T, col_P_init, col_P_opt)) ou (-1, None).
    """
    try:
        df = pd.read_csv(path)
    except Exception as e:
        logging.debug("Échec lecture %s : %s", path, e)
        return -1, None

    # Chercher colonne temps
    try:
        col_T = _detect_col(
            df,
            "T",
            ["T", "T_Gyr", "temps", "temps_Gyr"],
            numeric_only=True,
        )
    except Exception:
        return -1, None

    # Colonnes P-like numériques (nom contient 'p' ou 'press')
    p_like = []
    for col in df.columns:
        if col == col_T:
            continue
        name = col.lower()
        if ("p" in name or "press" in name) and pd.api.types.is_numeric_dtype(df[col]):
            p_like.append(col)

    if len(p_like) < 2:
        logging.debug(
            "Fichier %s rejeté (dP/dT) : seulement %d colonne(s) P-like",
            path,
            len(p_like),
        )
        return -1, None

    col_P_init = p_like[0]
    col_P_opt = p_like[1]

    name = path.name.lower()
    score = 10
    if "donnee" in name or "donnée" in name or "donnees" in name:
        score += 5
    if "optimis" in name or "optimise" in name or "optimisée" in name:
        score += 5
    if "derive" in name or "deriv" in name:
        score += 2
    score += max(0, len(p_like) - 2)

    logging.debug(
        "Score fichier (dP/dT) %s = %d (T=%s, P_init=%s, P_opt=%s)",
        path,
        score,
        col_T,
        col_P_init,
        col_P_opt,
    )
    return score, (col_T, col_P_init, col_P_opt)


def _select_pt_dataset() -> Tuple[Path, str, str, str]:
    """Sélectionne le même type de dataset P(T) que pour Fig. 04."""
    candidates = sorted(DATA_DIR.glob("01_*.csv"))
    if not candidates:
        raise FileNotFoundError(f"Aucun fichier 01_*.csv trouvé dans {DATA_DIR}")

    best_score = -1
    best_info: Optional[Tuple[Path, str, str, str]] = None

    for path in candidates:
        score, cols = _score_pt_file(path)
        if score > best_score and cols is not None:
            col_T, col_P_init, col_P_opt = cols
            best_score = score
            best_info = (path, col_T, col_P_init, col_P_opt)

    if best_info is None:
        raise FileNotFoundError(
            f"Aucun CSV exploitable (avec ≥ 2 colonnes P-like) parmi : "
            f"{[p.name for p in candidates]}"
        )

    path, col_T, col_P_init, col_P_opt = best_info
    logging.info(
        "Fichier CSV sélectionné pour dP/dT : %s (T=%s, P_init=%s, P_opt=%s)",
        path,
        col_T,
        col_P_init,
        col_P_opt,
    )
    return path, col_T, col_P_init, col_P_opt


def _numerical_derivative(x: np.ndarray, y: np.ndarray) -> Tuple[np.ndarray, np.ndarray]:
    """Calcule dP/dT sur une grille triée."""
    order = np.argsort(x)
    x_sorted = x[order]
    y_sorted = y[order]
    dy_dt = np.gradient(y_sorted, x_sorted)
    return x_sorted, dy_dt


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main(args: Optional[argparse.Namespace] = None) -> None:
    if args is None:
        class _Args:
            verbose = 0
        args = _Args()  # type: ignore[assignment]

    _setup_logging(getattr(args, "verbose", 0))

    data_csv, col_T, col_P_init, col_P_opt = _select_pt_dataset()
    logging.info("Lecture des données P(T) depuis : %s", data_csv)

    df = pd.read_csv(data_csv)

    T = df[col_T].to_numpy(dtype=float)
    P_init = df[col_P_init].to_numpy(dtype=float)
    P_opt = df[col_P_opt].to_numpy(dtype=float)

    # Dérivées numériques
    T_init, dP_init = _numerical_derivative(T, P_init)
    T_opt, dP_opt = _numerical_derivative(T, P_opt)

    # ------------------------------------------------------------------
    # Tracé
    # ------------------------------------------------------------------
    fig, ax = plt.subplots(figsize=(8, 4.5), dpi=300)
    ax.plot(
        T_init,
        dP_init,
        "--",
        color="gray",
        linewidth=1.5,
        label="dP/dT (initiale)",
    )
    ax.plot(
        T_opt,
        dP_opt,
        "-",
        color="tab:blue",
        linewidth=1.8,
        label="dP/dT (optimisée)",
    )

    ax.set_xscale("log")
    ax.set_xlabel("T (Gyr)")
    ax.set_ylabel("dP/dT (unités arbitraires)")
    ax.set_title("Fig. 06 – Comparaison des dérivées dP/dT – Chapitre 1")
    ax.grid(True, which="both", linestyle=":", linewidth=0.5)
    ax.legend(loc="best", frameon=False)

    fig.subplots_adjust(left=0.08, right=0.98, bottom=0.12, top=0.90)
    fig.savefig(OUT_PNG)
    logging.info("Figure sauvegardée : %s", OUT_PNG)


# === MCGT CLI SEED v2 ===
if __name__ == "__main__":
    def _mcgt_cli_seed() -> None:
        import sys
        import traceback

        parser = argparse.ArgumentParser(
            description="Standard CLI seed (non-intrusif).",
            allow_abbrev=False,
        )
        parser.add_argument(
            "--outdir",
            default=".",
            help="(ignoré ici, présent pour compatibilité)",
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
            help="Graine aléatoire (optionnelle).",
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
            default=150,
            help="Figure DPI (default: 150)",
        )
        parser.add_argument(
            "--format",
            choices=["png", "pdf", "svg"],
            default="png",
            help="Figure format",
        )
        parser.add_argument(
            "--transparent",
            action="store_true",
            help="Transparent background",
        )

        args = parser.parse_args()

        # Config matplotlib (best-effort)
        try:
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
        except Exception as e:  # pragma: no cover
            print(f"[CLI seed] main() a levé: {e}", file=sys.stderr)
            traceback.print_exc()
            sys.exit(1)

    _mcgt_cli_seed()
