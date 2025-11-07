#!/usr/bin/env bash
set -euo pipefail

S="zz-scripts/chapter10"
F="$S/plot_fig07_synthesis.py"
O="zz-out/chapter10"

echo "[PATCH] Réécriture propre de $F"

cat > "$F" <<'PY'
#!/usr/bin/env python3
"""
plot_fig07_synthesis.py — Figure 7 (synthèse)
- Lit 1+ manifests (JSON) produits par plot_fig03b_bootstrap_coverage_vs_n.py
- Trace la couverture vs N (avec barres d'erreur) et la largeur moyenne d'IC vs N
- Peut écrire un CSV de synthèse (--summary-csv / --csv)
"""

from __future__ import annotations

import argparse
import json
import os
from dataclasses import dataclass
from typing import Any, List

import matplotlib.pyplot as plt
import numpy as np


# ---------- utils de lecture ----------
def load_manifest(path: str) -> dict:
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def _first(d: dict, keys: list[str], default=np.nan):
    for k in keys:
        if k in d and d[k] is not None:
            return d[k]
    return default


def _param(params: dict[str, Any], candidates: list[str], default=np.nan):
    return _first(params, candidates, default)


@dataclass
class Series:
    label: str
    N: np.ndarray
    coverage: np.ndarray
    err_low: np.ndarray
    err_high: np.ndarray
    width_mean: np.ndarray
    alpha: float
    params: dict


def series_from_manifest(man: dict, label_override: str | None = None) -> Series:
    results = man.get("results", [])
    if not results:
        raise ValueError("Manifest ne contient pas 'results'.")

    N = np.array([_first(r, ["N"], np.nan) for r in results], dtype=float)
    coverage = np.array([_first(r, ["coverage"], np.nan) for r in results], dtype=float)
    err_low = np.array([_first(r, ["coverage_err95_low", "coverage_err_low"], 0.0) for r in results], dtype=float)
    err_high = np.array([_first(r, ["coverage_err95_high", "coverage_err_high"], 0.0) for r in results], dtype=float)
    width_mean = np.array([_first(r, ["width_mean_rad", "width_mean"], np.nan) for r in results], dtype=float)

    params = man.get("params", {})
    alpha = float(_param(params, ["alpha", "conf_alpha"], 0.05))
    label = label_override or man.get("series_label") or man.get("label") or "série"

    return Series(
        label=label,
        N=N,
        coverage=coverage,
        err_low=err_low,
        err_high=err_high,
        width_mean=width_mean,
        alpha=alpha,
        params=params,
    )


def detect_reps_params(params: dict[str, Any]) -> tuple[float, float, float]:
    M = _param(params, ["M", "num_trials", "n_trials", "n_repeat", "repeats", "nsimu"], np.nan)
    outer_B = _param(params, ["outer_B", "outer", "B_outer", "outerB", "Bouter"], np.nan)
    inner_B = _param(params, ["inner_B", "inner", "B_inner", "innerB", "Binner"], np.nan)
    return float(M), float(outer_B), float(inner_B)


