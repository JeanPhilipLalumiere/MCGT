#!/usr/bin/env python3
# MCGT — ch10 official generator (restored, CSV schema aligned to tests)
# Headers required by tests: sample_id,q,m1,m2,fpeak_hz,phi_at_fpeak_rad,p95_rad
# NOTE:
# This script is a lightweight toy generator used for the *chapter 10 minimal
# pipeline* and for CI/smoke tests. It does NOT run the full 8D Sobol Monte Carlo
# pipeline (generer_donnees_chapitre10.py + 10_mc_results.*).
# It only produces synthetic but structured values (fpeak_hz, phi_at_fpeak_rad,
# p95_rad) so that the plotting scripts 10_fig_01…10_fig_07 can be exercised
# quickly and deterministically.

import argparse, csv, json, os, sys, math, random
from typing import Any, Dict, Iterable, List

def parse_args():
    p = argparse.ArgumentParser(description="MCGT ch10 official generator (aligned headers)")
    p.add_argument("--config", required=False, default="zz-data/chapter10/10_mc_config.json",
                   help="Config JSON (optional)")
    p.add_argument("--out-results", required=True, help="Output CSV path")
    return p.parse_args()

def load_config(path: str) -> Dict[str, Any]:
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return {}

def compute_rows(cfg: Dict[str, Any]) -> List[Dict[str, Any]]:
    n = int(cfg.get("n_samples", 50))
    seed = int(cfg.get("seed", 42))
    random.seed(seed)

    # Defaults; override via config if needed
    m1 = float(cfg.get("m1", 1.40))          # ex: masses (unités internes projet)
    m2 = float(cfg.get("m2", 1.30))
    q  = float(cfg.get("q",  m1/m2 if m2 else 1.0))
    f0 = float(cfg.get("base_fpeak_hz", 150.0))
    phi0 = float(cfg.get("phi0_rad", 0.0))

    # Valeur moyenne de référence pour p95, mais la valeur sera modulée point par point
    p95_base = float(cfg.get("p95_rad", 3.0))

    rows: List[Dict[str, Any]] = []
    for i in range(n):
        # Paramètre réduit dans [0,1] pour structurer les variations
        t = i / max(1, n - 1)

        # Variation douce de f_peak et phi_at_fpeak (comme avant)
        fpeak = f0 * (1.0 + 0.05 * math.sin(2 * math.pi * t))
        phi_at_fpeak = phi0 + 0.1 * math.cos(2 * math.pi * t)

        # --- Nouvelle logique : p95_rad variable, pas une constante ---
        # Composante structurée (sinus / cosinus) + petit bruit aléatoire gaussien
        rel = 0.25 * math.sin(2 * math.pi * t) + 0.15 * math.cos(4 * math.pi * t)
        jitter = random.gauss(0.0, 0.05)

        p95_i = p95_base * (1.0 + rel) + jitter

        # On évite les valeurs trop petites ou négatives
        p95_i = max(0.05, p95_i)

        rows.append({
            "sample_id": i,
            "q": round(q, 6),
            "m1": round(m1, 6),
            "m2": round(m2, 6),
            "fpeak_hz": round(fpeak, 6),
            "phi_at_fpeak_rad": round(phi_at_fpeak, 6),
            "p95_rad": round(p95_i, 6),
        })
    return rows

def write_csv(path: str, rows: Iterable[Dict[str, Any]]) -> None:
    rows = list(rows)
    fieldnames = ["sample_id","q","m1","m2","fpeak_hz","phi_at_fpeak_rad","p95_rad"]
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    with open(path, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fieldnames)
        w.writeheader()
        w.writerows(rows)

def main() -> int:
    args = parse_args()
    cfg = load_config(args.config)
    rows = compute_rows(cfg)
    write_csv(args.out_results, rows)
    print(f"[ch10-official] wrote {args.out_results} ({len(rows)} rows)")
    return 0

if __name__ == "__main__":
    sys.exit(main())
