from pathlib import Path
import re, sys

apply = "--write" in sys.argv
files = [Path(p) for p in sys.argv[1:] if p.endswith(".py")]
if not files:
    print("[INFO] aucun .py fourni"); sys.exit(0)

pat = re.compile(r'\b([A-Za-z_]\w*)\.tight_layout\([^)]*\)')
repl = r'fig.subplots_adjust(left=0.04, right=0.98, bottom=0.06, top=0.96)'

total = 0
for f in files:
    s = f.read_text(encoding="utf-8")
    s2, n = pat.subn(repl, s)
    if n:
        print(f"[DRY] {f}: {n} remplacement(s)")
        total += n
        if apply:
            f.write_text(s2, encoding="utf-8")
print(f"[OK] total remplacements: {total} (apply={apply})")
