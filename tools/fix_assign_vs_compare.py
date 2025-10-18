#!/usr/bin/env python3
import re, sys
from pathlib import Path

PAT = re.compile(r'^(\s*)([A-Za-z_]\w*)\s*==\s*\2(\.dropna\s*\()', flags=re.M)

def process(p: Path) -> bool:
    txt = p.read_text(encoding="utf-8", errors="ignore")
    new = PAT.sub(r'\1\2 = \2\3', txt)
    if new != txt:
        p.write_text(new, encoding="utf-8")
        print("[FIX] replaced '==' with '=' for dropna() in", p)
        return True
    print("[OK] no 'df == df.dropna(' pattern in", p)
    return False

if __name__ == "__main__":
    for a in sys.argv[1:]: process(Path(a))
