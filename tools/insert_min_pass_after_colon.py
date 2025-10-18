#!/usr/bin/env python3
import argparse, json, re
from pathlib import Path

REPORT = Path("zz-manifests/indent_failures.json")

def next_nonempty(lines, i):
    j = i + 1
    while j < len(lines) and lines[j].strip() == "":
        j += 1
    return j if j < len(lines) else None

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()

    data = json.loads(REPORT.read_text(encoding="utf-8"))
    for r in data:
        msg = r.get("msg","")
        if not msg.startswith("expected an indented block"):
            continue
        p = Path(r["path"])
        lines = p.read_text(encoding="utf-8", errors="ignore").splitlines(True)
        colon_line_no = int(re.search(r"on line (\d+)", msg).group(1)) if "on line " in msg else r["lineno"]-1
        i = colon_line_no - 1
        if i < 0 or i >= len(lines):
            continue
        indent = len(lines[i]) - len(lines[i].lstrip(" "))
        j = next_nonempty(lines, i)
        if j is None:
            continue
        # si la prochaine ligne n'est pas plus indentée, on insère un pass.
        if len(lines[j]) - len(lines[j].lstrip(" ")) <= indent:
            ins = " " * (indent + 4) + "pass\n"
            if not args.apply:
                print("[DRY]", p, f"insert 'pass' after L{i+1}")
                continue
            bak = p.with_suffix(p.suffix + ".bak_after_colon")
            if not bak.exists():
                bak.write_text("".join(lines), encoding="utf-8")
            lines.insert(i+1, ins)
            p.write_text("".join(lines), encoding="utf-8")
            print("[APPLY]", p, f"inserted pass after L{i+1}")
    print(f"[DONE] apply={args.apply}")
if __name__ == "__main__":
    main()
