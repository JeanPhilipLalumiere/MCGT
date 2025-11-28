#!/usr/bin/env python3
"""Fig. 04 – Évolution de P(T) – Chapitre 1.

Ce script trace l'évolution de la pression P en fonction du temps cosmique T
pour la solution initiale et la solution optimisée.

Données attendues
-----------------
On NE dépend plus d'un seul nom de fichier fixe.
On scanne plutôt le répertoire :

    zz-data/chapter01/

On cherche un CSV "01_*.csv" qui contient :
    - une colonne temporelle (T, T_Gyr, temps, …)
    - au moins DEUX colonnes de type pression (P_initiale / P_optimisee, etc.)

Le choix du fichier se fait par heuristique :
    * on lit tous les 01_*.csv
    * on garde uniquement ceux qui ont ≥ 2 colonnes P-like (nom contenant 'p'
      ou 'press' et numérique)
    * on score les noms : +5 si "donnee(s)", +5 si "optimis(e)", +2 si "derive"
    * on prend le meilleur score

La figure produite est :

    zz-figures/chapter01/01_fig_04_p_vs_t_evolution.png
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
OUT_PNG = FIG_DIR / "01_fig_04_p_vs_t_evolution.png"

FIG_DIR.mkdir(parents=True, exist_ok=True)


# ---------------------------------------------------------------------------
# Logging & helpers génériques
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
    """Détecte une colonne par liste de candidats + heuristique.

    - candidates : noms préférés (prioritaires, insensibles à la casse)
    - numeric_only : si True, restreint aux colonnes numériques
    - exclude : noms à ignorer (déjà choisis pour un autre rôle)
    """
    lower_map = {c.lower(): c for c in df.columns}
    exclude_lower = {e.lower() for e in exclude}

    # 1) Candidats explicites
    for cand in candidates:
        key = cand.lower()
        if key in lower_map and key not in exclude_lower:
            col = lower_map[key]
            if numeric_only and not pd.api.types.is_numeric_dtype(df[col]):
                continue
            logging.info("Colonne %s détectée : %s", label, col)
            return col

    # 2) Première numérique non exclue
    if numeric_only:
        for col in df.columns:
            if col.lower() in exclude_lower:
                continue
            if pd.api.types.is_numeric_dtype(df[col]):
                logging.info(
                    "Colonne %s détectée par heuristique numérique : %s", label, col
                )
                return col

    # 3) Fallback : première colonne non exclue
    for col in df.columns:
        if col.lower() in exclude_lower:
            continue
        logging.info("Colonne %s (fallback générique) : %s", label, col)
        return col

    raise RuntimeError(f"Impossible de détecter une colonne pour {label}")


def _score_pt_file(path: Path) -> Tuple[int, Optional[Tuple[str, str, str]]]:
    """Retourne (score, (col_T, col_P_init, col_P_opt)) pour un CSV donné.

    Si le fichier n'est pas exploitable (pas assez de colonnes P-like),
    on retourne (score=-1, None).
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
        # Pas assez de colonnes P-like → on exclut ce fichier
        logging.debug(
            "Fichier %s rejeté : seulement %d colonne(s) P-like", path, len(p_like)
        )
        return -1, None

    # On choisit la première comme "initiale", la seconde comme "optimisée"
    col_P_init = p_like[0]
    col_P_opt = p_like[1]

    # Score basé sur le nom
    name = path.name.lower()
    score = 10  # base
    if "donnee" in name or "donnée" in name or "donnees" in name:
        score += 5
    if "optimis" in name or "optimise" in name or "optimisée" in name:
        score += 5
    if "derive" in name or "deriv" in name:
        score += 2

    # Bonus léger si plus de 2 colonnes P-like
    score += max(0, len(p_like) - 2)

    logging.debug(
        "Score fichier %s = %d (T=%s, P_init=%s, P_opt=%s)",
        path,
        score,
        col_T,
        col_P_init,
        col_P_opt,
    )
    return score, (col_T, col_P_init, col_P_opt)


def _select_pt_dataset() -> Tuple[Path, str, str, str]:
    """Sélectionne le meilleur CSV 01_*.csv pour P(T) initiale / optimisée."""
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
        "Fichier CSV sélectionné pour P(T) : %s (T=%s, P_init=%s, P_opt=%s)",
        path,
        col_T,
        col_P_init,
        col_P_opt,
    )
    return path, col_T, col_P_init, col_P_opt


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main(args: Optional[argparse.Namespace] = None) -> None:
    if args is None:
        # Appel direct sans CLI seed
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

    # Tri croissant en T
    order = np.argsort(T)
    T = T[order]
    P_init = P_init[order]
    P_opt = P_opt[order]

    # ------------------------------------------------------------------
    # Tracé
    # ------------------------------------------------------------------
    fig, ax = plt.subplots(figsize=(8, 4.5), dpi=300)
    ax.plot(T, P_init, "--", color="gray", linewidth=1.5, label="P(T) initiale")
    ax.plot(T, P_opt, "-", color="tab:orange", linewidth=1.8, label="P(T) optimisée")

    ax.set_xscale("log")
    ax.set_xlabel("T (Gyr)")
    ax.set_ylabel("P (unités arbitraires)")
    ax.set_title("Fig. 04 – Évolution de P(T) initiale vs optimisée – Chapitre 1")
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
        except Exception as e:  # pragma: no cover - chemin debug
            print(f"[CLI seed] main() a levé: {e}", file=sys.stderr)
            traceback.print_exc()
            sys.exit(1)

    _mcgt_cli_seed()
