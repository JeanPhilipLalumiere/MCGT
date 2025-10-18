#!/usr/bin/env python3
import json
from pathlib import Path

REPORT = Path("zz-manifests/indent_failures.json")

def show_snippet(p: Path, lineno: int, radius=6):
    lines = p.read_text(encoding="utf-8", errors="ignore").splitlines()
    a = max(1, lineno - radius)
    b = min(len(lines), lineno + radius)
    for i in range(a, b + 1):
        prefix = ">>" if i == lineno else "  "
        print(f"{prefix} {i:5d}: {lines[i-1]}")

def main():
    data = json.loads(REPORT.read_text(encoding="utf-8"))
    for r in data:
        p = Path(r["path"])
        print(f"\n=== {p} (lineno={r['lineno']}, msg={r['msg']}) ===")
        try:
            show_snippet(p, r["lineno"])
        except Exception as e:
            print("[WARN] snippet failed:", e)

if __name__ == "__main__":
    main()
