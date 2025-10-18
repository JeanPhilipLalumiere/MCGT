#!/usr/bin/env python3
import sys
from pathlib import Path

def indent(s): return len(s.expandtabs(4)) - len(s.lstrip(" "))

def fix(p: Path, needle: str) -> bool:
    lines = p.read_text(encoding="utf-8", errors="ignore").splitlines(True)
    for i, s in enumerate(lines):
        if s.lstrip().startswith(needle):
            j = i - 1
            while j >= 0 and lines[j].strip() == "":
                j -= 1
            base = 0 if j < 0 else indent(lines[j])
            fixed = (" " * base) + s.lstrip()
            if fixed != s:
                lines[i] = fixed
                p.write_text("".join(lines), encoding="utf-8")
                return True
            return False
    return False

if __name__ == "__main__":
    p = Path(sys.argv[1]); needle = sys.argv[2]
    print(("[FIX]" if fix(p, needle) else "[OK]"), p, "::", needle)
