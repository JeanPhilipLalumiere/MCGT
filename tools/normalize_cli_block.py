#!/usr/bin/env python3
from pathlib import Path
import re, sys
p = Path(sys.argv[1]); t = p.read_text(encoding="utf-8", errors="ignore")

start = re.search(r'^\s*parser\s*=\s*argparse\.ArgumentParser\(', t, re.M)
end   = re.search(r'^\s*args\s*=\s*parser\.parse_args\(\)\s*$', t, re.M)
if not (start and end): print("[OK] no CLI block reshape needed in", p); sys.exit(0)

cli = '''
parser = argparse.ArgumentParser(description="Standard CLI seed (non-intrusif).")
parser.add_argument("--outdir", default="zz-figures/chapter06")
parser.add_argument("--dry-run", action="store_true")
parser.add_argument("--seed", type=int, default=0)
parser.add_argument("--force", action="store_true")
parser.add_argument("-v", "--verbose", action="count", default=0)
parser.add_argument("--dpi", type=int, default=150)
parser.add_argument("--format", choices=["png","pdf","svg"], default="png")
parser.add_argument("--fmt", dest="format", choices=["png","pdf","svg"])  # alias
parser.add_argument("--transparent", action="store_true")
args = parser.parse_args()
'''.lstrip("\n")

nt = t[:start.start()] + cli + t[end.end():]
p.write_text(nt, encoding="utf-8")
print("[FIX] normalized CLI block in", p)
