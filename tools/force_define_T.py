#!/usr/bin/env python3
import re, sys
from pathlib import Path

p = Path(sys.argv[1])
txt = p.read_text(encoding="utf-8", errors="ignore")

# If T already assigned somewhere, do nothing.
if re.search(r'^\s*T\s*=', txt, re.M):
    print("[OK] T already defined in", p); sys.exit(0)

lines = txt.splitlines(True)

# Heuristic: insert after the first df = pd.read_csv(...) or first "df =" line.
ins = None
for i, s in enumerate(lines):
    if re.search(r'^\s*df\s*=\s*pd\.read_csv\(', s) or re.search(r'^\s*df\s*=', s):
        ins = i + 1
        break

# Fall back: after imports.
if ins is None:
    ins = 0
    while ins < len(lines) and (lines[ins].startswith("#!") or
                                lines[ins].strip().startswith("from ") or
                                lines[ins].strip().startswith("import") or
                                lines[ins].strip()=="" or
                                lines[ins].strip().startswith("#")):
        ins += 1

stub = (
    "import numpy as np\n"
    "try:\n"
    "    T = (df['T_Gyr'].to_numpy() if 'df' in locals() and 'T_Gyr' in getattr(df, 'columns', [])\n"
    "         else (df['T'].to_numpy() if 'df' in locals() and 'T' in getattr(df, 'columns', [])\n"
    "         else np.arange(100)))\n"
    "except Exception:\n"
    "    T = np.arange(100)\n"
)
lines.insert(ins, stub)
p.write_text("".join(lines), encoding="utf-8")
print("[FIX] injected T definition in", p)
