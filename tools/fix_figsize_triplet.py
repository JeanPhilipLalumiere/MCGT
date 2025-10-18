#!/usr/bin/env python3
import re, sys
from pathlib import Path
p = Path(sys.argv[1])
txt = p.read_text(encoding="utf-8", errors="ignore")
# Replace any triple with a reasonable default (6.5, 4.5)
new = re.sub(r'figsize\s*=\s*\(\s*[^,]+,\s*[^,]+,\s*[^)]+\)', 'figsize=(6.5, 4.5)', txt)
if new != txt:
    p.write_text(new, encoding="utf-8")
    print("[FIX] normalized figsize triplet -> pair in", p)
else:
    print("[OK] no figsize triplet in", p)
