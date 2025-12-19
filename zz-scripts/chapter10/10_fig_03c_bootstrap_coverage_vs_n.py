#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
plot_fig03b_bootstrap_coverage_vs_n.py

CH10 – Figure 03b : couverture empirique (IC percentile 95%) vs N
+ largeur moyenne des IC, avec manifest JSON pour la synthèse (fig07).

Basé sur : tracer_fig03b_coverage_bootstrap_vs_n.py

Adaptations CH10 :
- --results optionnel, défaut = zz-data/chapter10/10_results_global_scan.csv
- --out par défaut = zz-figures/chapter10/10_fig_03c_bootstrap_coverage_vs_n.png
- minN par défaut = 10 (plus de plantage quand Mtot=50)
- detect_p95_column sait gérer p95_rad
- manifest écrit à côté du PNG, même format que fig07_synthesis attend.

Schéma Monte Carlo (notation M / outer_B / inner_B)
---------------------------------------------------
- M désigne le nombre de réplicats externes utilisés pour estimer la couverture,
  et correspond à outer_B dans le manifeste.
- Pour chaque taille d’échantillon N, on tire M sous-échantillons de taille N
  (bootstrap « externe ») ; pour chacun, on construit un IC 95 % par bootstrap
  interne avec inner_B ré-échantillonnages (bootstrap percentile).
- Le manifeste associe donc :
    * "M"        ≡ nombre de réalisations externes par point N (outer_B),
    * "outer_B"  ≡ nombre de réplicats externes pour la couverture,
    * "inner_B"  ≡ nombre de réplicats internes pour l’IC percentile.
Ces trois champs sont lus ensuite par plot_fig07_synthesis.py pour reconstruire
les courbes de couverture et les largeurs d’IC en fonction de N.

"""
from __future__ import annotations
from pathlib import Path

def _repro_generated_at_utc() -> str:
    # Reproductible : SOURCE_DATE_EPOCH ou timestamp du dernier commit git
    epoch = os.environ.get("SOURCE_DATE_EPOCH")
    if epoch:
        try:
            ts = int(float(epoch))
            return datetime.datetime.fromtimestamp(ts, tz=datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        except Exception:
            pass
    try:
        repo_root = Path(__file__).resolve().parents[2]
        out = subprocess.check_output(["git", "log", "-1", "--format=%ct"], cwd=repo_root, text=True).strip()
        ts = int(out)
        return datetime.datetime.fromtimestamp(ts, tz=datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    except Exception:
        return datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

def _carry_or_repro_generated_at(manifest_path: Path) -> str:
    try:
        if manifest_path.exists():
            old = json.loads(manifest_path.read_text(encoding="utf-8"))
            if isinstance(old, dict):
                ga = old.get("generated_at")
                if isinstance(ga, str) and ga.strip():
                    return ga
    except Exception:
        pass
    return _repro_generated_at_utc()


import datetime
import subprocess
import argparse
import json
import os
import time
from dataclasses import dataclass

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from mpl_toolkits.axes_grid1.inset_locator import inset_axes
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


# ----------------------------- utilitaires ---------------------------------


def detect_p95_column(df: pd.DataFrame, hint: str | None) -> str:
    """Détecte la colonne p95 dans le CSV (avec support de p95_rad)."""
    if hint and hint in df.columns:
        return hint
    for c in [
        "p95_rad",
        "p95_20_300_recalc",
        "p95_20_300_circ",
        "p95_20_300",
        "p95_circ",
        "p95_recalc",
        "p95",
    ]:
        if c in df.columns:
            return c
    for c in df.columns:
        if "p95" in c.lower():
            return c
    raise KeyError("Aucune colonne p95 détectée (utiliser --p95-col).")


def wilson_err95(p: float, n: int) -> tuple[float, float]:
    """
    Retourne (err_bas, err_haut) Wilson 95% pour une proportion p sur n.

    NB : pour éviter le crash matplotlib ('yerr' must not contain negative values),
    on CLAMPE les erreurs à >= 0 même si, numériquement, p sort légèrement de [lo, hi].
    """
    if n <= 0:
        return 0.0, 0.0

    z = 1.959963984540054  # 97.5e percentile
    denom = 1.0 + (z * z) / n
    center = (p + (z * z) / (2 * n)) / denom
    half = (z / denom) * np.sqrt((p * (1 - p) / n) + (z * z) / (4 * n * n))
    lo = max(0.0, center - half)
    hi = min(1.0, center + half)

    err_low = p - lo
    err_high = hi - p

    # Clamp de sécurité pour éviter les yerr négatifs
    if err_low < 0.0:
        err_low = 0.0
    if err_high < 0.0:
        err_high = 0.0

    return err_low, err_high


def bootstrap_percentile_ci(
    vals: np.ndarray,
    B: int,
    rng: np.random.Generator,
    alpha: float = 0.05,
) -> tuple[float, float]:
    """IC percentile (95% par défaut) pour la moyenne linéaire."""
    n = len(vals)
    boots = np.empty(B, dtype=float)
    for b in range(B):
        samp = rng.choice(vals, size=n, replace=True)
        boots[b] = float(np.mean(samp))
    lo = float(np.percentile(boots, 100 * (alpha / 2)))
    hi = float(np.percentile(boots, 100 * (1 - alpha / 2)))
    return lo, hi


def circ_mean_rad(angles: np.ndarray) -> float:
    """Moyenne circulaire d'angles (radians)."""
    z = np.mean(np.exp(1j * angles))
    return float(np.angle(z))


