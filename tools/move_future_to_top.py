#!/usr/bin/env python3
from pathlib import Path
import re, sys

F = Path(sys.argv[1]) if len(sys.argv) > 1 else None
if not F or not F.exists():
    print("usage: move_future_to_top.py FILE", file=sys.stderr); sys.exit(2)

text = F.read_text(encoding="utf-8")
lines = text.splitlines(True)

def find_docstring_end(i):
    # i pointe sur la 1re ligne non vide/non-comment
    if i >= len(lines): return i
    s = lines[i].lstrip()
    if s.startswith('"""') or s.startswith("'''"):
        q = s[:3]
        i += 1
        while i < len(lines):
            if lines[i].strip().endswith(q):
                return i+1
            i += 1
    return i

# 1) position d'insertion = après shebang + docstring + éventuels blancs
i = 0
if i < len(lines) and lines[i].startswith("#!"):
    i += 1
while i < len(lines) and lines[i].strip() == "":
    i += 1
i = find_docstring_end(i)
while i < len(lines) and lines[i].strip() == "":
    i += 1

# 2) collecter tous les "from __future__ import ..." (n'importe où)
FUT_RE = re.compile(r'^\s*from\s+__future__\s+import\s+')
future_lines = []
keep_lines = []
for ln in lines:
    if FUT_RE.match(ln):
        future_lines.append(ln)
    else:
        keep_lines.append(ln)

# rien à faire si pas de lignes future ou si elles sont déjà à la bonne place
if not future_lines:
    print("[NOTE] aucun from __future__ import ... trouvé")
    sys.exit(0)

# 3) insérer les futures à l'emplacement calculé, en évitant un doublon immédiat
# (si elles y étaient déjà)
already = "".join(keep_lines[i:i+len(future_lines)])
insert_block = "".join(future_lines)
if insert_block != already:
    keep_lines[i:i] = future_lines + (["\n"] if keep_lines[i].strip() != "" else [])
    bak = F.with_suffix(F.suffix + ".bak_future")
    if not bak.exists():
        bak.write_text(text, encoding="utf-8")
    F.write_text("".join(keep_lines), encoding="utf-8")
    print(f"[OK] moved {len(future_lines)} future-import line(s) to top in {F}")
else:
    print("[NOTE] imports déjà au bon endroit")
