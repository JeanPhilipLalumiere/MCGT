#!/usr/bin/env python3
import sys, re
from pathlib import Path

RX_F = re.compile(r'(^|\s)f([\'\"])')
def balance_line(s: str) -> str:
    # ne traite que les lignes avec f"..." ou f'...'
    if not RX_F.search(s): return s
    # Compte simple { } en ignorant les doubles {{ }}
    open_braces = 0
    i = 0
    while i < len(s):
        if s[i] == '{':
            if i+1 < len(s) and s[i+1] == '{':
                i += 2; continue
            open_braces += 1
        elif s[i] == '}':
            if i+1 < len(s) and s[i+1] == '}':
                i += 2; continue
            open_braces -= 1
        i += 1
    if open_braces > 0:
        # injecter les '}' manquants juste avant la fin de ligne
        return s.rstrip("\n") + ("}" * open_braces) + ("\n" if s.endswith("\n") else "")
    return s

def process(p: Path) -> bool:
    L = p.read_text(encoding="utf-8", errors="ignore").splitlines(True)
    new = [balance_line(s) for s in L]
    if new != L:
        p.write_text("".join(new), encoding="utf-8")
        print("[FIX] balanced f-strings in", p)
        return True
    print("[OK] f-strings balanced already in", p)
    return False

if __name__ == "__main__":
    for arg in sys.argv[1:]: process(Path(arg))
