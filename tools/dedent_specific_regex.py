#!/usr/bin/env python3
import re, sys
from pathlib import Path
def process(p: Path, pat: str) -> bool:
    rx = re.compile(pat)
    L = p.read_text(encoding="utf-8", errors="ignore").splitlines(True)
    changed = False
    for i,s in enumerate(L):
        if rx.match(s.lstrip()) and s[:1].isspace():
            ns = s.lstrip(" \t")
            if ns != s: L[i] = ns; changed = True
    if changed: p.write_text("".join(L), encoding="utf-8")
    print(("[FIX]" if changed else "[OK]"), p, "::", pat)
    return changed
if __name__ == "__main__":
    p = Path(sys.argv[1]); pat = sys.argv[2]
    process(p, pat)
