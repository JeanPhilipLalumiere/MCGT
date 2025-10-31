#!/usr/bin/env python3
# MCGT — ch10 official generator (restored, CSV schema aligned to tests)
# Headers required by tests: sample_id,q,m1,m2,fpeak_hz,phi_at_fpeak_rad,p95_rad

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

    # Defaults sensible; override via config if needed
    m1 = float(cfg.get("m1", 1.40))          # ex: masses (unités internes projet)
    m2 = float(cfg.get("m2", 1.30))
    q  = float(cfg.get("q",  m1/m2 if m2 else 1.0))
    f0 = float(cfg.get("base_fpeak_hz", 150.0))
    phi0 = float(cfg.get("phi0_rad", 0.0))
    p95 = float(cfg.get("p95_rad", 3.0))

    rows: List[Dict[str, Any]] = []
    for i in range(n):
        # Variation simple mais déterministe autour des defaults
        t = i / max(1, n-1)
        fpeak = f0 * (1.0 + 0.05*math.sin(2*math.pi*t))
        phi_at_fpeak = phi0 + 0.1*math.cos(2*math.pi*t)

        rows.append({
            "sample_id": i,
            "q": round(q, 6),
            "m1": round(m1, 6),
            "m2": round(m2, 6),
            "fpeak_hz": round(fpeak, 6),
            "phi_at_fpeak_rad": round(phi_at_fpeak, 6),
            "p95_rad": round(p95, 6),
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
# === MCGT:CLI-SHIM-BEGIN ===
# Idempotent. Expose: --out/--dpi/--format/--transparent/--style/--verbose
# Ne modifie pas la logique existante : parse_known_args() au module-scope.
def _mcgt_cli_shim_parse_known():
    import argparse, sys
    p = argparse.ArgumentParser(add_help=False)
    p.add_argument("--out", type=str, default=None)
    p.add_argument("--dpi", type=int, default=None)
    p.add_argument("--format", type=str, default=None, choices=["png","pdf","svg"])
    p.add_argument("--transparent", action="store_true")
    p.add_argument("--style", type=str, default=None)
    p.add_argument("--verbose", action="store_true")
    args, _ = p.parse_known_args(sys.argv[1:])
    try:
        import matplotlib as _mpl
        if args.style:
            _mpl.style.use(args.style)
        if args.dpi and hasattr(_mpl, "rcParams"):
            _mpl.rcParams["figure.dpi"] = int(args.dpi)
    except Exception:
        # Jamais bloquant.
        pass
    return args

# Exposition module-scope (ne force rien si l'appelant n'utilise pas MCGT_CLI)
try:
    MCGT_CLI = _mcgt_cli_shim_parse_known()
except Exception:
    MCGT_CLI = None
# === MCGT:CLI-SHIM-END ===
