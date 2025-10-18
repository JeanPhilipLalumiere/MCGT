#!/usr/bin/env python3
from pathlib import Path
import re

p = Path("zz-scripts/chapter10/plot_fig07_synthesis.py")
src = p.read_text(encoding="utf-8")

# Fix any variant like "table = try:" or "foo =     try:" on its own line
fixed = re.sub(r'^([ \t]*)[A-Za-z_][A-Za-z0-9_]*\s*=\s*try:\s*$',
               r'\1try:', src, flags=re.M)

if fixed != src:
    p.write_text(fixed, encoding="utf-8")
    print("[OK] cleaned stray '<name> = try:' line(s)")
else:
    print("[SKIP] nothing to clean")
