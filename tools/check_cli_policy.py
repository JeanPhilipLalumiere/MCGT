from __future__ import annotations
import csv, sys
from pathlib import Path

CSV = Path("zz-manifests/TODO_round3_cli.csv")
REQUIRED = ["has_out","has_dpi","has_format","has_transparent","has_style","has_verbose"]

if not CSV.exists():
    print(f"[ERROR] Manquant: {CSV}", file=sys.stderr)
    sys.exit(2)

bad = []
with CSV.open(newline="", encoding="utf-8") as f:
    r = csv.DictReader(f)
    for row in r:
        misses = [k for k in REQUIRED if row.get(k,"0") != "1"]
        if misses:
            bad.append((row["path"], misses))

if bad:
    print("CLI policy violations:", file=sys.stderr)
    for p, miss in bad:
        print(f" - {p}: manque {', '.join(miss)}", file=sys.stderr)
    sys.exit(1)

print("[PASS] CLI policy: tous les producteurs ont les flags communs requis.")
