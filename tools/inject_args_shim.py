#!/usr/bin/env python3
import sys, re
from pathlib import Path

SHIM = """# >>> AUTO-ARGS-SHIM >>>
try:
    args  # may raise NameError if not yet defined
except NameError:  # inject a minimal argparse so early uses of args.* work
    import argparse as _argparse, sys as _sys
    _shim = _argparse.ArgumentParser(add_help=False)
    # Common figure flags we saw in chap.10
    _shim.add_argument('--results')
    _shim.add_argument('--x-col'); _shim.add_argument('--y-col')
    _shim.add_argument('--sigma-col'); _shim.add_argument('--group-col')
    _shim.add_argument('--n-col'); _shim.add_argument('--p95-col')
    _shim.add_argument('--orig-col'); _shim.add_argument('--recalc-col')
    _shim.add_argument('--m1-col'); _shim.add_argument('--m2-col')
    _shim.add_argument('--seed', type=int)
    _shim.add_argument('--boot-ci', action='store_true')
    _shim.add_argument('--dpi'); _shim.add_argument('--out')
    _shim.add_argument('--format'); _shim.add_argument('--transparent', action='store_true')
    # variants we saw in code: --p95-ref → args.p95_ref
    _shim.add_argument('--p95-ref', dest='p95_ref', type=float)
    try:
        args, _unk = _shim.parse_known_args(_sys.argv[1:])
    except Exception:
        class _A: pass
        args = _A()
        args.results = None
# <<< AUTO-ARGS-SHIM <<<
"""

def inject_shim(p: Path):
    txt = p.read_text(encoding="utf-8")
    if "AUTO-ARGS-SHIM" in txt:
        print(f"[OK   ] {p}: shim déjà présent")
        return
    # insérer juste après la ligne shebang si présente, sinon au tout début
    lines = txt.splitlines(True)
    idx = 0
    if lines and lines[0].startswith("#!"):
        idx = 1
    new = "".join(lines[:idx]) + SHIM + "".join(lines[idx:])
    p.write_text(new, encoding="utf-8")
    print(f"[PATCH] {p}: shim args injecté")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("usage: tools/inject_args_shim.py FILE [FILE...]", file=sys.stderr)
        sys.exit(2)
    for a in sys.argv[1:]:
        path = Path(a)
        if not path.exists():
            print(f"[SKIP ] not found: {path}")
            continue
        inject_shim(path)
