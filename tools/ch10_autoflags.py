#!/usr/bin/env python3
"""
tools/ch10_autoflags.py
- Lit un CSV chap.10 (p.ex. 10_mc_results.circ.with_fpeak.csv)
- Détecte des colonnes plausibles par regex
- Produit:
  * zz-manifests/ch10_autoflags.json (pour inspection)
  * zz-manifests/ch10_autoflags.env   (export VARs shell prêtes à sourcer)
"""

from __future__ import annotations
import argparse, json, re, sys
from pathlib import Path

try:
    import pandas as pd
except Exception as e:
    print(f"[ERR] pandas requis: {e}", file=sys.stderr)
    sys.exit(2)

ROOT = Path(__file__).resolve().parents[1]
MANI = ROOT / "zz-manifests"
MANI.mkdir(parents=True, exist_ok=True)

def pick_one(names, patterns):
    for pat in patterns:
        rgx = re.compile(pat, re.I)
        for n in names:
            if rgx.search(n):
                return n
    return None

def sanitize(s: str) -> str:
    # Valeur sûre pour shell: on entoure de quotes simples, on échappe les simples éventuels
    return "'" + s.replace("'", "'\"'\"'") + "'"

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--results", required=True, help="Chemin du CSV chap.10")
    args = ap.parse_args()

    csv = Path(args.results)
    if not csv.is_file():
        print(f"[ERR] CSV introuvable: {csv}", file=sys.stderr)
        sys.exit(1)

    # charge quelques lignes pour colonnes
    try:
        df = pd.read_csv(csv, nrows=100)
    except Exception as e:
        print(f"[ERR] Lecture CSV: {e}", file=sys.stderr)
        sys.exit(1)

    cols = list(df.columns)
    names = [str(c) for c in cols]

    # Heuristiques
    x_fpeak = pick_one(names, [
        r"\bf_?peak\b", r"\bfreq.*peak", r"\bf_max\b", r"\bf\b"
    ])
    y_phi_at_fpeak = pick_one(names, [
        r"\bphi.*fpeak\b", r"\bphi_at_fpeak\b", r"\bphi.*peak\b", r"\bphi\b"
    ])
    sigma_phi = pick_one(names, [
        r"sigma.*phi", r"phi.*sigma", r"std.*phi", r"phi.*std", r"err.*phi", r"phi.*err"
    ])
    group_col = pick_one(names, [
        r"\b(group|subset|batch|tag|label|cluster|split)\b"
    ])
    p95_col = pick_one(names, [
        r"\bp95\b", r"p_?95", r"\bphi95\b", r"ci.?95", r"coverage.?95"
    ])
    n_col = pick_one(names, [
        r"(^n$|_n$|num(_)?samples|samples|count|size)"
    ])
    # Paires pour "recalc vs orig"
    p95_orig = pick_one(names, [r"(orig|original).*(p)?95", r"p95.*(orig|original)"])
    p95_recalc = pick_one(names, [r"(recalc|recomputed|circ|circular).*(p)?95", r"p95.*(recalc|recomputed|circ|circular)"])

    # "residual_map" -> deux colonnes quantitatives comparables (phi1, phi2 / m1,m2)
    phi_cols = [c for c in names if re.search(r"\bphi", c, re.I)]
    m1_col = phi_cols[0] if phi_cols else pick_one(names, [r"\bm1\b", r"\bmetric.?1\b"])
    m2_col = phi_cols[1] if len(phi_cols) > 1 else pick_one(names, [r"\bm2\b", r"\bmetric.?2\b"])

    # Assemble flags par script (on ne met QUE ce qu’on a trouvé)
    flags = {}

    # fig02_scatter_phi_at_fpeak
    f02 = []
    if x_fpeak: f02 += ["--x-col", x_fpeak]
    if y_phi_at_fpeak: f02 += ["--y-col", y_phi_at_fpeak]
    if sigma_phi: f02 += ["--sigma-col", sigma_phi]
    if group_col: f02 += ["--group-col", group_col]
    flags["plot_fig02_scatter_phi_at_fpeak.py"] = f02

    # fig03_convergence_p95_vs_n
    f03 = []
    if n_col: f03 += ["--n-col", n_col]
    if p95_col: f03 += ["--p95-col", p95_col]
    flags["plot_fig03_convergence_p95_vs_n.py"] = f03

    # fig03b_bootstrap_coverage_vs_n (si besoin des mêmes colonnes)
    f03b = []
    if n_col: f03b += ["--n-col", n_col]
    if p95_col: f03b += ["--p95-col", p95_col]
    flags["plot_fig03b_bootstrap_coverage_vs_n.py"] = f03b

    # fig04_scatter_p95_recalc_vs_orig
    f04 = []
    if p95_orig: f04 += ["--orig-col", p95_orig]
    if p95_recalc: f04 += ["--recalc-col", p95_recalc]
    flags["plot_fig04_scatter_p95_recalc_vs_orig.py"] = f04

    # fig05_hist_cdf_metrics
    f05 = []
    if p95_col: f05 += ["--p95-col", p95_col]
    flags["plot_fig05_hist_cdf_metrics.py"] = f05

    # fig06_residual_map
    f06 = []
    if m1_col: f06 += ["--m1-col", m1_col]
    if m2_col: f06 += ["--m2-col", m2_col]
    flags["plot_fig06_residual_map.py"] = f06

    out_json = MANI / "ch10_autoflags.json"
    out_env  = MANI / "ch10_autoflags.env"

    # Sauvegarde JSON lisible
    out_json.write_text(json.dumps({
        "csv": str(csv),
        "columns": names,
        "flags": flags
    }, indent=2), encoding="utf-8")

    # Sauvegarde ENV (variables shell)
    lines = []
    for script, arr in flags.items():
        base = Path(script).name.replace(".py", "")
        var = f"ARGS_{re.sub('[^A-Za-z0-9_]', '_', base)}"
        parts = []
        # On quote chaque valeur
        for x in arr:
            parts.append(x if x.startswith("--") else sanitize(x))
        lines.append(f'{var}="' + " ".join(parts) + '"')
    out_env.write_text("\n".join(lines) + "\n", encoding="utf-8")

    print(f"[OK] flags → {out_json}")
    print(f"[OK] env   → {out_env}")
    print("[HINT] Inspecte le JSON, ou 'source zz-manifests/ch10_autoflags.env' pour voir les ARGS_*.")

if __name__ == "__main__":
    main()
