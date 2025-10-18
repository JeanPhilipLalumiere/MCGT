#!/usr/bin/env python3
import re, sys
from pathlib import Path
def ind(s): return len(s.expandtabs(4)) - len(s.lstrip(" "))
def process(p: Path, pattern=r'^\s*elif\s+args\.verbose\s*==\s*1\s*:') -> bool:
    rx = re.compile(pattern)
    L = p.read_text(encoding="utf-8", errors="ignore").splitlines(True)
    changed = False
    for i,s in enumerate(L):
        if rx.match(s):
            base = ind(s)
            j = i-1
            while j>=0 and L[j].strip()=="":
                j -= 1
            ok = (j>=0 and ind(L[j])==base and L[j].lstrip().startswith("if "))
            if not ok:
                L[i] = re.sub(r'^\s*elif', " " * base + "if", s)
                changed = True
    if changed:
        p.write_text("".join(L), encoding="utf-8")
        print("[FIX] demoted lonely elif -> if in", p)
    else:
        print("[OK] no lonely elif to demote in", p)
    return changed
if __name__ == "__main__":
    for a in sys.argv[1:]: process(Path(a))
