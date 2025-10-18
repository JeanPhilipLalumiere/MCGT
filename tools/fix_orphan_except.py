#!/usr/bin/env python3
import re, sys
from pathlib import Path

HDR_TRY = re.compile(r'^\s*try:\s*(#.*)?$')
HDR_EXC = re.compile(r'^\s*(except\b.*:|finally:)\s*(#.*)?$')

def indent(s: str) -> int:
    return len(s.expandtabs(4)) - len(s.lstrip(" "))

def process(p: Path) -> bool:
    lines = p.read_text(encoding="utf-8", errors="ignore").splitlines(True)
    changed = False
    i = 0
    while i < len(lines):
        s = lines[i]
        if HDR_EXC.match(s):
            base = indent(s)
            # chercher un "try:" aligné plus haut
            j = i - 1
            found_try = False
            while j >= 0:
                if lines[j].strip() == "":
                    j -= 1; continue
                indj = indent(lines[j])
                if indj < base:
                    break
                if indj == base and HDR_TRY.match(lines[j]):
                    found_try = True
                    break
                j -= 1
            if not found_try:
                # commenter l'except/finally + son bloc
                lines[i] = (" " * base) + "# [AUTO] orphan except/finally removed\n"
                i += 1
                while i < len(lines) and (lines[i].strip()=="" or indent(lines[i]) > base):
                    if lines[i].strip():
                        lines[i] = "# [AUTO] " + lines[i]
                    i += 1
                changed = True
                continue
        i += 1
    if changed:
        p.write_text("".join(lines), encoding="utf-8")
    return changed

if __name__ == "__main__":
    for arg in sys.argv[1:]:
        p = Path(arg)
        print(("[FIX]" if process(p) else "[OK]"), p)
