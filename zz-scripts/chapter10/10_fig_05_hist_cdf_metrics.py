#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
plot_fig05_hist_cdf_metrics.py

Figure 05 : Histogramme + CDF des p95 recalculés (métrique circulaire).
Produit un PNG.

Exemple (appel manuel) :
python zz-scripts/chapter10/plot_fig05_hist_cdf_metrics.py \
  --results zz-data/chapter10/10_results_global_scan.csv \
  --out 10_fig_05_hist_cdf_metrics.png \
  --ref-p95 0.7104087123286049 --bins 50 --dpi 150 \
  --zoom-x 3.0 --zoom-y 35 --zoom-dx 0.30 --zoom-dy 30
"""
from __future__ import annotations


import argparse
import hashlib
import shutil
import tempfile
import textwrap
from pathlib import Path
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.lines as mlines
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


# ---------- utils ----------
def detect_p95_column(df: pd.DataFrame) -> str:
    """
    Essaie de trouver la bonne colonne p95.

    On commence par quelques noms standards (ancienne et nouvelle version),
    puis on cherche toute colonne contenant "p95".
    """
    candidates = [
        "p95_20_300_recalc",
        "p95_20_300_circ",
        "p95_20_300_recalced",
        "p95_20_300",
        "p95_circ",
        "p95_recalc",
        "p95_rad",  # nouveau format (10_results_global_scan.csv)
        "p95",
    ]
    for c in candidates:
        if c in df.columns:
            return c
    for c in df.columns:
        if "p95" in c.lower():
            return c
    raise KeyError(
        "Aucune colonne 'p95' détectée dans le CSV results "
        f"(colonnes présentes : {list(df.columns)})"
    )


def _sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()


def safe_save(filepath: Path | str, fig, **savefig_kwargs) -> bool:
    """
    Sauvegarde fig en évitant de toucher le mtime si le PNG est identique.
    Retourne True si le fichier a changé, False sinon.
    """
    path = Path(filepath)
    path.parent.mkdir(parents=True, exist_ok=True)

    if path.exists():
        with tempfile.NamedTemporaryFile(delete=False, suffix=path.suffix) as tmp:
            tmp_path = Path(tmp.name)
        try:
            fig.savefig(tmp_path, **savefig_kwargs)
            if _sha256(tmp_path) == _sha256(path):
                tmp_path.unlink()
                return False
            shutil.move(tmp_path, path)
            return True
        finally:
            if tmp_path.exists():
                tmp_path.unlink()

    fig.savefig(path, **savefig_kwargs)
    return True


# ---------- main ----------
def main() -> None:
    ap = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    ap.add_argument(
        "--results",
        default=None,
        help=(
            "CSV avec p95 circulaire recalculé. "
            "Par défaut : zz-data/chapter10/10_results_global_scan.csv."
        ),
    )
    ap.add_argument(
        "--out",
        default="zz-figures/chapter10/10_fig_05_hist_cdf_metrics.png",
        help="PNG de sortie",
    )
    ap.add_argument(
        "--ref-p95",
        type=float,
        default=0.7104087123286049,
        help="p95 de référence [rad]",
    )
    ap.add_argument(
        "--bins",
        type=int,
        default=50,
        help="Nb de bacs histogramme",
    )
    ap.add_argument(
        "--dpi",
        type=int,
        default=150,
        help="DPI du PNG",
    )
    # position et fenêtre du zoom (centre + demi-étendues)
    ap.add_argument(
        "--zoom-x",
        type=float,
        default=3.0,
        help="centre X du zoom (rad)",
    )
    ap.add_argument(
        "--zoom-y",
        type=float,
        default=35.0,
        help="centre Y du zoom (counts)",
    )
    ap.add_argument(
        "--zoom-dx",
        type=float,
        default=0.30,
        help="demi-largeur X du zoom (rad)",
    )
    ap.add_argument(
        "--zoom-dy",
        type=float,
        default=30.0,
        help="demi-hauteur Y du zoom (counts)",
    )
    # taille du panneau de zoom (fraction de l’axe)
    ap.add_argument(
        "--zoom-w",
        type=float,
        default=0.35,
        help="largeur du zoom (fraction de l’axe principal)",
    )
    ap.add_argument(
        "--zoom-h",
        type=float,
        default=0.25,
        help="hauteur du zoom (fraction de l’axe principal)",
    )
    args = ap.parse_args()
    # --- normalisation sortie : si '--out' est un nom nu -> redirige vers zz-figures/chapter10/ ---
    outp = Path(args.out)
    if outp.parent == Path("."):
        outp = Path("zz-figures/chapter10") / outp.name
    outp.parent.mkdir(parents=True, exist_ok=True)
    args.out = str(outp)


    # --- fichier par défaut si non fourni (pour le pipeline minimal) ---
    if args.results is None:
        args.results = "zz-data/chapter10/10_results_global_scan.csv"
        print(f"[INFO] --results non fourni ; utilisation par défaut de '{args.results}'.")

    # --- lecture & colonne p95 ---
    df = pd.read_csv(args.results)
    p95_col = detect_p95_column(df)
    p95 = df[p95_col].dropna().astype(float).values

    # Heuristique : si colonne "originale" dispo, compter les corrections unwrap
    wrapped_corrected: int | None = None
    for cand in ("p95_20_300", "p95_raw", "p95_orig", "p95_20_300_raw"):
        if cand in df.columns and cand != p95_col:
            diff = df[[cand, p95_col]].dropna().astype(float)
            wrapped_corrected = int((np.abs(diff[cand] - diff[p95_col]) > 1e-6).sum())
            break

    # --- stats ---
    N = p95.size
    if N == 0:
        raise SystemExit("Aucune valeur p95 non-NaN trouvée dans le CSV.")

    mean = float(np.mean(p95))
    median = float(np.median(p95))
    std = float(np.std(p95, ddof=0))
    n_below = int((p95 < args.ref_p95).sum())
    frac_below = n_below / max(1, N)

    # --- figure ---
    plt.style.use("classic")
    fig, ax = plt.subplots(figsize=(14, 6))

    # Histogramme (counts)
    counts, bins, patches = ax.hist(
        p95,
        bins=args.bins,
        alpha=0.7,
        edgecolor="k",
    )
    ax.set_ylabel("Effectifs")
    ax.set_xlabel(f"{p95_col} [rad]")

    # CDF empirique (axe droit)
    ax2 = ax.twinx()
    sorted_p = np.sort(p95)
    ecdf = np.arange(1, N + 1) / N
    cdf_line, = ax2.plot(sorted_p, ecdf, lw=2)
    ax2.set_ylabel("CDF empirique")
    ax2.set_ylim(0.0, 1.02)

    # Ligne verticale de référence
    ax.axvline(args.ref_p95, color="crimson", linestyle="--", lw=2)
    ax.text(
        args.ref_p95,
        ax.get_ylim()[1] * 0.45,
        f"ref = {args.ref_p95:.4f} rad",
        color="crimson",
        rotation=90,
        va="center",
        ha="right",
        fontsize=10,
    )

    # Boîte de stats (haut-gauche)
    stat_lines = [
        f"N = {N}",
        f"mean = {mean:.3f}",
        f"median = {median:.3f}",
        f"std = {std:.3f}",
    ]
    if wrapped_corrected is not None:
        stat_lines.append(f"wrapped_corrected = {wrapped_corrected}")
    stat_lines.append(f"p(p95 < ref) = {frac_below:.3f} (n={n_below})")
    stat_text = "\n".join(stat_lines)
    ax.text(
        0.02,
        0.98,
        stat_text,
        transform=ax.transAxes,
        fontsize=10,
        va="top",
        ha="left",
        bbox=dict(
            boxstyle="round",
            fc="white",
            ec="black",
            lw=1,
            alpha=0.95,
        ),
    )

    # Petite légende (sous la boîte de stats)
    handles: list = []
    # histogramme : premier patch comme handle
    if len(patches) > 0:
        handles.append(patches[0])
    else:
        from matplotlib.patches import Rectangle

        handles.append(
            Rectangle(
                (0, 0),
                1,
                1,
                facecolor="C0",
                edgecolor="k",
                alpha=0.7,
            )
        )
    proxy_cdf = mlines.Line2D([], [], color=cdf_line.get_color(), lw=2)
    proxy_ref = mlines.Line2D([], [], color="crimson", linestyle="--", lw=2)
    handles += [proxy_cdf, proxy_ref]
    labels = ["Histogram (counts)", "Empirical CDF", "p95 ref"]
    ax.legend(
        handles,
        labels,
        loc="upper left",
        bbox_to_anchor=(0.02, 0.72),
        frameon=True,
        fontsize=10,
    )

    # Inset zoom — centré dans l’axe, fenêtre contrôlée par (zoom-x/y, zoom-dx/dy).
    inset_ax = inset_axes(
        ax,
        width=f"{args.zoom_w * 100:.0f}%",
        height=f"{args.zoom_h * 100:.0f}%",
        loc="upper center",
        bbox_to_anchor=(0.30, 0.60, args.zoom_w, args.zoom_h),
        bbox_transform=ax.transAxes,
        borderpad=0.8,
    )

    # Fenêtre X/Y demandée
    x0, x1 = args.zoom_x - args.zoom_dx, args.zoom_x + args.zoom_dx
    y0_user = max(0.0, args.zoom_y - args.zoom_dy)
    y1_user = args.zoom_y + args.zoom_dy

    # Histogramme restreint au domaine X du zoom pour déterminer le sommet réel
    mask_x = (p95 >= x0) & (p95 <= x1)
    data_inset = p95[mask_x] if mask_x.sum() >= 5 else p95
    inset_counts, inset_bins, _ = inset_ax.hist(
        data_inset,
        bins=min(args.bins, 30),
        alpha=0.9,
        edgecolor="k",
    )

    # Hauteur auto : on s'assure d'englober le pic (avec marge 10 %)
    ymax_auto = (np.max(inset_counts) if inset_counts.size else 1.0) * 1.10
    y0 = 0.0
    y1 = max(y1_user, ymax_auto)

    inset_ax.set_xlim(x0, x1)
    inset_ax.set_ylim(y0, y1)
    inset_ax.set_title("zoom", fontsize=10)
    inset_ax.tick_params(axis="both", which="major", labelsize=8)

    # Removed connection lines to declutter

    # Titre (taille 15)
    ax.set_title(f"Global distribution of {p95_col}", fontsize=15)

    # Note de bas de figure
    wrapped_val = wrapped_corrected if wrapped_corrected is not None else 0
    foot = textwrap.fill(
        (
            r"Métrique : distance circulaire (mod $2\pi$). "
            r"Définition : p95 = $95^{\mathrm{e}}$ centile de $|\Delta\phi(f)|$ "
            r"pour $f\in[20,300]\ \mathrm{Hz}$. "
            r"Corrections : sauts de branchement corrigés, "
            rf"$N_{{\mathrm{{wrapped\_corrected}}}} = {wrapped_val}$. "
            r"Comparaison : "
            rf"$p(\mathrm{{p95}}<\mathrm{{p95_{{ref}}}}) = {frac_below:.3f}$ "
            rf"(n = {n_below})."
        ),
        width=180,
    )

    # réserver de l'espace en bas puis placer le texte
    plt.tight_layout(rect=[0, 0.14, 1, 0.98])
    fig.text(0.5, 0.04, foot, ha="center", va="bottom", fontsize=9)

    updated = safe_save(args.out, fig, dpi=args.dpi)
    status = "Wrote" if updated else "Unchanged (identique)"
    print(f"{status} : {args.out}")


if __name__ == "__main__":
    main()
