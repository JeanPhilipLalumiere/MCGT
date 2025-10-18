#!/usr/bin/env python3
from pathlib import Path
import re

ROOTS = ["zz-scripts"]

RULES = [
    (re.compile(r'\)\s+(parser\.add_argument\s*\()'), r')\n\1'),
    (re.compile(r'\)\s+(parser\.set_defaults\s*\()'), r')\n\1'),
    (re.compile(r'\)\s+(args\s*=\s*parser\.parse_args\s*\()'), r')\n\1'),
]

def process(p: Path) -> bool:
    txt = p.read_text(encoding="utf-8", errors="ignore")
    new = txt
    for pat, repl in RULES:
        new = pat.sub(repl, new)
    if new != txt:
        bak = p.with_suffix(p.suffix + ".bak_argsjoin")
        if not bak.exists():
            bak.write_text(txt, encoding="utf-8")
        p.write_text(new, encoding="utf-8")
        return True
    return False

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
