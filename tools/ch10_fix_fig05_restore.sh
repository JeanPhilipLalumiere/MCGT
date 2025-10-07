#!/usr/bin/env bash
set -euo pipefail

F="zz-scripts/chapter10/plot_fig05_hist_cdf_metrics.py"

echo "[RESTORE] Réécriture propre de $F (sans tight_layout)"

# Écrit une version saine du script
cat <<'PY' > "$F"
#!/usr/bin/env python3
"""
plot_fig05_hist_cdf_metrics.py
Figure 05 : Histogramme + CDF des p95 (métrique circulaire).
Options minimales : --results, --out, --bins, --dpi, --ref-p95
"""

from __future__ import annotations

import argparse
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.lines as mlines

# --- utils ---
def detect_p95_column(df: pd.DataFrame) -> str:
    candidates = [
        "p95_20_300_recalc",
        "p95_20_300_circ",
        "p95_20_300_recalced",
        "p95_20_300",
        "p95_circ",
        "p95_recalc",
        "p95",
    ]
    for c in candidates:
        if c in df.columns:
            return c
    # fallback: toute colonne contenant "p95"
    for c in df.columns:
        if "p95" in c.lower():
            return c
    raise KeyError("Aucune colonne 'p95' détectée dans le CSV results.")

# --- main ---
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--results", required=True, help="CSV avec p95 circulaire")
    ap.add_argument("--out", required=True, help="Chemin de sortie (image)")
    ap.add_argument("--bins", type=int, default=50, help="Histogram bins")
    ap.add_argument("--dpi", type=int, default=150, help="DPI PNG")
    ap.add_argument("--ref-p95", type=float, default=1.0, help="Référence p95 (ligne verticale)")
    args = ap.parse_args()

    # Lecture
    df = pd.read_csv(args.results)
    p95_col = detect_p95_column(df)
    p95 = df[p95_col].dropna().astype(float).values
    N = p95.size
    if N == 0:
        raise SystemExit("Aucune donnée p95 utilisable.")

    # Stats simples
    mean = float(np.mean(p95))
    median = float(np.median(p95))
    std = float(np.std(p95, ddof=0))
    n_below = int((p95 < args.ref_p95).sum())
    frac_below = n_below / max(1, N)

    # Figure
    plt.style.use("classic")
    fig, ax = plt.subplots(figsize=(14, 6), dpi=args.dpi)

    # Histogramme (counts)
    counts, bins, patches = ax.hist(p95, bins=args.bins, alpha=0.7, edgecolor="k")
    ax.set_ylabel("Effectifs")
    ax.set_xlabel(f"{p95_col} [rad]")

    # CDF (axe droit)
    ax2 = ax.twinx()
    sorted_p = np.sort(p95)
    ecdf = np.arange(1, N + 1) / N
    (cdf_line,) = ax2.plot(sorted_p, ecdf, lw=2)
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

    # Boîte de stats
    stat_lines = [
        f"N = {N}",
        f"mean = {mean:.3f}",
        f"median = {median:.3f}",
        f"std = {std:.3f}",
        f"p(P95 < ref) = {frac_below:.3f} (n={n_below})",
    ]
    ax.text(
        0.02, 0.98, "\n".join(stat_lines),
        transform=ax.transAxes,
        fontsize=10,
        va="top", ha="left",
        bbox=dict(boxstyle="round", fc="white", ec="black", lw=1, alpha=0.95),
    )

    # Légende
    if len(patches) > 0:
        hist_handle = patches[0]
    else:
        from matplotlib.patches import Rectangle
        hist_handle = Rectangle((0, 0), 1, 1, facecolor="C0", edgecolor="k", alpha=0.7)
    proxy_cdf = mlines.Line2D([], [], color=cdf_line.get_color(), lw=2)
    proxy_ref = mlines.Line2D([], [], color="crimson", linestyle="--", lw=2)
    ax.legend(
        [hist_handle, proxy_cdf, proxy_ref],
        ["Histogramme (effectifs)", "CDF empirique", "p95 réf"],
        loc="upper left",
        bbox_to_anchor=(0.02, 0.72),
        frameon=True,
        fontsize=10,
    )

    ax.set_title("Distribution de p95 (MC global)", fontsize=15)

    # Pied de figure
    foot = (
        r"Métrique : distance circulaire (mod $2\pi$). "
        r"Définition : p95 = 95e centile de $|\Delta\phi(f)|$ pour $f\in[20,300]$ Hz."
    )

    # Footer propre : PAS de tight_layout
    fig = plt.gcf()
    fig.text(0.5, 0.04, foot, ha="center", va="bottom", fontsize=9)
    fig.subplots_adjust(left=0.07, right=0.98, top=0.93, bottom=0.18)
    fig.savefig(args.out, dpi=args.dpi)
    print(f"Wrote : {args.out}")

if __name__ == "__main__":
    main()
PY

chmod +x "$F"

echo "[TEST] Regénère fig05"
OUT_DIR="zz-out/chapter10"
DATA_DIR="zz-data/chapter10"
mkdir -p "$OUT_DIR"
python3 "$F" --results "$DATA_DIR/dummy_results.csv" --out "$OUT_DIR/fig05_hist_cdf.png" --bins 40 --dpi 120

echo "[DONE] fig05 restaurée et testée."
