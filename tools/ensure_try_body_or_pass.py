#!/usr/bin/env python3
import re, sys
from pathlib import Path

HDR_TRY = re.compile(r'^(\s*)try:\s*(#.*)?$')

def indent(s): return len(s.expandtabs(4)) - len(s.lstrip(" "))

def process(p: Path) -> bool:
    L = p.read_text(encoding="utf-8", errors="ignore").splitlines(True)
    changed = False
    i = 0
    while i < len(L):
        m = HDR_TRY.match(L[i])
        if not m: i += 1; continue
        base = len(m.group(1).expandtabs(4))
        j = i + 1
        # skip blanks/comments
        while j < len(L) and (L[j].strip() == "" or L[j].lstrip().startswith("#")):
            j += 1
        if j >= len(L) or indent(L[j]) <= base or re.match(r'^\s*(except\b|finally:)', L[j]):
            L.insert(i+1, " " * (base + 4) + "pass\n")
            changed = True
            i += 1
        i += 1
    if changed:
        p.write_text("".join(L), encoding="utf-8")
        print("[FIX] inserted pass after empty try in", p)
    else:
        print("[OK] all try blocks have bodies in", p)
    return changed

if __name__ == "__main__":
    for a in sys.argv[1:]: process(Path(a))
