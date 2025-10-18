#!/usr/bin/env python3
import argparse, ast, re
from pathlib import Path

ROOT = Path("zz-scripts")  # <-- on cible uniquement les scripts de figures
RE_PARSE_ASSIGN = re.compile(
    r"^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*parser\s*\.\s*parse_args\s*\(",
    re.MULTILINE,
)

def list_py_files():
    for p in ROOT.rglob("*.py"):
        if any(part in {"__pycache__"} for part in p.parts):
            continue
        yield p

def has_parse_args(txt: str) -> bool:
    return "parser.parse_args(" in txt

def has_ensure_call(txt: str) -> bool:
    return "ensure_std_args(" in txt

def compiles_ok(path: Path) -> bool:
    try:
        ast.parse(path.read_text(encoding="utf-8", errors="ignore"))
        return True
    except Exception:
        return False

def find_insertion_after_parse(lines, idx):
    depth = 0; in_str = None; esc = False
    i = idx
    while i < len(lines):
        for ch in lines[i]:
            if in_str:
                if esc: esc = False
                elif ch == "\\": esc = True
                elif ch == in_str: in_str = None
                continue
            if ch in ("'", '"'): in_str = ch
            elif ch in "([{": depth += 1
            elif ch in ")]}": depth = max(0, depth-1)
        if depth == 0:
            return i + 1
        i += 1
    return idx + 1

def insert_import(lines):
    imp = "from _common.postparse import ensure_std_args\n"
    if any("ensure_std_args" in l and "from _common.postparse" in l for l in lines):
        return lines
    # injecter après éventuelle docstring et futures
    i = 0
    while i < len(lines) and lines[i].strip() == "": i += 1
    if i < len(lines) and lines[i].lstrip().startswith(('"""',"'''")):
        q = lines[i].lstrip()[:3]; i += 1
        while i < len(lines) and q not in lines[i]: i += 1
        if i < len(lines): i += 1
    while i < len(lines) and lines[i].startswith("from __future__ import"):
        i += 1
    lines.insert(i, imp)
    return lines

def patch_file(p: Path, apply=False) -> dict:
    txt = p.read_text(encoding="utf-8", errors="ignore")
    if not has_parse_args(txt) or has_ensure_call(txt):
        return {"file": str(p), "changed": False, "reason": "skip"}
    m = RE_PARSE_ASSIGN.search(txt)
    if not m:
        return {"file": str(p), "changed": False, "reason": "no_assign"}
    var = m.group(1)
    lines = txt.splitlines(True)
    pos = txt[:m.start()].count("\n")
    insert_at = find_insertion_after_parse(lines, pos)
    new_line = f"{var} = ensure_std_args({var})\n"

    if not apply:
        return {"file": str(p), "changed": True, "preview": f"insert @{insert_at}: {new_line.strip()}"}

    bak = p.with_suffix(p.suffix + ".bak_ensure_std_args")
    if not bak.exists():
        bak.write_text(txt, encoding="utf-8")
    new_lines = insert_import(lines[:])
    new_lines.insert(insert_at, new_line)
    p.write_text("".join(new_lines), encoding="utf-8")

    if not compiles_ok(p):
        p.write_text(bak.read_text(encoding="utf-8"), encoding="utf-8")
        return {"file": str(p), "changed": False, "reason": "compile_fail_rolled_back"}
    return {"file": str(p), "changed": True, "reason": "patched"}

def main():
    ap = argparse.ArgumentParser(description="Inject ensure_std_args() de manière sûre (zz-scripts/*).")
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--limit", type=int, default=10)
    ap.add_argument("--only", type=str, default=None)
    args = ap.parse_args()

    targets = []
    if args.only:
        targets = [Path(args.only)]
    else:
        for p in list_py_files():
            txt = p.read_text(encoding="utf-8", errors="ignore")
            if has_parse_args(txt) and not has_ensure_call(txt):
                targets.append(p)

    changed = 0
    for p in targets[: args.limit]:
        r = patch_file(p, apply=args.apply)
        print(f"[{'APPLY' if args.apply else 'DRY'}] {r}")
        if r.get("changed"): changed += 1
    print(f"[SUMMARY] candidates={len(targets)} processed={min(len(targets), args.limit)} changed={changed} apply={args.apply}")

if __name__ == "__main__":
    main()
