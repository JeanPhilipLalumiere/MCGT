#!/usr/bin/env python3
import re, sys
from pathlib import Path
p = Path(sys.argv[1])
L = p.read_text(encoding="utf-8", errors="ignore").splitlines(True)

def indent(s): return len(s.expandtabs(4)) - len(s.lstrip(" "))
i = 0; changed = False
while i < len(L):
    m = re.match(r'^(\s*)try:\s*(#.*)?$', L[i])
    if not m: i += 1; continue
    base = indent(L[i]); j = i + 1
    # ensure body (insert pass if immediate next is except/finally or dedent)
    if j >= len(L) or L[j].strip()=="":
        # skip blanks
        k = j
        while k < len(L) and L[k].strip()=="":
            k += 1
        j = k
    need_pass = (j >= len(L) or indent(L[j]) <= base or re.match(r'^\s*(except\b|finally:)', L[j] or ""))
    if need_pass:
        L.insert(i+1, " "*(base+4)+"pass\n"); changed = True
    # find first handler and align it with base
    h = i + 1
    while h < len(L) and not re.match(r'^\s*(except\b.*:|finally:)', L[h]):
        h += 1
    if h < len(L):
        # realign handler to base
        if indent(L[h]) != base:
            L[h] = " " * base + L[h].lstrip()
            changed = True
        # ensure handler has at least a pass
        if h+1 >= len(L) or indent(L[h+1]) <= base:
            L.insert(h+1, " "*(base+4)+"pass\n"); changed = True
    else:
        # no handler, add a minimal one
        L.insert(i+1, " "*(base+4)+"pass\n")
        L.insert(i+2, " "*(base)+"except Exception:\n")
        L.insert(i+3, " "*(base+4)+"pass\n")
        changed = True
    break

if changed:
    p.write_text("".join(L), encoding="utf-8")
    print("[FIX] normalized first try/except in", p)
else:
    print("[OK] try/except looked fine in", p)
