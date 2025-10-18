#!/usr/bin/env python3
import re, sys
from pathlib import Path

PARSER_RX = re.compile(r'(\bargparse\.ArgumentParser\([^)]*\))')
ADDED_RX  = re.compile(r'--fmt[\'"]')

def process(p: Path) -> bool:
    txt = p.read_text(encoding="utf-8", errors="ignore")
    if ADDED_RX.search(txt):
        print("[OK] fmt alias already present in", p); return False
    # Add a minimal alias: parser.add_argument('--fmt', dest='format', choices=['png','pdf','svg'])
    # Insert after first ArgumentParser(...) occurrence
    m = PARSER_RX.search(txt)
    if not m:
        print("[WARN] no ArgumentParser() found in", p); return False
    insert_at = m.end()
    injection = "\nparser.add_argument('--fmt', dest='format', choices=['png','pdf','svg'])\n"
    new = txt[:insert_at] + injection + txt[insert_at:]
    if new != txt:
        p.write_text(new, encoding="utf-8")
        print("[FIX] added --fmt alias in", p)
        return True
    print("[OK] unchanged:", p); return False

if __name__ == "__main__":
    for a in sys.argv[1:]: process(Path(a))
