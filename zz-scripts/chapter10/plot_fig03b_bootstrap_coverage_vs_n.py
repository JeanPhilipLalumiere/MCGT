#!/usr/bin/env python3
"""Fig. 03b – Couverture bootstrap vs N – Chapitre 10.

Script simplifié pour générer la figure 03b et un manifest JSON compatible
avec plot_fig07_synthesis.py.

- Entrée : un CSV avec au moins une colonne de métrique p95 (ex. p95_20_300_recalc)
- Sorties :
  * PNG : courbes couverture vs N + largeur moyenne d’IC vs N
  * JSON : manifest avec les champs attendus par Series.from_manifest(...)
"""

from __future__ import annotations

import argparse
import json
import logging
from dataclasses import dataclass
from math import sqrt
from pathlib import Path
from typing import List, Optional, Sequence, Tuple

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd


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


def detect_p95_column(df: pd.DataFrame, explicit: Optional[str]) -> str:
    """Détecte la colonne p95 à utiliser.

    Priorité :
    1) --p95-col explicite si présente
    2) colonnes candidates usuelles
    """
    if explicit and explicit in df.columns:
        logging.info("Colonne p95 explicite trouvée : %s", explicit)
        return explicit

    candidates = [
        "p95_20_300_recalc",
        "p95_20_300",
        "p95",
    ]
    for c in candidates:
        if c in df.columns:
            logging.info("Colonne p95 détectée automatiquement : %s", c)
            return c

    raise RuntimeError(
        f"Aucune colonne p95 trouvée (candidats : {candidates}, "
        f"colonnes présentes : {list(df.columns)})"
    )


def wilson_interval(p_hat: float, n: int, alpha: float) -> Tuple[float, float, float]:
    """Intervalle de confiance binomial de Wilson (approx. 95 % si alpha=0.05).

    Retourne (center, low, high).
    """
    if n <= 0:
        return np.nan, np.nan, np.nan
    z = 1.959963984540054  # quantile ~N(0,1) pour 1 - alpha/2
    z2 = z * z
    denom = 1.0 + z2 / n
    center = (p_hat + z2 / (2.0 * n)) / denom
    half_width = (
        z
        * sqrt((p_hat * (1.0 - p_hat) + z2 / (4.0 * n)) / n)
        / denom
    )
    low = center - half_width
    high = center + half_width
    return center, low, high


@dataclass
class CoveragePoint:
    N: int
    coverage: float       # valeur utilisée pour le tracé (centre de Wilson)
    err_low: float        # >= 0
    err_high: float       # >= 0
    width_mean: float


def compute_coverage_curve(
    values: np.ndarray,
    *,
    outer: int,
    alpha: float,
    minN: int,
    npoints: int,
    seed: Optional[int] = None,
) -> List[CoveragePoint]:
    """Calcule couverture et largeur moyenne d’IC en fonction de N.

    Approche simplifiée :
    - on tire pour chaque N des sous-échantillons bootstrap (outer répétitions)
    - pour chaque sous-échantillon, on calcule un IC percentile (alpha/2, 1-alpha/2)
    - on compte la proportion de fois où la "référence" (médiane globale)
      est contenue dans l’IC
    - on construit un IC de Wilson sur cette proportion
    - on garde la largeur moyenne de cet IC percentile
    """
    rng = np.random.default_rng(seed)
    values = np.asarray(values, dtype=float)
    values = values[np.isfinite(values)]
    if values.size < 2:
        raise ValueError("Trop peu de valeurs finies pour le bootstrap.")

    true_ref = float(np.median(values))
    logging.info("Référence p95 utilisée (médiane globale) : %.6f", true_ref)

    maxN = int(values.size)
    if minN <= 0 or minN > maxN:
        raise ValueError(f"minN doit être dans [1, {maxN}] (reçu: {minN})")

    # Grille de N à explorer
    N_values = np.linspace(minN, maxN, num=npoints, dtype=int)
    N_values = np.unique(N_values)
    logging.info("Grille N utilisée : %s", N_values)

    points: List[CoveragePoint] = []
    for N in N_values:
        covers = 0
        widths: List[float] = []
        for _ in range(outer):
            idx = rng.integers(0, values.size, size=N)
            sample = values[idx]
            q_low = float(np.quantile(sample, alpha / 2.0))
            q_high = float(np.quantile(sample, 1.0 - alpha / 2.0))
            if q_high < q_low:
                q_low, q_high = q_high, q_low
            if q_low <= true_ref <= q_high:
                covers += 1
            widths.append(q_high - q_low)

        p_hat = covers / float(outer)
        center, low, high = wilson_interval(p_hat, outer, alpha)

        # On trace le centre de Wilson et on encode les barres comme distances
        coverage = center
        err_low = max(0.0, coverage - low)
        err_high = max(0.0, high - coverage)
        width_mean = float(np.mean(widths)) if widths else np.nan

        logging.info(
            "N=%d : p_hat=%.3f, coverage(center)=%.3f [%.3f, %.3f], width_mean=%.5f",
            N,
            p_hat,
            coverage,
            low,
            high,
            width_mean,
        )

        points.append(
            CoveragePoint(
                N=int(N),
                coverage=coverage,
                err_low=err_low,
                err_high=err_high,
                width_mean=width_mean,
            )
        )

    return points


