#!/usr/bin/env python3
import re, sys
from pathlib import Path
p = Path(sys.argv[1])
txt = p.read_text(encoding="utf-8", errors="ignore")
# Find a line with ArgumentParser(description="... with no closing ")
pat = re.compile(r'(ArgumentParser\([^)]*description\s*=\s*"[^\n"]*)\n')
def repl(m): return m.group(1) + '")\n'
new = pat.sub(repl, txt)
if new != txt:
    p.write_text(new, encoding="utf-8")
    print("[FIX] closed unterminated ArgumentParser description in", p)
else:
    print("[OK] no unterminated ArgumentParser description in", p)
