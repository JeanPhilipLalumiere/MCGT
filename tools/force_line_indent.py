#!/usr/bin/env python3
import re, sys
from pathlib import Path
def set_line_indent(p: Path, pattern: str, indent: int, occurrence: int = 1) -> bool:
    rx = re.compile(pattern)
    L = p.read_text(encoding="utf-8", errors="ignore").splitlines(True)
    n = 0
    for i, s in enumerate(L):
        if rx.search(s):
            n += 1
            if n == occurrence:
                L[i] = (" " * indent) + s.lstrip()
                p.write_text("".join(L), encoding="utf-8")
                print(f"[FIX] {p}:{i+1} -> indent {indent}")
                return True
    print(f"[WARN] pattern not found in {p}")
    return False
if __name__ == "__main__":
    p = Path(sys.argv[1]); pat = sys.argv[2]; indent = int(sys.argv[3])
    set_line_indent(p, pat, indent)
