#!/usr/bin/env python3
import re, sys
from pathlib import Path

HDR_OK = re.compile(r'^\s*(if|elif|for|while|try|except|finally|with)\b.*:\s*(#.*)?$')

def ind(s): return len(s.expandtabs(4)) - len(s.lstrip(" "))

def process(p: Path) -> bool:
    L = p.read_text(encoding="utf-8", errors="ignore").splitlines(True)
    changed = False
    for i,s in enumerate(L):
        if s.lstrip().startswith("else:"):
            base = ind(s)
            j = i - 1
            while j >= 0 and L[j].strip() == "":
                j -= 1
            ok = j >= 0 and ind(L[j]) == base and HDR_OK.match(L[j])
            if not ok:
                L[i] = (" " * base) + "if True:\n"
                changed = True
    if changed:
        p.write_text("".join(L), encoding="utf-8")
        print("[FIX] demoted orphan else->if True in", p)
    else:
        print("[OK] no orphan else in", p)
    return changed

if __name__ == "__main__":
    for a in sys.argv[1:]: process(Path(a))