@dataclass
class RowRes:
    N: int
    coverage: float
    cov_err95_low: float
    cov_err95_high: float
    width_mean: float
    n_hits: int
    method: str


# ------------------------------- coeur --------------------------------------


def main() -> None:
    p = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )

    # NOTE: --results n'est plus "required": on a un défaut CH10.
    p.add_argument(
        "--results",
        default=None,
        help="CSV avec colonne p95 (défaut CH10 si omis).",
    )
    p.add_argument(
        "--p95-col",
        default=None,
        help="Nom exact de la colonne p95 (auto-détection si omis).",
    )
    p.add_argument(
        "--out",
        default="zz-figures/chapter10/10_fig_03c_bootstrap_coverage_vs_n.png",
        help="PNG de sortie",
    )
    p.add_argument(
        "--outer",
        type=int,
        default=400,
        help="Nombre de réplicats externes (couverture).",
    )
    p.add_argument(
        "--M",
        type=int,
        default=None,
        help="Alias de --outer (si précisé, remplace --outer).",
    )
    p.add_argument(
        "--inner",
        type=int,
        default=2000,
        help="Nombre de réplicats internes (IC).",
    )
    p.add_argument(
        "--alpha",
        type=float,
        default=0.05,
        help="Niveau d'erreur pour IC (ex. 0.05).",
    )
    p.add_argument(
        "--npoints",
        type=int,
        default=10,
        help="Nombre de points N.",
    )
    # IMPORTANT : minN=10 par défaut (et non 100) pour Mtot=50 en CH10.
    p.add_argument(
        "--minN",
        type=int,
        default=10,
        help="Plus petit N (sera tronqué à [10, M]).",
    )
    p.add_argument(
        "--seed",
        type=int,
        default=12345,
        help="Seed RNG.",
    )
    p.add_argument(
        "--dpi",
        type=int,
        default=300,
        help="DPI PNG.",
    )
    p.add_argument(
        "--ymin-coverage",
        type=float,
        default=None,
        help="Ymin panneau couverture.",
    )
    p.add_argument(
        "--ymax-coverage",
        type=float,
        default=None,
        help="Ymax panneau couverture.",
    )
    p.add_argument(
        "--title-left",
        default="CI coverage vs N (estimator: mean)",
        help="Titre panneau gauche.",
    )
    p.add_argument(
        "--title-right",
        default="Mean CI width vs N",
        help="Titre panneau droit.",
    )
    # options ajoutées
    p.add_argument(
        "--hires2000",
        action="store_true",
        help="Utiliser outer=2000, inner=2000 (ne change pas les défauts globaux).",
    )
    p.add_argument(
        "--angular",
        action="store_true",
        help="Active l'encart comparant moyenne linéaire vs moyenne circulaire (p95 en radians).",
    )
    # figure annexe de sensibilité
    p.add_argument(
        "--make-sensitivity",
        action="store_true",
        help="Produit une figure annexe de sensibilité (coverage vs outer/inner).",
    )
    p.add_argument(
        "--sens-mode",
        choices=["outer", "inner"],
        default="outer",
        help="Paramètre de sensibilité (outer ou inner).",
    )
    p.add_argument(
        "--sens-N",
        type=int,
        default=None,
        help="N fixe utilisé pour la sensibilité (défaut: N max du dataset).",
    )
    p.add_argument(
        "--sens-B-list",
        default="100,200,400,800,1200,2000",
        help="Liste de B séparés par virgules pour la sensibilité.",
    )
    args = p.parse_args()

    # --------------------------- lecture des données -------------------------
    if args.results is None:
        args.results = "zz-data/chapter10/10_results_global_scan.csv"
        print(
            "[INFO] --results non fourni ; utilisation par défaut de "
            "'zz-data/chapter10/10_results_global_scan.csv'."
        )

    df = pd.read_csv(args.results)
    p95_col = detect_p95_column(df, args.p95_col)
    vals_all = df[p95_col].dropna().astype(float).values
    Mtot = len(vals_all)
    if Mtot == 0:
        raise SystemExit("Aucune donnée p95.")
    print(f"[INFO] Dataset M={Mtot}, p95_col={p95_col}")

    # préréglage haute précision si demandé
    if args.hires2000:
        args.outer = 2000
        args.inner = 2000
        if args.M is None:
            args.M = 2000
        print("[INFO] Mode haute précision: outer=2000, inner=2000")

    # --------------------------- grille en N ---------------------------------
    minN = max(10, int(args.minN))
    if minN > Mtot:
        minN = max(1, Mtot)
    N_list = np.unique(np.linspace(minN, Mtot, args.npoints, dtype=int))
    if N_list[-1] != Mtot:
        N_list = np.append(N_list, Mtot)
    print(f"[INFO] N_list = {N_list.tolist()}")

    outer_for_cov = int(args.M) if args.M is not None else int(args.outer)
    print(
        f"[INFO] outer={outer_for_cov}, inner={args.inner}, "
        f"alpha={args.alpha}, seed={args.seed}"
    )

    rng = np.random.default_rng(args.seed)
    ref_value_lin = float(np.mean(vals_all))
    ref_value_circ = float(circ_mean_rad(vals_all)) if args.angular else None

    # --------------------------- boucle bootstrap ----------------------------
    results: list[RowRes] = []
    for idx, N in enumerate(N_list, start=1):
        hits = 0
        widths = np.empty(outer_for_cov, dtype=float)
        for b in range(outer_for_cov):
            samp = rng.choice(vals_all, size=int(N), replace=True)
            lo, hi = bootstrap_percentile_ci(
                samp, args.inner, rng, alpha=args.alpha
            )
            widths[b] = hi - lo
            if (ref_value_lin >= lo) and (ref_value_lin <= hi):
                hits += 1
        p_hat = hits / outer_for_cov
        e_lo, e_hi = wilson_err95(p_hat, outer_for_cov)
        results.append(
            RowRes(
                N=int(N),
                coverage=float(p_hat),
                cov_err95_low=float(e_lo),
                cov_err95_high=float(e_hi),
                width_mean=float(np.mean(widths)),
                n_hits=int(hits),
                method="percentile",
            )
        )
        print(
            f"[{idx}/{len(N_list)}] N={N:5d}  "
            f"coverage={p_hat:0.3f}  width_mean={np.mean(widths):0.5f} rad"
        )

    # ------------------------------- tracé principal -------------------------
    plt.style.use("classic")
    fig = plt.figure(figsize=(15, 6))
    gs = fig.add_gridspec(1, 2, width_ratios=[5, 3], wspace=0.25)
    ax1 = fig.add_subplot(gs[0, 0])  # couverture
    ax2 = fig.add_subplot(gs[0, 1])  # largeur

    # CI coverage + Wilson error bars
    xN = [r.N for r in results]
    yC = [r.coverage for r in results]
    yerr_low = [r.cov_err95_low for r in results]
    yerr_high = [r.cov_err95_high for r in results]
    ax1.errorbar(
        xN,
        yC,
        yerr=[yerr_low, yerr_high],
        fmt="o-",
        lw=1.6,
        ms=6,
        color="tab:blue",
        ecolor="tab:blue",
        elinewidth=1.0,
        capsize=3,
        label="Empirical CI coverage",
    )
    ax1.axhline(
        1 - args.alpha,
        color="crimson",
        ls="--",
        lw=1.5,
        label="Niveau nominal 95%",
    )

    ax1.set_xlabel(r"Sample Size $N$")
    ax1.set_ylabel("CI Coverage (95% contains reference)")
    ax1.set_title(args.title_left)
    if (args.ymin_coverage is not None) or (args.ymax_coverage is not None):
        ymin = (
            args.ymin_coverage
            if args.ymin_coverage is not None
            else ax1.get_ylim()[0]
        )
        ymax = (
            args.ymax_coverage
            if args.ymax_coverage is not None
            else ax1.get_ylim()[1]
        )
        ax1.set_ylim(ymin, ymax)
    ax1.legend(loc="lower left", frameon=True)

    # Boîte d'info (haut gauche)
    txt = (
        f"N = {Mtot}\n"
        f"mean(ref) = {ref_value_lin:0.3f} rad\n"
        f"outer B = {outer_for_cov}, inner B = {args.inner}\n"
        f"seed = {args.seed}\n"
        f"note: IC = percentile (inner bootstrap)"
    )
    ax1.text(
        0.02,
        0.97,
        txt,
        transform=ax1.transAxes,
        va="top",
        ha="left",
        bbox=dict(boxstyle="round", fc="white", ec="black", alpha=0.95),
    )

    # Inset "moyenne linéaire vs circulaire" si demandé
    if args.angular and (ref_value_circ is not None):
        inset = inset_axes(
            ax1,
            width="33%",
            height="27%",
            loc="lower left",
            bbox_to_anchor=(0.04, 0.08, 0.33, 0.27),
            bbox_transform=ax1.transAxes,
            borderpad=0.5,
        )
        bars = [ref_value_lin, ref_value_circ]
        inset.bar([0, 1], bars)
        inset.set_xticks([0, 1])
        inset.set_xticklabels(["mean\n(lin)", "mean\n(circ)"])
        inset.set_title("Référence N=max", fontsize=9)
        inset.set_ylabel("[rad]", fontsize=8)
        inset.tick_params(axis="both", labelsize=8)

    # Panneau largeur
    ax2.plot(xN, [r.width_mean for r in results], "-", lw=2.0, color="tab:green")
    ax2.set_xlabel("Taille d'échantillon N")
    ax2.set_ylabel("Mean 95% CI width [rad]")
    ax2.set_title(args.title_right)

    # >>> MARGIN BAS AJUSTÉE <<<
    fig.subplots_adjust(
        left=0.08, right=0.98, top=0.92, bottom=0.18, wspace=0.25
    )

    foot = (
        f"Bootstrap imbriqué: outer={outer_for_cov}, inner={args.inner}. "
        f"Référence = estimateur({Mtot}) = {ref_value_lin:0.3f} rad. "
        f"Seed={args.seed}."
    )
    fig.text(0.5, 0.012, foot, ha="center", fontsize=10)

    os.makedirs(os.path.dirname(args.out), exist_ok=True)
    fig.savefig(args.out, dpi=args.dpi)
    print(f"[OK] Figure écrite: {args.out}")

    # ---------------------------- manifest JSON ----------------------------
    manifest_path = Path(os.path.splitext(args.out)[0] + ".manifest.json")
    manifest = {
        "script": "plot_fig03b_bootstrap_coverage_vs_n.py",
        "generated_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "inputs": {"results": args.results, "p95_col": p95_col},
        "params": {
            # Nombre de réalisations Monte Carlo par point N
            "M": int(outer_for_cov),

            # Synonymes pour compatibilité avec plot_fig07_synthesis
            "outer_B": int(outer_for_cov),
            "inner_B": int(args.inner),

            # Noms historiques déjà utilisés dans ce script
            "outer": int(outer_for_cov),
            "inner": int(args.inner),

            "alpha": float(args.alpha),
            "seed": int(args.seed),
            "minN": int(args.minN),
            "npoints": int(args.npoints),
            "ymin_coverage": None if args.ymin_coverage is None else float(args.ymin_coverage),
            "ymax_coverage": None if args.ymax_coverage is None else float(args.ymax_coverage),
            "angular_inset": bool(args.angular),
        },
        "ref_value_linear_rad": float(ref_value_lin),
        "ref_value_circular_rad": None
        if ref_value_circ is None
        else float(ref_value_circ),
        "N_list": [int(x) for x in np.asarray(N_list).tolist()],
        "results": [
            {
                "N": int(r.N),
                "coverage": float(r.coverage),
                "coverage_err95_low": float(r.cov_err95_low),
                "coverage_err95_high": float(r.cov_err95_high),
                "width_mean_rad": float(r.width_mean),
                "hits": int(r.n_hits),
                "method": r.method,
            }
            for r in results
        ],
        "figure_path": args.out,
    }
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    manifest["generated_at"] = _carry_or_repro_generated_at(manifest_path)
    with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)
    print(f"[OK] Manifest écrit: {manifest_path}")

    # ------------------- Figure annexe: sensibilité -------------------------
    if args.make_sensitivity:
        mode = args.sens_mode
        sensN = int(args.sens_N) if args.sens_N is not None else int(N_list[-1])
        B_list = [int(x.strip()) for x in args.sens_B_list.split(",") if x.strip()]
        print(f"[INFO] Sensibilité: mode={mode}, N={sensN}, B_list={B_list}")

        rng2 = np.random.default_rng(args.seed + 7)
        cov_list, lo_list, hi_list = [], [], []

        for B in B_list:
            if mode == "outer":
                hits = 0
                for b in range(B):
                    samp = rng2.choice(vals_all, size=sensN, replace=True)
                    lo, hi = bootstrap_percentile_ci(
                        samp, args.inner, rng2, alpha=args.alpha
                    )
                    if (ref_value_lin >= lo) and (ref_value_lin <= hi):
                        hits += 1
                p_hat = hits / B
                e_lo, e_hi = wilson_err95(p_hat, B)
            else:
                hits = 0
                for b in range(outer_for_cov):
                    samp = rng2.choice(vals_all, size=sensN, replace=True)
                    lo, hi = bootstrap_percentile_ci(
                        samp, B, rng2, alpha=args.alpha
                    )
                    if (ref_value_lin >= lo) and (ref_value_lin <= hi):
                        hits += 1
                p_hat = hits / outer_for_cov
                e_lo, e_hi = wilson_err95(p_hat, outer_for_cov)

            cov_list.append(float(p_hat))
            lo_list.append(float(e_lo))
            hi_list.append(float(e_hi))
            print(f"[SENS] B={B:4d}  coverage={p_hat:0.3f}")

        figS, axS = plt.subplots(figsize=(7.5, 4.2))
        axS.errorbar(
            B_list,
            cov_list,
            yerr=[lo_list, hi_list],
            fmt="o-",
            color="tab:blue",
            ecolor="tab:blue",
            capsize=3,
            lw=1.6,
            ms=6,
            label="Empirical CI coverage",
        )
        axS.axhline(
            1 - args.alpha,
            color="crimson",
            ls="--",
            lw=1.5,
            label="Niveau nominal 95%",
        )
        axS.set_xlabel("B (outer)" if mode == "outer" else "B (inner)")
        axS.set_ylabel("CI Coverage (95% contains reference)")
        axS.set_title(
            f"Sensibilité de la couverture vs "
            f"{'outer' if mode == 'outer' else 'inner'}  (N={sensN})"
        )
        axS.legend(loc="lower left", frameon=True)
        figS.tight_layout()
        out_sens = os.path.splitext(args.out)[0] + f"_sensitivity_{mode}.png"
        figS.savefig(out_sens, dpi=args.dpi)
        print(f"[OK] Figure annexe écrite: {out_sens}")

        manifest_sens = {
            "script": "plot_fig03b_bootstrap_coverage_vs_n.py",
            "annex": "sensitivity",
            "generated_at": time.strftime(
                "%Y-%m-%dT%H:%M:%SZ", time.gmtime()
            ),
            "mode": mode,
            "N": int(sensN),
            "B_list": [int(b) for b in B_list],
            "coverage": [float(c) for c in cov_list],
            "err95_low": [float(e) for e in lo_list],
            "err95_high": [float(e) for e in hi_list],
            "figure_path": out_sens,
        }
        sens_path = os.path.splitext(out_sens)[0] + ".manifest.json"
        with open(sens_path, "w", encoding="utf-8") as f:
            json.dump(manifest_sens, f, indent=2)
        print(f"[OK] Manifest annexe écrit: {sens_path}")


if __name__ == "__main__":
    main()
