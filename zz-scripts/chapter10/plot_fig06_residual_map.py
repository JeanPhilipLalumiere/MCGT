#!/usr/bin/env python3
"""
plot_fig06_residual_map.py  —  Figure 6 finale

- Carte hexbin des résidus sur (m1,m2) avec réduction par médiane.
- Colorbar pré-scalée (affiche en ×10^exp rad ; défaut exp=-7).

Exemple :
python zz-scripts/chapter10/plot_fig06_residual_map.py \
  --results zz-data/chapter10/10_mc_results.circ.csv \
  --metric dp95 --abs --m1-col m1 --m2-col m2 \
  --orig-col p95_20_300 --recalc-col p95_20_300_recalc \
  --gridsize 36 --mincnt 3 --cmap viridis --vclip 1,99 \
  --scale-exp -7 --threshold 1e-6 \
  --figsize 15,9 --dpi 300 --manifest \
  --out zz-figures/chapter10/10_fig_06_heatmap_absdp95_m1m2.png
"""

from __future__ import annotations

import argparse
import json
import os

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.ticker import MaxNLocator


# ------------------------- utilitaires -------------------------------------
def wrap_pi(x: np.ndarray) -> np.ndarray:
    """Ramène les angles en radians dans (-π, π]."""
    return (x + np.pi) % (2 * np.pi) - np.pi


def detect_col(df: pd.DataFrame, candidates: list[str]) -> str:
    """Trouve une colonne par nom exact ou par inclusion insensible à la casse."""
    for c in candidates:
        if c and c in df.columns:
            return c
    for c in df.columns:
        lc = c.lower()
        for cand in candidates:
            if cand and cand.lower() in lc:
                return c
    raise KeyError(f"Impossible de trouver l'une des colonnes : {candidates}")


