#!/usr/bin/env python3
import sys, re
from pathlib import Path

IF_FALSE = re.compile(r'^(\s*)if\s+False\s*:\s*$')

def patch(p: Path) -> bool:
    txt = p.read_text(encoding="utf-8").splitlines(True)
    changed = False
    for i, line in enumerate(txt):
        m = IF_FALSE.match(line)
        if m and m.group(1):  # il y a une indentation -> on la retire
            txt[i] = "if False:\n"
            changed = True
    if changed:
        bak = p.with_suffix(p.suffix + ".bak_dedent_iffalse")
        if not bak.exists():
            bak.write_text("".join(txt), encoding="utf-8")  # on sauvegarde l'état modifié pour référence
        p.write_text("".join(txt), encoding="utf-8")
    return changed

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("usage: dedent_if_false_lines.py FILE [FILE...]", file=sys.stderr)
        sys.exit(2)
    for a in sys.argv[1:]:
        path = Path(a)
        if not path.exists():
            print(f"[SKIP] not found: {path}")
            continue
        print(f"[PATCH] {'changed' if patch(path) else 'nochange'} → {path}")
