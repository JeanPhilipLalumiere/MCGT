#!/usr/bin/env python3
import re, sys
from pathlib import Path
RX_TRY   = re.compile(r'^\s*try:\s*(#.*)?$')
RX_HDR   = re.compile(r'^\s*(try:|except\b.*:|finally:)\s*(#.*)?$')
RX_EXC   = re.compile(r'^\s*(except\b.*:|finally:)\s*(#.*)?$')
def ind(s): return len(s.expandtabs(4)) - len(s.lstrip(" "))
def process(p: Path) -> bool:
    L = p.read_text(encoding="utf-8", errors="ignore").splitlines(True)
    changed = False
    i = 0
    while i < len(L):
        s = L[i]
        if RX_EXC.match(s):
            base = ind(s)
            # dernière ligne non vide avec indent <= base avant i
            j = i - 1
            while j >= 0 and L[j].strip()=="":
                j -= 1
            if j < 0 or ind(L[j]) < base or not RX_HDR.match(L[j]) or not RX_TRY.match(L[j]):
                # orphelin -> commenter le header + son bloc
                L[i] = (" " * base) + "# [AUTO] orphan except/finally removed\n"
                i += 1
                while i < len(L) and (L[i].strip()=="" or ind(L[i]) > base):
                    if L[i].strip():
                        L[i] = "# [AUTO] " + L[i]
                    i += 1
                changed = True
                continue
        i += 1
    if changed: p.write_text("".join(L), encoding="utf-8")
    return changed
if __name__ == "__main__":
    for arg in sys.argv[1:]:
        print(("[FIX]" if process(Path(arg)) else "[OK]"), arg)
