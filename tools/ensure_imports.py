#!/usr/bin/env python3
import sys
from pathlib import Path
def run(p: Path, *modules):
    L = p.read_text(encoding="utf-8", errors="ignore").splitlines(True)
    head = 0
    # find end of initial shebang / __future__ / encoding / comments
    while head < len(L) and (L[head].startswith("#!") or L[head].strip().startswith("from __future__") or L[head].strip().startswith("#") or L[head].strip()==""):
        head += 1
    txt = "".join(L)
    changed = False
    for m in modules:
        if f"import {m}" in txt or f"from {m} import" in txt: continue
        L.insert(head, f"import {m}\n"); head += 1; changed = True
    if changed:
        p.write_text("".join(L), encoding="utf-8")
        print("[FIX] inserted imports", list(modules), "in", p)
    else:
        print("[OK] imports already present in", p)
if __name__ == "__main__":
    args = sys.argv[1:]
    p = Path(args[0]); mods = args[1:]
    run(p, *mods)
