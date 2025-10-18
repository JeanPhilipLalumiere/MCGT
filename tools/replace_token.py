#!/usr/bin/env python3
import re, sys
from pathlib import Path
def process(p: Path) -> bool:
    txt = p.read_text(encoding="utf-8", errors="ignore")
    new = re.sub(r'(\w|\))\s+et\s+(\{|\w)', r'\1 and \2', txt)
    if new != txt:
        p.write_text(new, encoding="utf-8"); print("[FIX]", p); return True
    print("[OK]", p); return False
if __name__ == "__main__":
    for arg in sys.argv[1:]: process(Path(arg))
