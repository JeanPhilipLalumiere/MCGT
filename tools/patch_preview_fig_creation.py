#!/usr/bin/env python3
import argparse, ast, re
from pathlib import Path

TARGET = Path("zz-scripts/chapter02/plot_fig05_FG_series.py")

def compiles_ok(path: Path) -> bool:
    try:
        ast.parse(path.read_text(encoding="utf-8", errors="ignore"))
        return True
    except Exception:
        return False

def insert_import(lines):
    imp = "import matplotlib.pyplot as plt\n"
    txt = "".join(lines)
    if "import matplotlib.pyplot as plt" in txt:
        return lines
    # skip shebang + docstring + from __future__
    i = 0
    if lines and lines[0].startswith("#!"):
        i = 1
    # skip docstring
    if i < len(lines) and lines[i].lstrip().startswith(('"""',"'''")):
        q = lines[i].lstrip()[:3]; i += 1
        while i < len(lines) and q not in lines[i]:
            i += 1
        if i < len(lines): i += 1
    while i < len(lines) and lines[i].startswith("from __future__ import"):
        i += 1
    lines.insert(i, imp)
    return lines

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()

    p = TARGET
    if not p.exists():
        print(f"[SKIP] not found: {p}")
        return
    txt = p.read_text(encoding="utf-8", errors="ignore")

    if "fig.subplots_adjust(" not in txt:
        print("[SKIP] no fig.subplots_adjust found")
        return
    if re.search(r"\bfig\s*,\s*ax\s*=\s*plt\.subplots\s*\(", txt):
        print("[SKIP] fig/ax already created")
        return

    lines = txt.splitlines(True)
    # insertion point: before first 'fig.subplots_adjust('
    insert_at = None
    for i, line in enumerate(lines):
        if "fig.subplots_adjust(" in line:
            insert_at = i
            break
    if insert_at is None:
        print("[SKIP] no insertion point")
        return

    # import plt if needed
    new_lines = insert_import(lines[:])

    # detect top-level vs indented usage
    target_line = new_lines[insert_at]
    is_toplevel = (target_line.lstrip() == target_line)
    create_line = ("fig, ax = plt.subplots()\n" if is_toplevel
                   else "    fig, ax = plt.subplots()\n")

    preview = f"insert @{insert_at}: {create_line.strip()!r}"
    if not args.apply:
        print("[DRY]", preview)
        return

    bak = p.with_suffix(p.suffix + ".bak_fig_init")
    if not bak.exists():
        bak.write_text(txt, encoding="utf-8")

    new_lines.insert(insert_at, create_line)
    p.write_text("".join(new_lines), encoding="utf-8")

    if not compiles_ok(p):
        p.write_text(bak.read_text(encoding="utf-8"), encoding="utf-8")
        print("[ROLLBACK] compile failed; restored backup")
        return
    print("[APPLY] patched:", preview)

if __name__ == "__main__":
    main()
