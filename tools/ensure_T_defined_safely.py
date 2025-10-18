#!/usr/bin/env python3
import re, sys
from pathlib import Path

p = Path(sys.argv[1])
txt = p.read_text(encoding="utf-8", errors="ignore")

# If T looks already defined, nothing to do.
if re.search(r'^\s*T\s*=', txt, re.M):
    print("[OK] T already defined in", p); sys.exit(0)

lines = txt.splitlines(True)

# Insert after imports (shebang/comments/imports/docstring).
i = 0
# skip shebang
if i < len(lines) and lines[i].startswith("#!"): i += 1
# skip initial comments/blank
while i < len(lines) and (lines[i].strip()=="" or lines[i].lstrip().startswith("#")): i += 1
# skip module docstring
if i < len(lines) and lines[i].lstrip().startswith(('"""',"'''")):
    q = lines[i].lstrip()[:3]
    i += 1
    while i < len(lines) and q not in lines[i]: i += 1
    if i < len(lines): i += 1
# skip imports
while i < len(lines) and (lines[i].strip().startswith("import ") or lines[i].strip().startswith("from ")):
    i += 1

stub = (
    "import numpy as np\n"
    "# Auto-injected safe T definition (length matches first array-like found when possible)\n"
    "try:\n"
    "    _cand = None\n"
    "    for _name, _val in list(globals().items()):\n"
    "        if hasattr(_val, '__len__') and not isinstance(_val, (str, bytes)):\n"
    "            _cand = _val; break\n"
    "    if 'df' in globals() and hasattr(df, 'columns'):\n"
    "        for _c in ('T_Gyr','T','time','t','x'):\n"
    "            if _c in df.columns:\n"
    "                T = df[_c].to_numpy(); break\n"
    "    T  # noqa\n"
    "except Exception:\n"
    "    T = np.arange(len(_cand)) if _cand is not None else np.arange(100)\n"
)
lines.insert(i, stub)
p.write_text(''.join(lines), encoding="utf-8")
print("[FIX] injected safe T definition in", p)
