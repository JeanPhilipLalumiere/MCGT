#!/usr/bin/env python3
import re, sys
from pathlib import Path

def ind(s): return len(s.expandtabs(4)) - len(s.lstrip(" "))

def normalize(lines):
    i, changed = 0, False
    while i < len(lines):
        m = re.match(r'^(\s*)try:\s*(#.*)?$', lines[i])
        if not m: i += 1; continue
        base = ind(lines[i])
        # Ensure body exists
        j = i + 1
        while j < len(lines) and lines[j].strip() == "": j += 1
        if j >= len(lines) or ind(lines[j]) <= base or re.match(r'^\s*(except\b.*:|finally:)', lines[j] if j < len(lines) else ""):
            lines.insert(i+1, " "*(base+4)+"pass\n"); changed = True
            j = i + 2
        # Find first handler
        h = j
        while h < len(lines) and not re.match(r'^\s*(except\b.*:|finally:)', lines[h]):
            # stop if we dedent to base level (i.e., block ended without handler)
            if ind(lines[h]) < base: break
            h += 1
        # If no handler before dedent → insert minimal one at current position
        if h >= len(lines) or ind(lines[h]) < base:
            lines.insert(h, " "*(base)+"except Exception:\n"); lines.insert(h+1, " "*(base+4)+"pass\n")
            changed = True
            i = h + 2
            continue
        # Align handler to base
        if ind(lines[h]) != base:
            lines[h] = " " * base + lines[h].lstrip(); changed = True
        # Ensure handler has a body
        if h+1 >= len(lines) or ind(lines[h+1]) <= base:
            lines.insert(h+1, " "*(base+4)+"pass\n"); changed = True
        i = h + 2
    return lines, changed

p = Path(sys.argv[1])
L = p.read_text(encoding="utf-8", errors="ignore").splitlines(True)
NL, ch = normalize(L)
if ch:
    p.write_text("".join(NL), encoding="utf-8"); print("[FIX] normalized try/except blocks in", p)
else:
    print("[OK] try/except blocks already sane in", p)
