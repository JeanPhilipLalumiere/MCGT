#!/usr/bin/env python3
import sys, re
from pathlib import Path

def unindent_rcparams(p: Path) -> bool:
    lines = p.read_text(encoding="utf-8", errors="ignore").splitlines(True)
    changed = False
    for i,s in enumerate(lines):
        if re.match(r"^\s*mpl\.rcParams\[[\"']", s):
            ns = s.lstrip(" \t")
            if ns != s:
                lines[i] = ns
                changed = True
        if re.match(r"^\s*import\s+matplotlib\s+as\s+mpl\b", s):
            ns = s.lstrip(" \t")
            if ns != s:
                lines[i] = ns
                changed = True
    if changed:
        p.write_text("".join(lines), encoding="utf-8")
    return changed

if __name__ == "__main__":
    for arg in sys.argv[1:]:
        p = Path(arg)
        if unindent_rcparams(p):
            print("[FIX] rcParams/import dedented in", p)
        else:
            print("[OK] no rcParams indent issue in", p)
