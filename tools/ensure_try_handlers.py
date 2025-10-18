#!/usr/bin/env python3
import re, sys
from pathlib import Path
HDR_TRY = re.compile(r'^(\s*)try:\s*(#.*)?$', re.M)
def indent(s): return len(s.expandtabs(4)) - len(s.lstrip(" "))
def process(p: Path):
    L = p.read_text(encoding="utf-8", errors="ignore").splitlines(True)
    i=0; changed=False
    while i < len(L):
        m = HDR_TRY.match(L[i])
        if not m: i+=1; continue
        base = len(m.group(1).expandtabs(4))
        j=i+1
        # find end of try block
        while j < len(L) and (L[j].strip()=="" or indent(L[j])>base and not re.match(r'^\s*(except\b|finally:)', L[j])):
            j+=1
        # if next nonblank is not except/finally, insert a minimal handler
        if j>=len(L) or not re.match(r'^\s*(except\b|finally:)', L[j]):
            L.insert(j, " "*(base)+"except Exception as _e:\n")
            L.insert(j+1, " "*(base+4)+"pass\n")
            changed=True
            i=j+2
        else:
            i=j
    if changed:
        p.write_text("".join(L), encoding="utf-8")
        print("[FIX] added missing try-handlers in", p)
    else:
        print("[OK] try-handlers present in", p)
if __name__ == "__main__":
    for a in sys.argv[1:]: process(Path(a))
