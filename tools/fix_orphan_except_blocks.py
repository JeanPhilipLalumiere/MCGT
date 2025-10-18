#!/usr/bin/env python3
import sys, re
from pathlib import Path

TRY_RE    = re.compile(r'^(\s*)try:\s*$')
EXCEPT_RE = re.compile(r'^(\s*)except\b.*:\s*$')

def patch(path: Path) -> bool:
    lines = path.read_text(encoding="utf-8").splitlines(True)
    changed = False
    # track open try blocks (indent levels)
    try_stack = []

    for i, line in enumerate(lines):
        m_try = TRY_RE.match(line)
        if m_try:
            # push this indent
            try_stack.append(len(m_try.group(1)))
            continue

        m_exc = EXCEPT_RE.match(line)
        if m_exc:
            ind = len(m_exc.group(1))
            # pop any try blocks that are deeper (closed earlier)
            while try_stack and try_stack[-1] > ind:
                try_stack.pop()
            # if there isn't a try at this indent, it's orphaned
            if not try_stack or try_stack[-1] != ind:
                lines[i] = f"{m_exc.group(1)}if False:\n"
                changed = True
            else:
                # normal except; keep stack as-is
                pass

        # if this is a dedent line and closes a try at this indent, pop
        # (very lightweight heuristic; good enough for our single-file fix)
        if not line.strip():  # blank line: ignore
            continue
        cur_ind = len(line) - len(line.lstrip(' \t'))
        while try_stack and cur_ind < try_stack[-1]:
            try_stack.pop()

    if changed:
        bak = path.with_suffix(path.suffix + ".bak_orph")
        if not bak.exists():
            bak.write_text("".join(lines), encoding="utf-8")
        path.write_text("".join(lines), encoding="utf-8")
    return changed

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("usage: fix_orphan_except_blocks.py FILE [FILE...]", file=sys.stderr)
        sys.exit(2)
    for a in sys.argv[1:]:
        p = Path(a)
        if not p.exists():
            print(f"[SKIP] not found: {p}")
            continue
        print(f"[PATCH] {'changed' if patch(p) else 'nochange'} → {p}")
