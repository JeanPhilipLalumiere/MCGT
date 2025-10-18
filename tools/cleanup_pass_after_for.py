#!/usr/bin/env python3
import re, argparse
from pathlib import Path

def indent(s): return len(s.expandtabs(4)) - len(s.lstrip(" "))

def process(p: Path) -> bool:
    lines = p.read_text(encoding="utf-8", errors="ignore").splitlines(True)
    changed = False
    i = 0
    while i < len(lines)-1:
        s = lines[i]
        if re.search(r":\s*(#.*)?\s*$", s) and s.lstrip().startswith(("for ", "while ", "if ", "elif ", "else:", "try:", "except", "finally:")):
            base = indent(s)
            j = i + 1
            # sauter lignes vides
            while j < len(lines) and lines[j].strip() == "":
                j += 1
            if j < len(lines) and lines[j].strip() == "pass" and indent(lines[j]) == base + 4:
                # s'il existe ensuite une autre ligne au même niveau base+4 -> on supprime ce pass
                k = j + 1
                while k < len(lines) and lines[k].strip() == "":
                    k += 1
                if k < len(lines) and indent(lines[k]) == base + 4:
                    del lines[j]
                    changed = True
                    continue
        i += 1
    if changed:
        p.write_text("".join(lines), encoding="utf-8")
    return changed

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("file", nargs="+")
    args = ap.parse_args()
    for f in args.file:
        p = Path(f)
        if process(p):
            print("[FIX] removed placeholder pass in", p)
        else:
            print("[OK] no placeholder pass in", p)

if __name__ == "__main__":
    main()
