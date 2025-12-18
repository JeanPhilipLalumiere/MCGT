#!/usr/bin/env python3
"""
Fig. 05 – Séries F/G – Chapitre 2

Produit :
- zz-figures/chapter02/02_fig_05_fg_series.png

Logique :
- Lit 02_FG_series.csv
- Si colonnes ['ordre', 'coeff', 'serie'] présentes :
    * trace coeff(ordre) pour chaque série (F, G, ...)
- Sinon, fallback : trace toutes les colonnes numériques en fonction d'un x numérique.
"""

from __future__ import annotations

import logging
import hashlib
import shutil
import tempfile
from pathlib import Path
from typing import List

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

# Répertoires
ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = ROOT / "zz-data" / "chapter02"
FIG_DIR = ROOT / "zz-figures" / "chapter02"
FIG_DIR.mkdir(parents=True, exist_ok=True)

CSV_PATH = DATA_DIR / "02_FG_series.csv"
OUT_PNG = FIG_DIR / "02_fig_05_fg_series.png"


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


def _numeric_columns(df: pd.DataFrame, min_frac: float = 0.8) -> List[str]:
    """Retourne les noms de colonnes majoritairement numériques."""
    num_cols: List[str] = []
    for col in df.columns:
        s = pd.to_numeric(df[col], errors="coerce")
        if s.notna().mean() >= min_frac:
            num_cols.append(col)
    return num_cols


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
    if not CSV_PATH.is_file():
        raise FileNotFoundError(f"CSV introuvable : {CSV_PATH}")
    logging.info("Lecture des séries F/G depuis : %s", CSV_PATH)

    df = pd.read_csv(CSV_PATH)
    logging.debug("Colonnes disponibles : %s", list(df.columns))

    fig, ax = plt.subplots(figsize=(8, 5), dpi=300)

    # ------------------------------------------------------------------
    # 2. Cas nominal : colonnes ordre / coeff / serie
    # ------------------------------------------------------------------
    lower_cols = {c.lower(): c for c in df.columns}
    has_ordre = "ordre" in lower_cols
    has_coeff = "coeff" in lower_cols
    serie_col_name = None
    for cand in ("serie", "series", "type"):
        if cand in lower_cols:
            serie_col_name = lower_cols[cand]
            break

    if has_ordre and has_coeff and serie_col_name is not None:
        ordre_col = lower_cols["ordre"]
        coeff_col = lower_cols["coeff"]

        logging.info(
            "Mode 'séries catégorielles' détecté : ordre=%s, coeff=%s, serie=%s",
            ordre_col,
            coeff_col,
            serie_col_name,
        )

        # On s'assure que ordre/coeff sont bien numériques
        df[ordre_col] = pd.to_numeric(df[ordre_col], errors="coerce")
        df[coeff_col] = pd.to_numeric(df[coeff_col], errors="coerce")
        df = df.dropna(subset=[ordre_col, coeff_col])

        series_vals = sorted(df[serie_col_name].unique())
        logging.info("Séries détectées : %s", series_vals)

        label_map = {
            "F": r"$F_n$",
            "G": r"$G_n$",
            "FG": r"$F_n, G_n$",
        }

        for s in series_vals:
            sub = df[df[serie_col_name] == s]
            x = sub[ordre_col].to_numpy()
            y = sub[coeff_col].to_numpy()
            label = label_map.get(str(s), f"{s}")
            ax.plot(x, y, "-o", linewidth=1.3, markersize=3, label=label)

        ax.set_xlabel(r"Order $n$")
        ax.set_ylabel("Coefficient")
        ax.set_title("Series $F_n$ and $G_n$ - Chapter 2")

    else:
        # ------------------------------------------------------------------
        # 3. Fallback générique : toutes les colonnes numériques vs une abscisse
        # ------------------------------------------------------------------
        logging.warning(
            "Colonnes (ordre, coeff, serie) non toutes trouvées, fallback générique."
        )
        num_cols = _numeric_columns(df, min_frac=0.8)
        logging.info("Colonnes numériques détectées : %s", num_cols)

        if not num_cols:
            raise RuntimeError(
                "Aucune colonne majoritairement numérique, impossible de tracer."
            )

        # x = première colonne numérique, les suivantes sont des séries
        x_col = num_cols[0]
        y_cols = num_cols[1:] or num_cols  # si une seule, on trace juste celle-là

        x = pd.to_numeric(df[x_col], errors="coerce").to_numpy()

        for col in y_cols:
            if col == x_col:
                continue
            y = pd.to_numeric(df[col], errors="coerce").to_numpy()
            mask = ~(pd.isna(x) | pd.isna(y))
            ax.plot(
                x[mask],
                y[mask],
                "-o",
                linewidth=1.3,
                markersize=3,
                label=str(col),
            )

        xlabel = "Order" if x_col.lower() == "ordre" else x_col
        ax.set_xlabel(xlabel)
        ax.set_ylabel("Amplitude")
        ax.set_title("Series F/G (generic fallback) - Chapter 2")

    ax.grid(True, which="both", linestyle=":", linewidth=0.5)
    ax.legend()
    fig.subplots_adjust(left=0.06, right=0.98, bottom=0.08, top=0.94)

    safe_save(OUT_PNG)
    logging.info("Figure enregistrée → %s", OUT_PNG)


# === MCGT CLI SEED v2 ===
if __name__ == "__main__":
    def _mcgt_cli_seed() -> None:
        import argparse
        import os
        import sys
        import traceback

        parser = argparse.ArgumentParser(
            description="Standard CLI seed (non-intrusif) – fig_05 FG series."
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
