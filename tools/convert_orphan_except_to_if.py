#!/usr/bin/env python3
import re, sys
from pathlib import Path

if len(sys.argv) < 2:
    print("usage: convert_orphan_except_to_if.py FILE [FILE...]", file=sys.stderr)
    sys.exit(2)

EXC_RE = re.compile(r'^(\s*)except\s+NameError\s*:\s*$')
DF_LINE_RE = re.compile(r'^\s*df\b.*$')  # ex: "df  # peut lever NameError"

def convert(path: Path) -> bool:
    txt = path.read_text(encoding="utf-8").splitlines(True)
    out = []
    changed = False
    for line in txt:
        m = EXC_RE.match(line)
        if m:
            indent = m.group(1)
            # si la ligne précédente est un "df ..." (ex-garde), on la retire
            if out and DF_LINE_RE.match(out[-1]):
                out.pop()
            out.append(f'{indent}if "df" not in globals():\n')
            changed = True
        else:
            out.append(line)
    if changed:
        bak = path.with_suffix(path.suffix + ".bak_if")
        if not bak.exists():
            bak.write_text("".join(txt), encoding="utf-8")
        path.write_text("".join(out), encoding="utf-8")
    return changed

for arg in sys.argv[1:]:
    p = Path(arg)
    if not p.exists():
        print(f"[SKIP] not found: {p}")
        continue
    if convert(p):
        print(f"[PATCH] converted orphan except→if in {p}")
    else:
        print(f"[OK   ] no orphan except found in {p}")
