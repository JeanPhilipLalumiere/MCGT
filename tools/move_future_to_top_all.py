#!/usr/bin/env python3
from pathlib import Path

def process(p: Path) -> bool:
    s = p.read_text(encoding="utf-8")
    lines = s.splitlines(True)

    # toutes les lignes "from __future__ import ..."
    fut_idx = [i for i, l in enumerate(lines) if l.lstrip().startswith("from __future__ import")]
    if not fut_idx:
        return False

    # position d'insertion après shebang / blancs / docstring
    i = 0
    if i < len(lines) and lines[i].startswith("#!"):
        i += 1
    while i < len(lines) and lines[i].strip() == "":
        i += 1
    if i < len(lines) and lines[i].lstrip().startswith(("'''", '"""')):
        q = lines[i].lstrip()[:3]
        i += 1
        while i < len(lines):
            if lines[i].strip().endswith(q):
                i += 1
                break
            i += 1

    head = lines[:i]
    fut_lines = [lines[j] for j in fut_idx]
    # on enlève les futures du "reste" à partir de i (et seulement cette portion)
    rest_wo_fut = [l for k, l in enumerate(lines) if k >= i and k not in fut_idx]

    out = head + fut_lines + rest_wo_fut
    if out != lines:
        p.write_text("".join(out), encoding="utf-8")
        return True
    return False

def main():
    changed = 0
    for p in Path("zz-scripts").rglob("*.py"):
        try:
            if process(p):
                changed += 1
        except Exception:
            # on ignore les fichiers problématiques pour ne pas stopper le batch
            pass
    print(f"[OK] future-import moved in {changed} file(s)")

if __name__ == "__main__":
    main()
