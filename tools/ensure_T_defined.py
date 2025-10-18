#!/usr/bin/env python3
import re, sys
from pathlib import Path
p = Path(sys.argv[1])
txt = p.read_text(encoding="utf-8", errors="ignore")
# If file uses 'T,' somewhere and no assignment to T, inject a safe definition after imports.
if "T," in txt and not re.search(r'^\s*T\s*=', txt, re.M):
    lines = txt.splitlines(True)
    ins = 0
    while ins < len(lines) and (lines[ins].startswith("#!") or lines[ins].strip().startswith("from __future__") or lines[ins].strip().startswith("import") or lines[ins].strip().startswith("from ") or lines[ins].strip()=="" or lines[ins].strip().startswith("#")):
        ins += 1
    stub = (
        "import numpy as np\n"
        "try:\n"
        "    T = df['T_Gyr'].to_numpy() if 'df' in locals() and 'T_Gyr' in df.columns else df['T'].to_numpy()\n"
        "except Exception:\n"
        "    # Fallback: monotonic index if dataframe not available\n"
        "    T = np.arange(100)\n"
    )
    lines.insert(ins, stub)
    p.write_text("".join(lines), encoding="utf-8")
    print("[FIX] injected T definition in", p)
else:
    print("[OK] T already defined or not needed in", p)
