#!/usr/bin/env python3
import re, sys
from pathlib import Path

PAT = re.compile(
    r'^(?P<indent>[ \t]*)df\s*=\s*ci\.ensure_fig02_cols\(\s*df\s*\)\s*$',
    re.M
)

REPL = (
    "{i}try:\n"
    "{i}    df\n"
    "{i}except NameError:\n"
    "{i}    import pandas as _pd\n"
    "{i}    df = _pd.read_csv(args.results)\n"
    "{i}df = ci.ensure_fig02_cols(df)"
)

def patch_file(p: Path) -> bool:
    text = p.read_text(encoding="utf-8")
    def _sub(m):
        i = m.group("indent")
        return REPL.format(i=i)
    new = PAT.sub(_sub, text)
    if new != text:
        bak = p.with_suffix(p.suffix + ".bak")
        if not bak.exists():
            bak.write_text(text, encoding="utf-8")
        p.write_text(new, encoding="utf-8")
        print(f"[PATCH] {p}: df guard inséré")
        return True
    else:
        print(f"[OK   ] {p}: rien à faire (guard déjà présent ou pattern introuvable)")
        return False

def main(argv):
    if len(argv) < 2:
        print("usage: patch_df_guard.py FILE [FILE...]", file=sys.stderr)
        return 2
    changed = False
    for a in argv[1:]:
        p = Path(a)
        if not p.exists():
            print(f"[SKIP ] not found: {p}")
            continue
        changed |= patch_file(p)
    return 0 if True else 1

if __name__ == "__main__":
    sys.exit(main(sys.argv))
