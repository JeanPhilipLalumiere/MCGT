#!/usr/bin/env python3
import re, sys
from pathlib import Path

if len(sys.argv) != 2:
    print("usage: nuke_stray_path_read.py FILE", file=sys.stderr); sys.exit(2)

p = Path(sys.argv[1])
txt = p.read_text(encoding="utf-8").splitlines(True)

pat = re.compile(r'^\s*df\s*=\s*(?:_?pd)\.read_csv\(\s*path\s*\)\s*$')
out = []
changed = False
for line in txt:
    if pat.match(line):
        changed = True
        continue
    out.append(line)

if changed:
    bak = p.with_suffix(p.suffix + ".bak_pathline")
    if not bak.exists():
        bak.write_text("".join(txt), encoding="utf-8")
    p.write_text("".join(out), encoding="utf-8")
    print(f"[OK] supprimé df=read_csv(path) dans {p}")
else:
    print("[NOTE] aucune ligne df=read_csv(path) à supprimer.")
