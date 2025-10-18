#!/usr/bin/env python3
import re, sys
from pathlib import Path
def process(p: Path) -> bool:
    txt = p.read_text(encoding="utf-8", errors="ignore")
    new = re.sub(r'errors\s*==\s*([\'"])coerce\1', r'errors=\1coerce\1', txt)
    if new != txt:
        p.write_text(new, encoding="utf-8"); print("[FIX] errors==\"coerce\" -> errors=\"coerce\" in", p); return True
    print("[OK] no bad errors==\"coerce\" in", p); return False
if __name__ == "__main__":
    for a in sys.argv[1:]: process(Path(a))
