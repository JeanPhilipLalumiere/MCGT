#!/usr/bin/env python3
"""
Fig. 01 – Évolution P(T) – Chapitre 2

Produit :
- zz-figures/chapter02/02_fig_01_p_vs_t_evolution.png

Logique :
- Charge un CSV de chapitre 2 contenant T et P.
- Tente plusieurs noms de fichiers et de colonnes (robuste aux variantes).
- Si une colonne de classe est présente, distingue primaires / ordre 2.
"""

from __future__ import annotations

import logging
from pathlib import Path
from typing import Iterable

import matplotlib.pyplot as plt
import pandas as pd

# Répertoires
ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = ROOT / "zz-data" / "chapter02"
FIG_DIR = ROOT / "zz-figures" / "chapter02"
FIG_DIR.mkdir(parents=True, exist_ok=True)

OUT_PNG = FIG_DIR / "02_fig_01_p_vs_t_evolution.png"


def _first_existing(paths: Iterable[Path]) -> Path:
    """Renvoie le premier fichier existant parmi la liste, sinon lève."""
    for p in paths:
        if p.is_file():
            return p
    raise FileNotFoundError(
        "Aucun CSV trouvé pour P(T) parmi :\n"
        + "\n".join(f"  - {p}" for p in paths)
    )


def _detect_col(df: pd.DataFrame, candidates: list[str]) -> str:
    """Trouve une colonne par nom exact ou inclusion insensible à la casse."""
    # 1) noms exacts
    for c in candidates:
        if c in df.columns:
            return c
    # 2) inclusion insensible à la casse
    lower_map = {c.lower(): c for c in df.columns}
    for cand in candidates:
        lcand = cand.lower()
        if lcand in lower_map:
            return lower_map[lcand]
    for c in df.columns:
        lc = c.lower()
        for cand in candidates:
            if cand.lower() in lc:
                return c
    raise KeyError(f"Impossible de trouver une colonne parmi : {candidates}")


def main(args=None) -> None:
    # ------------------------------------------------------------------
    # Logging
    # ------------------------------------------------------------------
    level = logging.INFO
    if args is not None and getattr(args, "verbose", 0):
        v = int(args.verbose)
        if v >= 2:
            level = logging.DEBUG
        elif v == 1:
            level = logging.INFO
    logging.basicConfig(level=level, format="[%(levelname)s] %(message)s")

    # ------------------------------------------------------------------
    # 1. Chargement des données
    # ------------------------------------------------------------------
    csv_candidates = [
        DATA_DIR / "02_P_vs_T_evolution.csv",
        DATA_DIR / "02_p_vs_t_evolution.csv",
        DATA_DIR / "02_P_vs_T.csv",
        DATA_DIR / "02_p_vs_t.csv",
        DATA_DIR / "02_timeline_milestones.csv",
    ]
    csv_path = _first_existing(csv_candidates)
    logging.info("Lecture des données P(T) depuis : %s", csv_path)

    df = pd.read_csv(csv_path)

    # Colonnes obligatoires
    t_col = _detect_col(df, ["T", "T_Gyr", "t_Gyr", "time_Gyr", "time"])
    p_col = _detect_col(df, ["P", "P_dimless", "P_over_P0", "pressure"])

    T = df[t_col].astype(float).to_numpy()
    P = df[p_col].astype(float).to_numpy()

    # Colonne de classe optionnelle (primaires / ordre 2)
    classe_col = None
    for cand in ["classe", "class", "Classe"]:
        if cand in df.columns:
            classe_col = cand
            break

    # ------------------------------------------------------------------
    # 2. Tracé
    # ------------------------------------------------------------------
    fig, ax = plt.subplots(figsize=(8, 5), dpi=300)

    if classe_col is not None:
        cls = df[classe_col].astype(str)
        mask_primary = cls.str.lower() == "primaire"
        mask_other = ~mask_primary

        ax.plot(
            T[mask_primary],
            P[mask_primary],
            "o-",
            label="Jalons primaires",
            linewidth=1.0,
        )
        ax.plot(
            T[mask_other],
            P[mask_other],
            "s-",
            label="Jalons ordre 2",
            linewidth=1.0,
        )
    else:
        ax.plot(T, P, "o-", label="P(T)")

    ax.set_xscale("log")
    ax.set_xlabel("T (Gyr)")
    ax.set_ylabel("P(T)")
    ax.set_title("Fig. 01 – Évolution de P(T) – Chapitre 2")
    ax.grid(True, which="both", linestyle=":", linewidth=0.5)
    ax.legend()

    fig.subplots_adjust(left=0.06, right=0.98, bottom=0.08, top=0.94)
    fig.savefig(OUT_PNG)
    logging.info("Figure enregistrée → %s", OUT_PNG)


# === MCGT CLI SEED v2 ===
if __name__ == "__main__":
    def _mcgt_cli_seed() -> None:
        import argparse
        import os
        import sys
        import traceback

        parser = argparse.ArgumentParser(
            description="Standard CLI seed (non-intrusif) – fig_01 P(T)."
        )
        parser.add_argument(
            "--outdir",
            default=os.environ.get("MCGT_OUTDIR", ".ci-out"),
            help="Dossier de sortie (par défaut: .ci-out)",
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

        # Config outdir / backend matplotlib (best-effort)
        try:
            os.makedirs(args.outdir, exist_ok=True)
            os.environ["MCGT_OUTDIR"] = args.outdir
            import matplotlib as mpl

            mpl.rcParams["savefig.dpi"] = args.dpi
            mpl.rcParams["savefig.format"] = args.format
            mpl.rcParams["savefig.transparent"] = args.transparent
        except Exception:
            pass

        _main = globals().get("main")
        if callable(_main):
            try:
                _main(args)
            except SystemExit:
                raise
            except Exception as e:  # pragma: no cover - debug path
                print(f"[CLI seed] main() a levé: {e}", file=sys.stderr)
                traceback.print_exc()
                sys.exit(1)

    _mcgt_cli_seed()
