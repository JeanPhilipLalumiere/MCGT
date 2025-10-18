#!/usr/bin/env python3
import re, sys
from pathlib import Path

# match: f"...Aucun fichier d'entrée: ...{}..." with either quote style
PAT = re.compile(r'f(?P<q>["\'])(?:(?!\1).)*Aucun fichier d\'entrée:\s*\{\}(?:(?!\1).)*\1', re.DOTALL)

def process(p: Path) -> bool:
    txt = p.read_text(encoding="utf-8", errors="ignore")
    def repl(m):
        s = m.group(0)
        return s.replace("{}", "{args.csv}", 1)
    new = PAT.sub(repl, txt)
    if new != txt:
        p.write_text(new, encoding="utf-8")
        print("[FIX] filled empty f-string placeholder in", p)
        return True
    print("[OK] no empty placeholder to fix in", p)
    return False

if __name__ == "__main__":
    for a in sys.argv[1:]: process(Path(a))
