#!/usr/bin/env python3
import argparse, json, re
from pathlib import Path

REPORT = Path("zz-manifests/indent_failures.json")
SAFE_PREFIXES = ("try:", "if args.", "if args", "args = parse_args()", "args = ensure_std_args(")

def leading_spaces(s: str) -> int:
    return len(s) - len(s.lstrip(" "))

def prev_nonempty(lines, i):
    j = i - 1
    while j >= 0 and lines[j].strip() == "":
        j -= 1
    return j

def patch_unexpected_indent(p: Path, lineno: int) -> str | None:
    lines = p.read_text(encoding="utf-8", errors="ignore").splitlines(True)
    i = lineno - 1
    cur = lines[i]
    if not cur.lstrip().startswith(SAFE_PREFIXES):
        return None
    j = prev_nonempty(lines, i)
    base = 0 if j < 0 else leading_spaces(lines[j])
    fixed = " " * base + cur.lstrip()
    if fixed == cur:
        return None
    lines[i] = fixed
    return "".join(lines)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--only", nargs="*", help="paths à cibler (sinon tout le report)")
    args = ap.parse_args()

    data = json.loads(REPORT.read_text(encoding="utf-8"))
    changed = 0
    for r in data:
        if r["type"] != "SyntaxError" or r["msg"] != "unexpected indent":
            continue
        p = Path(r["path"])
        if args.only and str(p) not in args.only:
            continue
        new_txt = patch_unexpected_indent(p, r["lineno"])
        if not new_txt:
            print("[SKIP]", p, f"(no safe match @L{r['lineno']})")
            continue
        if not args.apply:
            print("[DRY]", p, f"dedent L{r['lineno']} to previous level")
            continue
        bak = p.with_suffix(p.suffix + ".bak_autofix_indent")
        if not bak.exists():
            bak.write_text(p.read_text(encoding="utf-8"), encoding="utf-8")
        p.write_text(new_txt, encoding="utf-8")
        changed += 1
        print("[APPLY]", p, f"fixed L{r['lineno']}")
    print(f"[SUMMARY] changed={changed} (apply={args.apply})")

if __name__ == "__main__":
    main()
