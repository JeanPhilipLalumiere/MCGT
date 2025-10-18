#!/usr/bin/env python3
import sys, re
from pathlib import Path

MSG = "expected 'except' or 'finally' block"
TRY_RE = re.compile(r'^\s*try\s*:\s*(#.*)?$')

def strip_prev_try(p: Path, lineno: int) -> bool:
    lines = p.read_text(encoding="utf-8").splitlines(True)
    # Cherche en arrière à partir de lineno-1
    for i in range(lineno-1, 0, -1):
        if TRY_RE.match(lines[i-1]):
            del lines[i-1]
            p.write_text("".join(lines), encoding="utf-8")
            print(f"[FIX] removed orphan 'try:' found at line {i}")
            return True
    return False

def main(path: str) -> int:
    f = Path(path)
    if not f.exists():
        print(f"[ERR] not found: {f}", file=sys.stderr); return 2
    bak = f.with_suffix(f.suffix + ".bak_orphantry2")
    if not bak.exists():
        bak.write_text(f.read_text(encoding="utf-8"), encoding="utf-8")

    for _ in range(200):
        try:
            compile(f.read_text(encoding="utf-8"), str(f), "exec")
            print("[OK ] compile passed")
            return 0
        except SyntaxError as e:
            if MSG in str(e) and (e.lineno or 0) > 0:
                if strip_prev_try(f, e.lineno):
                    continue
            print(f"[KO ] {type(e).__name__}: {e}")
            return 1
    print("[KO ] too many iterations, giving up")
    return 1

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("usage: tools/strip_orphan_try_v2.py FILE", file=sys.stderr)
        sys.exit(2)
    sys.exit(main(sys.argv[1]))
