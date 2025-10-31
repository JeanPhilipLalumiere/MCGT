from __future__ import annotations
import sys
from pathlib import Path

violations = []
for p in Path(".").rglob("run_*_safe.py"):
    # autorisé uniquement sous attic/
    parts = p.as_posix().split("/")
    if "attic" not in parts:
        violations.append(p.as_posix())

if violations:
    print("Safe runners non autorisés hors 'attic/' :", file=sys.stderr)
    for v in violations:
        print(f" - {v}", file=sys.stderr)
    sys.exit(1)

print("[PASS] Aucun runner *_safe.py hors 'attic/'.")
