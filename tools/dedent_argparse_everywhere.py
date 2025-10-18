#!/usr/bin/env python3
from pathlib import Path

ROOTS = ["zz-scripts"]
TRIGS = (
    "parser.add_argument(",
    "parser.set_defaults(",
    "args = parser.parse_args(",
    "parser = argparse.ArgumentParser(",
)

def process(p: Path) -> bool:
    txt = p.read_text(encoding="utf-8", errors="ignore")
    lines = txt.splitlines(True)
    changed = False
    for i, raw in enumerate(lines):
        if raw[:1].isspace():
            s = raw.lstrip()
            if s.startswith(TRIGS):
                lines[i] = s  # dé-dente au toplevel
                changed = True
    if changed:
        bak = p.with_suffix(p.suffix + ".bak_dedent_argparse")
        if not bak.exists():
            bak.write_text(txt, encoding="utf-8")
        p.write_text("".join(lines), encoding="utf-8")
    return changed

def main():
    changed = 0
    for root in ROOTS:
        for p in Path(root).rglob("*.py"):
            try:
                if process(p):
                    changed += 1
            except Exception:
                pass
    print(f"[OK] dedented argparse lines in {changed} file(s)")

if __name__ == "__main__":
    main()
