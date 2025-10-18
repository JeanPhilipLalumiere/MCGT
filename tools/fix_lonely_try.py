#!/usr/bin/env python3
import argparse, re
from pathlib import Path

def indent(s): return len(s.expandtabs(4)) - len(s.lstrip(" "))

def patch_file(p: Path) -> int:
    lines = p.read_text(encoding="utf-8", errors="ignore").splitlines(True)
    i = 0; changes = 0
    while i < len(lines):
        s = lines[i]
        if s.rstrip().endswith("try:"):
            base = indent(s)
            # chercher la première ligne <= base (fin logique du bloc)
            j = i + 1
            while j < len(lines):
                if lines[j].strip()=="":
                    j += 1; continue
                if indent(lines[j]) <= base:
                    break
                j += 1
            # vérifier s'il y a un except/finally entre i et j
            has_handler = False
            for k in range(i+1, j):
                if re.match(rf"^\s*(except\b|finally:)", lines[k]):
                    has_handler = True; break
            if not has_handler:
                # insérer un except minimal au point j
                lines.insert(j, " " * base + "except Exception:\n")
                lines.insert(j+1, " " * (base + 4) + "pass\n")
                changes += 2
                i = j + 2
                continue
        i += 1
    if changes:
        p.write_text("".join(lines), encoding="utf-8")
    return changes

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("paths", nargs="+")
    args = ap.parse_args()
    total = 0
    for path in args.paths:
        total += patch_file(Path(path))
    print(f"[OK] inserted handlers: {total}")

if __name__ == "__main__":
    main()
