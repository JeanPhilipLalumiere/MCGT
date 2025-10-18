#!/usr/bin/env python3
import re, sys
from pathlib import Path
PAT = re.compile(r'^\s*(ax\.|plt\.|fig\.)')
def process(p: Path) -> bool:
    L = p.read_text(encoding="utf-8", errors="ignore").splitlines(True)
    ch = False
    for i,s in enumerate(L):
        if PAT.match(s) and s[0].isspace():
            ns = s.lstrip(" \t")
            if ns != s: L[i] = ns; ch = True
    if ch: p.write_text("".join(L), encoding="utf-8")
    print(("[FIX]" if ch else "[OK]"), p)
    return ch
if __name__ == "__main__":
    for arg in sys.argv[1:]: process(Path(arg))