def plot_coverage_and_width(
    points: Sequence[CoveragePoint],
    *,
    alpha: float,
    out_png: Path,
    dpi: int,
    ymin_cov: Optional[float] = None,
    ymax_cov: Optional[float] = None,
) -> None:
    """Trace couverture vs N + largeur d’IC vs N (2 panneaux)."""
    N = np.array([p.N for p in points], dtype=float)
    cov = np.array([p.coverage for p in points], dtype=float)
    err_low = np.array([p.err_low for p in points], dtype=float)
    err_high = np.array([p.err_high for p in points], dtype=float)
    width_mean = np.array([p.width_mean for p in points], dtype=float)

    fig, (ax_cov, ax_width) = plt.subplots(1, 2, figsize=(10, 4.5), dpi=dpi)

    yerr = np.vstack([err_low, err_high])
    ax_cov.errorbar(
        N,
        cov,
        yerr=yerr,
        fmt="o-",
        lw=1.6,
        ms=5,
        capsize=3,
        label="Couverture empirique (centre Wilson)",
    )
    nominal = 1.0 - alpha
    ax_cov.axhline(nominal, color="crimson", ls="--", lw=1.4, label="Niveau nominal")

    ax_cov.set_xlabel("Taille d'échantillon N")
    ax_cov.set_ylabel("Couverture (fréquence IC contenant la référence)")
    ax_cov.set_title("Couverture bootstrap vs N")
    if ymin_cov is not None or ymax_cov is not None:
        ymin = ymin_cov if ymin_cov is not None else ax_cov.get_ylim()[0]
        ymax = ymax_cov if ymax_cov is not None else ax_cov.get_ylim()[1]
        ax_cov.set_ylim(ymin, ymax)
    ax_cov.grid(True, which="both", linestyle=":", linewidth=0.5)
    ax_cov.legend(loc="best", frameon=True)

    ax_width.plot(N, width_mean, "o-", lw=1.8, ms=5)
    ax_width.set_xlabel("Taille d'échantillon N")
    ax_width.set_ylabel("Largeur moyenne IC (rad)")
    ax_width.set_title("Largeur d'IC vs N")
    ax_width.grid(True, which="both", linestyle=":", linewidth=0.5)

    fig.tight_layout()
    out_png.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(out_png, dpi=dpi)
    logging.info("Figure écrite : %s", out_png)


