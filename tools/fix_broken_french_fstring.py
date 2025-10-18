#!/usr/bin/env python3
import re, sys
from pathlib import Path

p = Path(sys.argv[1])
t = p.read_text(encoding="utf-8")
# Replace any broken multi-line version with a single canonical print
t2 = re.sub(
    r'print\(\s*f?"Aucun fichier d\'entrée:\s*\{?args\.csv\}?"\s*\)\s*',
    'print(f"Aucun fichier d\'entrée: {args.csv}")\n',
    t,
    flags=re.M
)
# Also fix the 2-line variant like: f"... {args.csv}\n")  → single line
t2 = re.sub(
    r'^\s*f"Aucun fichier d\'entrée:\s*\{args\.csv\}"\s*\)\s*$',
    'print(f"Aucun fichier d\'entrée: {args.csv}")\n',
    t2,
    flags=re.M
)
# Last resort: if we see the fragment without closing, rewrite the whole line safely
t2 = re.sub(
    r'^\s*["\']?Aucun fichier d\'entrée:\s*\{?args\.csv\}?\s*["\']\)?\s*$',
    'print(f"Aucun fichier d\'entrée: {args.csv}")\n',
    t2,
    flags=re.M
)
if t2 != t:
    p.write_text(t2, encoding="utf-8"); print("[FIX] normalized French f-string in", p)
else:
    print("[OK] French f-string already fine in", p)