# ---------- CSV ----------
def save_summary_csv(series_list: List[Series], out_csv: str) -> None:
    import csv

    os.makedirs(os.path.dirname(out_csv) or ".", exist_ok=True)
    fields = ["series", "N", "coverage", "err95_low", "err95_high", "width_mean", "M", "outer_B", "inner_B", "alpha"]
    with open(out_csv, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        for s in series_list:
            M, outer_B, inner_B = detect_reps_params(s.params)
            for i in range(len(s.N)):
                w.writerow(
                    {
                        "series": s.label,
                        "N": int(s.N[i]) if np.isfinite(s.N[i]) else "",
                        "coverage": float(s.coverage[i]) if np.isfinite(s.coverage[i]) else "",
                        "err95_low": float(s.err_low[i]) if np.isfinite(s.err_low[i]) else "",
                        "err95_high": float(s.err_high[i]) if np.isfinite(s.err_high[i]) else "",
                        "width_mean": float(s.width_mean[i]) if np.isfinite(s.width_mean[i]) else "",
                        "M": int(M) if np.isfinite(M) else "",
                        "outer_B": int(outer_B) if np.isfinite(outer_B) else "",
                        "inner_B": int(inner_B) if np.isfinite(inner_B) else "",
                        "alpha": s.alpha,
                    }
                )


# ---------- tracé ----------
def plot_synthesis(series_list: List[Series], out_png: str, dpi: int = 300,
                   ymin_cov: float | None = None, ymax_cov: float | None = None) -> None:
    plt.style.use("classic")
    fig = plt.figure(figsize=(14, 6))
    ax1 = fig.add_axes([0.07, 0.15, 0.56, 0.78])  # couverture
    ax2 = fig.add_axes([0.68, 0.15, 0.28, 0.78])  # largeur IC

    colors = ["tab:blue", "tab:orange", "tab:green", "tab:red", "tab:purple", "tab:brown"]

    # Couverture
    for i, s in enumerate(series_list):
        c = colors[i % len(colors)]
        ax1.errorbar(
            s.N,
            s.coverage,
            yerr=[s.err_low, s.err_high],
            fmt="o-",
            lw=1.6,
            ms=6,
            color=c,
            ecolor=c,
            elinewidth=1.0,
            capsize=3,
            label=f"{s.label} (1-α={1.0 - s.alpha:.3f})",
        )
        ax1.axhline(1.0 - s.alpha, color=c, ls="--", lw=1.0, alpha=0.5)

    ax1.set_xlabel("Taille d'échantillon N")
    ax1.set_ylabel("Couverture (IC contient la référence)")
    ax1.set_title("Couverture empirique vs N")
    if (ymin_cov is not None) or (ymax_cov is not None):
        y0 = ymin_cov if ymin_cov is not None else ax1.get_ylim()[0]
        y1 = ymax_cov if ymax_cov is not None else ax1.get_ylim()[1]
        ax1.set_ylim(y0, y1)
    ax1.legend(loc="lower right", frameon=True, fontsize=9)

    # Largeur IC
    for i, s in enumerate(series_list):
        c = colors[i % len(colors)]
        ax2.plot(s.N, s.width_mean, "-", lw=2.0, color=c, label=s.label)
    ax2.set_xlabel("Taille d'échantillon N")
    ax2.set_ylabel("Largeur moyenne de l'IC 95% [rad]")
    ax2.set_title("Largeur moyenne d'IC vs N")
    ax2.legend(loc="upper right", frameon=True, fontsize=9)

    # Sauvegarde (pas de tight_layout)
    fig.savefig(out_png, dpi=dpi)
    print(f"Wrote: {out_png}")


# ---------- main ----------
def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser()
    p.add_argument("--manifests", nargs="+", required=True, help="Liste de manifests JSON à agréger")
    p.add_argument("--labels", nargs="*", default=None, help="Labels (optionnels) pour chaque série")
    p.add_argument("--out", required=True, help="PNG de sortie")
    p.add_argument("--summary-csv", dest="summary_csv", default=None, help="CSV de synthèse")
    p.add_argument("--csv", dest="summary_csv", help="Alias de --summary-csv (CSV de synthèse)")
    p.add_argument("--dpi", type=int, default=300)
    p.add_argument("--ymin-coverage", type=float, default=None)
    p.add_argument("--ymax-coverage", type=float, default=None)
    return p.parse_args()


def main():
    args = parse_args()

    if args.labels and (len(args.labels) != len(args.manifests)):
        # Ajustement souple: tronque ou complète avec noms de fichiers
        labels = list(args.labels)[: len(args.manifests)]
        while len(labels) < len(args.manifests):
            labels.append(os.path.basename(args.manifests[len(labels)]))
    else:
        labels = args.labels or [os.path.basename(m) for m in args.manifests]

    series_list: List[Series] = []
    for path, lab in zip(args.manifests, labels):
        man = load_manifest(path)
        series_list.append(series_from_manifest(man, label_override=lab))

    if args.summary_csv:
        save_summary_csv(series_list, args.summary_csv)
        print(f"[OK] Summary CSV: {args.summary_csv}")

    plot_synthesis(
        series_list,
        out_png=args.out,
        dpi=args.dpi,
        ymin_cov=args.ymin_coverage,
        ymax_cov=args.ymax_coverage,
    )


if __name__ == "__main__":
    main()
PY

echo "[TEST] --help"
python3 "$F" --help >/dev/null

echo "[RUN] génération rapide si manifests présents"
M1="$O/fig03b_cov_A.manifest.json"
M2="$O/fig03b_cov_B.manifest.json"
if [[ -f "$M1" && -f "$M2" ]]; then
  python3 "$F" \
    --manifests "$M1" "$M2" \
    --labels "A(outer300,inner400)" "B(outer300,inner200)" \
    --out "$O/fig07_synthesis.png" \
    --csv "$O/fig07_summary.csv" \
    --dpi 140
fi

echo "[SMOKE] tools/ch10_smoke.sh"
if [[ -x tools/ch10_smoke.sh ]]; then
  bash tools/ch10_smoke.sh
else
  echo "[WARN] tools/ch10_smoke.sh introuvable (mais fig07 est réparé)."
fi

echo "[DONE]"
