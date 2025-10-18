#!/usr/bin/env python3
import sys
from pathlib import Path

def show(p: Path, pad=8):
    try:
        compile(p.read_text(encoding="utf-8"), str(p), "exec")
        print(f"[OK ] {p}: pas d'IndentationError")
    except IndentationError as e:
        ln = e.lineno or 1
        print(f"[ERR] {p}: IndentationError at line {ln}")
        lines = p.read_text(encoding="utf-8").splitlines()
        lo = max(1, ln - pad)
        hi = min(len(lines), ln + pad)
        w = len(str(hi))
        for i in range(lo, hi+1):
            mark = ">>" if i == ln else "  "
            print(f"{mark} {str(i).rjust(w)}: {lines[i-1]}")
    except Exception as ex:
        print(f"[NOTE] {p}: autre erreur ({type(ex).__name__}) — pas liée à l'indentation.")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("usage: show_indent_context.py FILE [FILE...]", file=sys.stderr); sys.exit(2)
    for a in sys.argv[1:]:
        show(Path(a))
