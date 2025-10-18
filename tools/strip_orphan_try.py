#!/usr/bin/env python3
import sys, re
from pathlib import Path

ORPHAN_MSG = "expected 'except' or 'finally' block"
TRY_LINE = re.compile(r'^\s*try\s*:\s*(#.*)?$')

def strip_once(p: Path, lineno: int) -> bool:
    lines = p.read_text(encoding="utf-8").splitlines(True)
    if 1 <= lineno <= len(lines) and TRY_LINE.match(lines[lineno-1]):
        lines.pop(lineno-1)
        p.write_text("".join(lines), encoding="utf-8")
        print(f"[FIX] removed orphan 'try:' at line {lineno}")
        return True
    return False

def main(path: str):
    p = Path(path)
    if not p.exists():
        print(f"[ERR] not found: {p}"); sys.exit(2)
    # backup une fois
    bak = p.with_suffix(p.suffix + ".bak_orphantry")
    if not bak.exists():
        bak.write_text(p.read_text(encoding="utf-8"), encoding="utf-8")

    # boucle: compile -> si SyntaxError 'try:' orphelin -> retire -> recommence
    for _ in range(100):
        try:
            compile(p.read_text(encoding="utf-8"), str(p), "exec")
            print("[OK ] compile passed")
            return 0
        except SyntaxError as e:
            if ORPHAN_MSG in str(e) and e.lineno:
                if strip_once(p, e.lineno):
                    continue
            # pas un cas gérable automatiquement
            print(f"[KO ] {type(e).__name__}: {e}")
            return 1
    print("[KO ] too many iterations, giving up")
    return 1

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("usage: tools/strip_orphan_try.py FILE", file=sys.stderr); sys.exit(2)
    sys.exit(main(sys.argv[1]))
