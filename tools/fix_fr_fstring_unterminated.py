#!/usr/bin/env python3
import re, sys
from pathlib import Path
p = Path(sys.argv[1])
txt = p.read_text(encoding="utf-8", errors="ignore")
pat = re.compile(r'(f"Aucun fichier d\'entrée:\s*\{args\.csv\})(?!")\s*$', re.M)
new = pat.sub(r'\1"', txt)
if new != txt:
    p.write_text(new, encoding="utf-8")
    print("[FIX] closed unterminated French f-string in", p)
else:
    print("[OK] French f-string looks fine in", p)
