#!/usr/bin/env python3
import sys
import re
from pathlib import Path

TRY_RE = re.compile(r"^(\s*)try:\s*$")
IF_GUARD_RE = re.compile(r'^\s*if\s+"df"\s+not\s+in\s+globals\(\):\s*$')


def fix(path: Path) -> bool:
    lines = path.read_text(encoding="utf-8").splitlines(True)
    out = []
    i = 0
    changed = False
    while i < len(lines):
        m = TRY_RE.match(lines[i])
        if m:
            # look ahead to next non-empty line
            j = i + 1
            while j < len(lines) and lines[j].strip() == "":
                out.append(lines[j])  # preserve blank lines
                j += 1
            if j < len(lines) and IF_GUARD_RE.match(lines[j]):
                # drop the 'try:' line (i), keep the rest as-is
                changed = True
                i = j
                continue
        out.append(lines[i])
        i += 1
    if changed:
        bak = path.with_suffix(path.suffix + ".bak_trydrop")
        if not bak.exists():
            bak.write_text("".join(lines), encoding="utf-8")
        path.write_text("".join(out), encoding="utf-8")
    return changed


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("usage: strip_try_before_df_guard.py FILE [FILE...]", file=sys.stderr)
        sys.exit(2)
    for a in sys.argv[1:]:
        p = Path(a)
        if not p.exists():
            print(f"[SKIP] not found: {p}")
            continue
        print(f"[PATCH] {'changed' if fix(p) else 'nochange'} → {p}")
