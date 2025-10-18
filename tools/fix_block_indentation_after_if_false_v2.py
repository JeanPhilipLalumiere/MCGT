#!/usr/bin/env python3
import sys, re
from pathlib import Path

IF_FALSE = re.compile(r'^([ ]*)if\s+False\s*:\s*$')  # espaces uniquement

def fix_one(path: Path) -> bool:
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
        # Normalise toutes les lignes non vides tant que leur indent > base
        while i < len(lines):
            s = lines[i]
            # fin de fichier
            if s is None:
                break
            # blanks -> conserver
            if s.strip() == "":
                i += 1
                continue
            # calcul indent actuel (espaces)
            actual = len(s) - len(s.lstrip(" "))
            if actual <= len(base):
                # on est sorti du bloc
                break
            # réécrit la ligne avec l'indent attendu
            body = s.lstrip(" ")
            if not s.startswith(want):
                lines[i] = want + body
                changed = True
            i += 1
    if changed:
        bak = path.with_suffix(path.suffix + ".bak_ifblock2")
        if not bak.exists():
            bak.write_text("".join(lines), encoding="utf-8")
        path.write_text("".join(lines), encoding="utf-8")
    return changed

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("usage: fix_block_indentation_after_if_false_v2.py FILE [FILE...]", file=sys.stderr)
        sys.exit(2)
    for a in sys.argv[1:]:
        p = Path(a)
        if not p.exists():
            print(f"[SKIP] not found: {p}")
            continue
        ch = fix_one(p)
        print(f"[{'FIX' if ch else 'OK '}] {p}")
