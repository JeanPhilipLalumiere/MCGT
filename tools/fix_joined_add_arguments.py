#!/usr/bin/env python3
from pathlib import Path

ROOTS = ["zz-scripts"]

TRIGGERS = (
    "parser.add_argument(",
    "parser.set_defaults(",
    "args = parser.parse_args(",
)

def fix_line(line: str) -> list[str]:
    # Si une ligne contient ')' avant l'un des TRIGGERS, on coupe avant le trigger.
    out = [line]
    changed = True
    while changed:
        changed = False
        new_out = []
        for ln in out:
            cut_idx = -1
            trig = None
            for t in TRIGGERS:
                i = ln.find(t)
                if i > 0 and ')' in ln[:i]:
                    if cut_idx == -1 or i < cut_idx:
                        cut_idx, trig = i, t
            if cut_idx != -1:
                # On conserve l'indentation initiale
                indent = ln[:len(ln) - len(ln.lstrip())]
                left  = ln[:cut_idx].rstrip() + "\n"
                right = indent + ln[cut_idx:].lstrip()
                new_out.extend([left, right])
                changed = True
            else:
                new_out.append(ln)
        out = new_out
    return out

def process(p: Path) -> bool:
    txt = p.read_text(encoding="utf-8", errors="ignore")
    lines = txt.splitlines(True)
    new_lines = []
    touched = False
    for ln in lines:
        fixed = fix_line(ln)
        if len(fixed) > 1:
            touched = True
        new_lines.extend(fixed)
    if touched:
        bak = p.with_suffix(p.suffix + ".bak_argsjoin")
        if not bak.exists():
            bak.write_text(txt, encoding="utf-8")
        p.write_text("".join(new_lines), encoding="utf-8")
    return touched

def main():
    changed = 0
    for root in ROOTS:
        for p in Path(root).rglob("*.py"):
            try:
                if process(p):
                    changed += 1
            except Exception:
                pass
    print(f"[OK] split joined argparse lines in {changed} file(s)")

if __name__ == "__main__":
    main()
