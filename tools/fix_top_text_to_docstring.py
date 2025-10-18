#!/usr/bin/env python3
import argparse, ast
from pathlib import Path

TARGET = Path("zz-scripts/chapter07/generate_data_chapter07.py")

TRIGS = ("import ", "from ", "def ", "class ", "if ", "try:", "parser = argparse.ArgumentParser(")

def compiles_ok(p: Path) -> bool:
    try:
        ast.parse(p.read_text(encoding="utf-8", errors="ignore"))
        return True
    except Exception:
        return False

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()

    p = TARGET
    if not p.exists():
        print(f"[SKIP] not found: {p}")
        return
    src = p.read_text(encoding="utf-8", errors="ignore")
    lines = src.splitlines(True)

    i = 0
    # skip shebang
    if lines and lines[0].startswith("#!"):
        i = 1

    # already has a docstring at top?
    if i < len(lines) and lines[i].lstrip().startswith(('"""',"'''","#")):
        print("[SKIP] already has header or comment")
        return

    # find first "code" trigger
    j = i
    while j < len(lines) and not any(lines[j].startswith(t) for t in TRIGS):
        j += 1
    if j == i:
        print("[SKIP] nothing to wrap")
        return

    pre = "".join(lines[i:j]).rstrip("\n")
    doc = f'"""(auto-wrapped header)\\n{pre}\\n"""\n'
    new_lines = lines[:i] + [doc] + lines[j:]

    if not args.apply:
        print("[DRY] would wrap lines", i, "to", j, "into a docstring")
        return

    bak = p.with_suffix(p.suffix + ".bak_topwrap")
    if not bak.exists():
        bak.write_text(src, encoding="utf-8")
    p.write_text("".join(new_lines), encoding="utf-8")

    if not compiles_ok(p):
        p.write_text(bak.read_text(encoding="utf-8"), encoding="utf-8")
        print("[ROLLBACK] compile failed; restored backup")
        return
    print("[APPLY] header wrapped into docstring")

if __name__ == "__main__":
    main()
