#!/usr/bin/env python3
import sys, re
from pathlib import Path

IF_FALSE = re.compile(r'^([ ]*)if\s+False\s*:\s*$')  # espaces uniquement

def fix(path: Path) -> bool:
    lines = path.read_text(encoding="utf-8").splitlines(True)
    changed = False
    i = 0
    while i < len(lines):
        m = IF_FALSE.match(lines[i])
        if not m:
            i += 1
            continue
        base = m.group(1)
        want = base + " " * 4   # indentation cible du bloc
        i += 1
        while i < len(lines):
            s = lines[i]
            if s.strip() == "":
                i += 1
                continue
            # fin de bloc si on est revenu à une indent <= base
            actual = len(s) - len(s.lstrip(" "))
            if actual <= len(base):
                break
            body = s.lstrip(" ")
            if not s.startswith(want):
                lines[i] = want + body
                changed = True
            i += 1
    if changed:
        bak = path.with_suffix(path.suffix + ".bak_ifblock")
        if not bak.exists():
            bak.write_text("".join(lines), encoding="utf-8")
        path.write_text("".join(lines), encoding="utf-8")
    return changed

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("usage: fix_block_indentation_after_if_false.py FILE [FILE...]", file=sys.stderr); sys.exit(2)
    for a in sys.argv[1:]:
        p = Path(a)
        if not p.exists():
            print(f"[SKIP] not found: {p}"); continue
        ch = fix(p)
        print(f"[{'FIX' if ch else 'OK '}] {p}")
