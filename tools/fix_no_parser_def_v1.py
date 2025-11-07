#!/usr/bin/env python3
from __future__ import annotations
import re, sys, os
from pathlib import Path

ROOT = Path("zz-scripts")
RX_HAS_BUILD = re.compile(r'^\s*def\s+build_parser\s*\(', re.M)
RX_HAS_MAIN  = re.compile(r'^\s*if\s+__name__\s*==\s*["\']__main__["\']\s*:', re.M)
RX_HAS_IMPORT_C = re.compile(r'^\s*from\s+_common\s+import\s+cli\s+as\s+C\s*$', re.M)

TEMPLATE_BUILD = """\
def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description={desc})
    C.add_common_plot_args(p)
    return p
"""

TEMPLATE_MAIN = """\
def main(argv=None) -> int:
    args = build_parser().parse_args(argv)
    log = C.setup_logging(args.log_level)
    C.setup_mpl(args.style)
    out = C.ensure_outpath(args)
    # TODO: insère la logique de la figure si nécessaire
    C.finalize_plot_from_args(args)
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
"""

def detect_desc(path: Path, s: str) -> str:
    stem = path.stem.replace("_"," ")
    return f"\"{stem}\""

def patch(path: Path) -> bool:
    s = path.read_text(encoding="utf-8", errors="replace")
    changed = False
    if not RX_HAS_IMPORT_C.search(s):
        s = f"from _common import cli as C\n" + s
        changed = True
    if "import argparse" not in s:
        s = "import argparse\n" + s
        changed = True
    if not RX_HAS_BUILD.search(s):
        desc = detect_desc(path, s)
        s = s + ("\n" if not s.endswith("\n") else "") + TEMPLATE_BUILD.format(desc=desc)
        changed = True
    if not RX_HAS_MAIN.search(s):
        s = s + ("\n" if not s.endswith("\n") else "") + TEMPLATE_MAIN
        changed = True
    if changed:
        path.write_text(s, encoding="utf-8")
    return changed

def main():
    todo = []
    for p in ROOT.rglob("*.py"):
        if any(seg in p.parts for seg in ("_attic_untracked","_autofix_sandbox","_tmp",".bak")):
            continue
        txt = p.read_text(encoding="utf-8", errors="replace")
        if ("NO_PARSER_DEF" in txt) or True:  # on sélectionnera par extension via le scan externe
            todo.append(p)
    changed = 0
    for p in sorted(todo):
        # n’applique réellement que si le fichier n’a pas build_parser ou main guard
        s = p.read_text(encoding="utf-8", errors="replace")
        if not RX_HAS_BUILD.search(s) or not RX_HAS_MAIN.search(s):
            if patch(p):
                changed += 1
                print("[patched]", p)
    print("Done. Files changed:", changed)

if __name__ == "__main__":
    main()
