#!/usr/bin/env python3
import re, sys
from pathlib import Path

if len(sys.argv) < 2:
    print("usage: convert_orphan_except_to_if_v2.py FILE [FILE...]", file=sys.stderr)
    sys.exit(2)

EXC_RE = re.compile(r'^(\s*)except\s+NameError\s*:\s*$')
DF_LINE_RE = re.compile(r'^\s*df\b.*$')  # ex: "df  # peut lever NameError"

def convert(path: Path) -> bool:
    src = path.read_text(encoding="utf-8").splitlines(True)
    out = []
    changed = False
    for i, line in enumerate(src):
        m = EXC_RE.match(line)
        if m:
            # cherche la ligne précédente non vide
            j = len(out) - 1
            while j >= 0 and out[j].strip() == "":
                j -= 1
            if j >= 0 and DF_LINE_RE.match(out[j]):
                # On remplace cet except NameError: par un if "df" not in globals():
                indent = m.group(1)
                # on supprime la ligne "df  # peut lever NameError"
                out.pop()
                out.append(f'{indent}if "df" not in globals():\n')
                changed = True
            else:
                # ne pas toucher (ex: except du shim d’args)
                out.append(line)
        else:
            out.append(line)

    if changed:
        bak = path.with_suffix(path.suffix + ".bak_if2")
        if not bak.exists():
            bak.write_text("".join(src), encoding="utf-8")
        path.write_text("".join(out), encoding="utf-8")
    return changed

for arg in sys.argv[1:]:
    p = Path(arg)
    if not p.exists():
        print(f"[SKIP] not found: {p}")
        continue
    if convert(p):
        print(f"[PATCH] targeted convert in {p}")
    else:
        print(f"[OK   ] nothing to convert in {p}")