# --------------------------- script principal ------------------------------
def main():
    ap = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    ap.add_argument("--results", required=True, help="CSV d'entrée.")
    ap.add_argument("--metric", choices=["dp95", "dphi"], default="dp95")
    ap.add_argument(
        "--abs",
        action="store_true",
        help="Prendre la valeur absolue.")
    ap.add_argument("--m1-col", default="m1")
    ap.add_argument("--m2-col", default="m2")
    ap.add_argument( "--orig-col", default="p95_20_300",
                     help="Colonne p95 originale (dp95)." )
    ap.add_argument(
        "--recalc-col",
        default="p95_20_300_recalc",
        help="Colonne p95 recalculée (dp95).",
    )
    ap.add_argument(
        "--phi-ref-col",
        default=None,
        help="Colonne phi_ref (dphi).")
    ap.add_argument(
        "--phi-mcgt-col",
        default=None,
        help="Colonne phi_mcgt (dphi).")
    ap.add_argument("--gridsize", type=int, default=36)
    ap.add_argument(
        "--mincnt",
        type=int,
        default=3,
        help="Masque les hexagones avec nb<mincnt." )
    ap.add_argument("--cmap", default="viridis")
    ap.add_argument(
        "--vclip",
        default="1,99",
        help="Percentiles pour vmin,vmax (ex: '1,99')." )
    ap.add_argument( "--scale-exp", type=int, default=-
                     7, help="Exponent pour l'échelle ×10^exp rad." )
    ap.add_argument(
        "--threshold",
        type=float,
        default=1e-6,
        help="Seuil pour fraction |metric|>threshold [rad].",
    )
    ap.add_argument(
        "--figsize",
        default="15,9",
        help="Largeur,hauteur en pouces (ex: '15,9')." )
    ap.add_argument(
        '--style',
        choices=[
            'paper',
            'talk',
            'mono',
            'none'],
        default='none',
        help='Style de figure (opt-in)')
    args = ap.parse_args()
                        "--outdir",
                        type = str,
                        default = None,
                        help = "Dossier pour copier la figure (fallback $MCGT_OUTDIR)")


                            ap.add_argument(
    "--fmt",
    type = str,
    default = None,
    help = "Format savefig (png, pdf, etc.)")

        # ------------------------------------------------------------------ data
        df = pd.read_csv(args.results).dropna(subset=[args.m1_col, args.m2_col])
    x = df[args.m1_col].astype(float).values
        y = df[args.m2_col].astype(float).values
        N = len(df)

        if args.metric == "dp95":
        col_o = detect_col(df, [args.orig_col, "p95_20_300", "p95"])
    col_r = detect_col(
            df, [args.recalc_col, "p95_20_300_recalc", "p95_recalc"])
            raw = df[col_r].astype(float).values - df[col_o].astype(float).values
                metric_name = r"\Delta p_{95}"
                else:  # dphi
                col_ref = detect_col(df, [args.phi_ref_col or "phi_ref_fpeak"])
                col_mc = detect_col(
            df, [args.phi_mcgt_col or "phi_mcgt_fpeak", "phi_mcgt"])
                raw = wrap_pi(
            df[col_mc].astype(float).values - df[col_ref].astype(float).values
        )
            metric_name = r"\Delta \phi"

            if args.abs:
            raw = np.abs(raw)
            metric_label = rf"|{metric_name}|"
            else:
            metric_label = rf"{metric_name}"

            # Pré-scaling pour l'affichage : valeurs en unités “×10^exp rad”
            scale_factor = 10.0**args.scale_exp
            scaled = raw / scale_factor

            # vmin/vmax via percentiles sur *scaled*
            p_lo, p_hi = (float(t) for t in args.vclip.split(","))
            vmin = float(np.percentile(scaled, p_lo))
            vmax = float(np.percentile(scaled, p_hi))

            # Stats globales (sur scaled) + fraction > threshold (non-scalé)
            med = float(np.median(scaled))
            mean = float(np.mean(scaled))
            std = float(np.std(scaled, ddof=0))
            p95 = float(np.percentile(scaled, 95.0))
            frac_over = float(np.mean(np.abs(raw) > args.threshold))

            # ------------------------------ figure & axes ---------------------------
            fig_w, fig_h = (float(s) for s in args.figsize.split(","))
            plt.style.use("classic")
            fig = plt.figure(figsize=(fig_w, fig_h), dpi=args.dpi)

            # -> plus d'espace horizontal entre carte/colorbar et inserts (left=0.75)
            # -> moins d'espace vertical avec le footer (bottom abaissé)
            # left, bottom, width, height
            ax_main = fig.add_axes([0.07, 0.145, 0.56, 0.74])
            ax_cbar = fig.add_axes([0.645, 0.145, 0.025, 0.74])
            right_left = 0.75
            right_w = 0.23
            ax_cnt = fig.add_axes([right_left, 0.60, right_w, 0.30])
            ax_hist = fig.add_axes([right_left, 0.20, right_w, 0.30])

            # ------------------------------- main hexbin ---------------------------
            hb = ax_main.hexbin(
        x,
        y,
        C = scaled,
        gridsize = args.gridsize,
        reduce_C_function = np.median,
        mincnt = args.mincnt,
        vmin = vmin,
        vmax = vmax,
        cmap = args.cmap,
    )
        cbar = fig.colorbar(hb, cax=ax_cbar)
        exp_txt = f"× 10^{args.scale_exp}"  # ex: × 10^-7
        cbar.set_label(rf"{metric_label} {exp_txt} [rad]")

        ax_main.set_title(
        rf"Carte des résidus ${metric_label}$ sur $(m_1,m_2)$"
        + (" (absolu)" if args.abs else "")
    )
        ax_main.set_xlabel("m1")
        ax_main.set_ylabel("m2")

        # annotation mincnt
        ax_main.text(
        0.02,
        0.02,
        f"Hexagones vides = count < {args.mincnt}",
        transform = ax_main.transAxes,
        ha = "left",
        va = "bottom",
        bbox = dict(boxstyle="round", fc="white", ec="0.5", alpha=0.9),
        fontsize = 9,
    )

        # ------------------------------- counts inset --------------------------
        hb_counts = ax_cnt.hexbin(x, y, gridsize=args.gridsize, cmap="gray_r")
        cbar_cnt = fig.colorbar(
        hb_counts, ax = ax_cnt, orientation="vertical", fraction=0.046, pad=0.03
    )
        cbar_cnt.set_label("Counts")
        ax_cnt.set_title("Counts (par cellule)")
        ax_cnt.set_xlabel("m1")
        ax_cnt.set_ylabel("m2")
        ax_cnt.xaxis.set_major_locator(MaxNLocator(nbins=5))
        ax_cnt.yaxis.set_major_locator(MaxNLocator(nbins=5))

        # n_active = somme des points contenus dans les cellules ayant count >=
        # mincnt
        counts_arr = hb_counts.get_array()
        n_active = int(np.sum(counts_arr[counts_arr >= args.mincnt]))

        # ------------------------------- histogram inset -----------------------
        ax_hist.hist(
        scaled,
        bins = 40,
        color = "#1f77b4",
        edgecolor = "black",
        linewidth = 0.6)
            ax_hist.set_title("Distribution globale")
            ax_hist.set_xlabel(rf"metric {exp_txt} [rad]")
            ax_hist.set_ylabel("fréquence")

            # Boîte de stats (3 lignes)
            stats_lines = [
        rf"median={
            med:.2f}, mean={
            mean:.2f}",
        rf"std={
                std:.2f}, p95={
                    p95:.2f} {exp_txt} [rad]",
        rf"fraction |metric|>{
                        args.threshold:.0e} rad = {
                            100 * frac_over:.2f}%",
                             ]
                             ax_hist.text(
        0.02,
        0.02,
        "\n".join(stats_lines),
        transform = ax_hist.transAxes,
        ha = "left",
        va = "bottom",
        fontsize = 9,
        bbox = dict(boxstyle="round", fc="white", ec="0.5", alpha=0.9),
    )

        # ------------------------------- footers --------------------------------
        foot_scale = (
        f"Réduction par médiane (gridsize={
            args.gridsize}, mincnt={
            args.mincnt}). " f"Échelle: vmin={
                vmin:.6g}, vmax={
                    vmax:.6g}  (percentiles {p_lo}–{p_hi})." )
            foot_stats = (
        f"Stats globales: median={
            med:.2f}, mean={
            mean:.2f}, std={
                std:.2f}, " f"p95={
                    p95:.2f} {exp_txt} [rad]. N={N}, cellules actives (≥{
                        args.mincnt}) = " )

            # (subplots_adjust n'affecte pas add_axes, on l'utilise juste pour la bbox globale)
            fig.subplots_adjust(
        left = 0.07, right=0.96, top=0.96, bottom=0.12, wspace=0.34, hspace=0.30
    )
        fig.text(0.5, 0.053, foot_scale, ha="center", fontsize=10)
        fig.text(
        0.5,
        0.032,
        foot_stats + f"{n_active}/{N}.",
        ha = "center",
        fontsize = 10)

            # ------------------------------- sortie ---------------------------------
            os.makedirs(os.path.dirname(args.out), exist_ok=True)
            fig.savefig(args.out, dpi=args.dpi, bbox_inches="tight")
            print(f"[OK] Figure écrite: {args.out}")

            if args.manifest:
            man_path = os.path.splitext(args.out)[0] + ".manifest.json"
            manifest = {
            "script": "plot_fig06_residual_map.py",
            "generated_at": pd.Timestamp.utcnow().isoformat() + "Z",
            "inputs": {
                "csv": args.results,
                "m1_col": args.m1_col,
                "m2_col": args.m2_col,
            },
            "metric": {
                "name": args.metric,
                "absolute": bool(args.abs),
                "orig_col": args.orig_col,
                "recalc_col": args.recalc_col,
                "phi_ref_col": args.phi_ref_col,
                "phi_mcgt_col": args.phi_mcgt_col,
            },
            "plot_params": {
                "gridsize": int(args.gridsize),
                "mincnt": int(args.mincnt),
                "cmap": args.cmap,
                "vclip_percentiles": [p_lo, p_hi],
                "vmin_scaled": float(vmin),
                "vmax_scaled": float(vmax),
                "scale_exp": int(args.scale_exp),
                "threshold_rad": float(args.threshold),
                "figsize": [fig_w, fig_h],
                "dpi": int(args.dpi),
            },
            "dataset": {"N": int(N), "n_active_points": int(n_active)},
            "stats_scaled": {
                "median": med,
                "mean": mean,
                "std": std,
                "p95": p95,
                "fraction_abs_gt_threshold": frac_over,
            },
            "figure_path": args.out,
        }
        with open(man_path, "w", encoding="utf-8") as f:
            json.dump(manifest, f, indent=2)
        print(f"[OK] Manifest écrit: {man_path}")


            if __name__ == "__main__":
            main()

            # [MCGT POSTPARSE EPILOGUE v2]
            # (compact) delegate to common helper; best-effort wrapper
            try:
            import os
            import sys
            _here = os.path.abspath(os.path.dirname(__file__))
            _zz = os.path.abspath(os.path.join(_here, ".."))
            if _zz not in sys.path:
            sys.path.insert(0, _zz)
            from _common.postparse import apply as _mcgt_postparse_apply
            except Exception:
            def _mcgt_postparse_apply(*_a, **_k):
            pass
            try:
            if "args" in globals():
            _mcgt_postparse_apply(args, caller_file=__file__)
            except Exception:
            pass
