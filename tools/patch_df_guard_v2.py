#!/usr/bin/env python3
import re, sys
from pathlib import Path

# remplace la ligne "df = _pd.read_csv(args.results)" INSÉRÉE par le précédent patch
PAT = re.compile(r'^(?P<i>[ \t]*)df\s*=\s*_pd\.read_csv\(\s*args\.results\s*\)\s*$', re.M)
REPL = (
    "{i}_res = None\n"
    "{i}try:\n"
    "{i}    _res = args.results\n"
    "{i}except Exception:\n"
    "{i}    import sys as _sys\n"
    "{i}    for _j,_a in enumerate(_sys.argv):\n"
    '{i}        if _a == "--results" and _j+1 < len(_sys.argv):\n'
    "{i}            _res = _sys.argv[_j+1]\n"
    "{i}            break\n"
    '{i}if _res is None:\n'
    '{i}    raise RuntimeError("Cannot infer --results (no args and no --results in argv)")\n'
    "{i}df = _pd.read_csv(_res)"
)

def patch(p: Path):
    txt = p.read_text(encoding="utf-8")
    def _sub(m): return REPL.format(i=m.group('i'))
    new = PAT.sub(_sub, txt)
    if new != txt:
        bak = p.with_suffix(p.suffix + ".bak2")
        if not bak.exists():
            bak.write_text(txt, encoding="utf-8")
        p.write_text(new, encoding="utf-8")
        print(f"[PATCH] {p}: df guard renforcé")
    else:
        print(f"[OK   ] {p}: rien à faire (ligne cible introuvable)")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("usage: patch_df_guard_v2.py FILE [FILE...]", file=sys.stderr); sys.exit(2)
    for a in sys.argv[1:]:
        p = Path(a)
        if not p.exists():
            print(f"[SKIP ] not found: {p}")
            continue
        patch(p)
