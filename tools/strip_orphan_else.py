#!/usr/bin/env python3
import re, sys
from pathlib import Path

ALLOWED_HDR = re.compile(r'^\s*(if|elif|else:|for|while|try:|except\b.*:|finally:|with|def|class)\b.*:\s*(#.*)?$')

def indent(s): return len(s.expandtabs(4)) - len(s.lstrip(" "))

def process(p: Path) -> bool:
    lines = p.read_text(encoding="utf-8", errors="ignore").splitlines(True)
    changed = False
    for i, s in enumerate(lines):
        if s.lstrip().startswith("else:"):
            ind = indent(s)
            j = i - 1
            while j >= 0 and lines[j].strip() == "":
                j -= 1
            ok = j >= 0 and indent(lines[j]) == ind and ALLOWED_HDR.match(lines[j])
            if not ok:
                lines[i] = (" " * ind) + "# [AUTO] orphan else removed\n"
                changed = True
    if changed:
        p.write_text("".join(lines), encoding="utf-8")
    return changed

if __name__ == "__main__":
    for arg in sys.argv[1:]:
        p = Path(arg)
        print(("[FIX]" if process(p) else "[OK]"), p)