def write_manifest(
    points: Sequence[CoveragePoint],
    *,
    results_csv: Path,
    p95_col: str,
    outer: int,
    inner: int,
    M: int,
    alpha: float,
    seed: Optional[int],
    out_png: Path,
) -> Path:
    """Écrit un manifest JSON compatible avec plot_fig07_synthesis.py."""
    out_manifest = out_png.with_suffix(out_png.suffix + ".manifest.json")

    results: List[dict] = []
    for p in points:
        results.append(
            {
                "N": p.N,
                "coverage": p.coverage,
                "coverage_err95_low": p.err_low,
                "coverage_err95_high": p.err_high,
                "width_mean_rad": p.width_mean,
            }
        )

    manifest = {
        "meta": {
            "script": "plot_fig03b_coverage_bootstrap_vs_n.py",
            "version": 1,
            "figure": out_png.name,
        },
        "params": {
            "results_csv": str(results_csv),
            "p95_col": p95_col,
            "outer_B": outer,
            "inner_B": inner,
            "M": M,
            "alpha": alpha,
            "seed": seed,
        },
        "results": results,
    }

    out_manifest.parent.mkdir(parents=True, exist_ok=True)
    with out_manifest.open("w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)
    logging.info("Manifest écrit : %s", out_manifest)
    return out_manifest


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def build_arg_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        description=(
            "Fig. 03b – Couverture bootstrap vs N (Chapitre 10).\n"
            "Génère une figure + manifest JSON pour la synthèse (fig. 07)."
        ),
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    p.add_argument(
        "--results",
        required=True,
        help="CSV des résultats Monte-Carlo (avec colonne p95).",
    )
    p.add_argument(
        "--p95-col",
        default=None,
        help="Nom explicite de la colonne p95 (sinon détection automatique).",
    )
    p.add_argument(
        "--out",
        default="zz-figures/chapter10/10_fig_03_b_coverage_bootstrap_vs_n.png",
        help="Chemin de sortie de la figure PNG.",
    )
    p.add_argument(
        "--outer",
        type=int,
        default=400,
        help="Nombre de répétitions bootstrap (courbe de couverture).",
    )
    p.add_argument(
        "--inner",
        type=int,
        default=2000,
        help="Paramètre décoratif pour manifest (non utilisé dans cette version).",
    )
    p.add_argument(
        "--M",
        type=int,
        default=2000,
        help="Paramètre décoratif pour manifest (non utilisé dans cette version).",
    )
    p.add_argument(
        "--alpha",
        type=float,
        default=0.05,
        help="Niveau d'erreur de l'IC (alpha).",
    )
    p.add_argument(
        "--seed",
        type=int,
        default=12345,
        help="Graine RNG.",
    )
    p.add_argument(
        "--minN",
        type=int,
        default=100,
        help="Taille N minimale.",
    )
    p.add_argument(
        "--npoints",
        type=int,
        default=10,
        help="Nombre de points N sur la courbe.",
    )
    p.add_argument(
        "--dpi",
        type=int,
        default=300,
        help="Résolution de la figure.",
    )
    p.add_argument(
        "--ymin-coverage",
        type=float,
        default=None,
        help="Ymin explicite pour la couverture (facultatif).",
    )
    p.add_argument(
        "--ymax-coverage",
        type=float,
        default=None,
        help="Ymax explicite pour la couverture (facultatif).",
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

    results_csv = Path(args.results)
    if not results_csv.exists():
        raise FileNotFoundError(f"CSV des résultats introuvable : {results_csv}")

    logging.info("Lecture des résultats : %s", results_csv)
    df = pd.read_csv(results_csv)
    p95_col = detect_p95_column(df, args.p95_col)
    values = df[p95_col].to_numpy()

    points = compute_coverage_curve(
        values,
        outer=args.outer,
        alpha=args.alpha,
        minN=args.minN,
        npoints=args.npoints,
        seed=args.seed,
    )

    out_png = Path(args.out)
    plot_coverage_and_width(
        points,
        alpha=args.alpha,
        out_png=out_png,
        dpi=args.dpi,
        ymin_cov=args.ymin_coverage,
        ymax_cov=args.ymax_coverage,
    )

    write_manifest(
        points,
        results_csv=results_csv,
        p95_col=p95_col,
        outer=args.outer,
        inner=args.inner,
        M=args.M,
        alpha=args.alpha,
        seed=args.seed,
        out_png=out_png,
    )


if __name__ == "__main__":
    main()
