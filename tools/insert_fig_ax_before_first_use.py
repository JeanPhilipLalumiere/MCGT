#!/usr/bin/env python3
import re, sys
from pathlib import Path

RX_USE = re.compile(r'\b(ax|fig)\s*\.')
RX_PLT_USE = re.compile(r'\bplt\s*\.')
RX_HAS_PLT = re.compile(r'^\s*(?:from\s+matplotlib\s+import\s+pyplot\s+as\s+plt|import\s+matplotlib\.pyplot\s+as\s+plt)\b')

def first_nonblank_before(L, i):
    j = i - 1
    while j >= 0 and L[j].strip() == "": j -= 1
    return j

def process(p: Path) -> bool:
    L = p.read_text(encoding="utf-8", errors="ignore").splitlines(True)
    # find the first use of fig./ax. or plt.
    first_use = None
    for i, s in enumerate(L):
        if RX_USE.search(s) or RX_PLT_USE.search(s):
            first_use = i; break
    if first_use is None:
        print("[OK] no fig/ax/plt usage in", p); return False

    # ensure a plt import exists ABOVE first_use; if not, insert one immediately before
    has_plt_above = any(RX_HAS_PLT.search(s) for s in L[:first_use])
    changed = False
    ins = first_use
    if not has_plt_above:
        L.insert(ins, "import matplotlib.pyplot as plt\n"); ins += 1; changed = True

    # ensure "fig, ax = plt.subplots()" exists ABOVE first ax./fig. use; if not, insert right here
    has_figax_above = any(re.search(r'\b(fig\s*,\s*ax|ax|fig)\s*=\s*plt\.subplots\(', s) for s in L[:ins])
    if not has_figax_above:
        L.insert(ins, "fig, ax = plt.subplots()\n"); ins += 1; changed = True

    if changed:
        p.write_text("".join(L), encoding="utf-8")
        print(f"[FIX] ensured plt import and fig,ax before first use in {p}")
    else:
        print("[OK] plt/fig/ax already defined above first use in", p)
    return changed

if __name__ == "__main__":
    for a in sys.argv[1:]: process(Path(a))
