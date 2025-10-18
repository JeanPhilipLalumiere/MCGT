#!/usr/bin/env python3
import json, csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
AUD  = ROOT / "zz-manifests/audit_sweep.json"
OUT  = ROOT / "zz-manifests/args_matrix.csv"

def main():
    rep = json.loads(AUD.read_text(encoding="utf-8"))
    files = rep.get("files", [])

    # recense tous les noms d'arguments vus dans le repo
    all_names = set()
    for f in files:
        for a in f.get("args_used") or []:
            all_names.add(a)
        for a in f.get("args_defined") or []:
            all_names.add(a)
    cols = ["file"] + sorted(all_names)

    with OUT.open("w", encoding="utf-8", newline="") as fo:
        wr = csv.writer(fo)
        wr.writerow(cols)
        for f in files:
            row = [f["path"]]
            used = set(f.get("args_used") or [])
            defi = set(f.get("args_defined") or [])
            for name in cols[1:]:
                if name in used and name in defi: cell = "OK"
                elif name in used and name not in defi: cell = "MISSING"
                elif name not in used and name in defi: cell = "DEF_ONLY"
                else: cell = ""
                row.append(cell)
            wr.writerow(row)
    print(f"[OK] wrote {OUT}")

if __name__ == "__main__":
    main()
