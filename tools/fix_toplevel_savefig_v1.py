#!/usr/bin/env python3
from __future__ import annotations
import re
from pathlib import Path

ROOT = Path("zz-scripts")
RX_SAVE_TOP = re.compile(r'^\s*plt\.savefig\s*\(.*$', re.M)

def patch(path: Path) -> bool:
    s = path.read_text(encoding="utf-8", errors="replace")
    if not RX_SAVE_TOP.search(s):
        return False
    s2 = RX_SAVE_TOP.sub("# [autofix] toplevel plt.savefig(...) neutralisé — utiliser C.finalize_plot_from_args(args)", s)
    if s2 != s:
        path.write_text(s2, encoding="utf-8")
        return True
    return False

def main():
    changed = 0
    for p in ROOT.rglob("*.py"):
        if any(seg in p.parts for seg in ("_attic_untracked","_autofix_sandbox","_tmp",".bak")):
            continue
        if patch(p):
            changed += 1
            print("[neutralized savefig]", p)
    print("Done. Files changed:", changed)

if __name__ == "__main__":
    main()
