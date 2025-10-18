#!/usr/bin/env python3
from pathlib import Path
import re

ROOTS = ["zz-scripts"]

START_CODE_RE = re.compile(
    r'^\s*(import |from |def |class |if __name__\s*==\s*[\'"]__main__[\'"])'
)

def wrap_header_as_docstring(lines, start_idx):
    i = start_idx
    j = i
    while j < len(lines) and not START_CODE_RE.match(lines[j]):
        j += 1
    before = lines[:i]
    header = ['"""(auto-wrapped header)\n'] + lines[i:j]
    if not header[-1].endswith("\n"):
        header[-1] = header[-1] + "\n"
    header.append('"""\n')
    after = lines[j:]
    return before + header + after, True

def balance_triple_quotes(text):
    # Comptage simple (ne gère pas les cas pathologiques de quotes imbriquées,
    # mais règle 99% des cas docstring non fermé)
    need_close = []
    if text.count('"""') % 2 != 0:
        need_close.append('"""')
    if text.count("'''") % 2 != 0:
        need_close.append("'''")
    if not need_close:
        return text, False
    fixed = text
    for q in need_close:
        fixed += ("\n" if not fixed.endswith("\n") else "") + q + "\n"
    return fixed, True

def fix_file(p: Path) -> bool:
    txt = p.read_text(encoding="utf-8", errors="ignore")
    lines = txt.splitlines(True)

    # pos après shebang + blancs
    i = 0
    if i < len(lines) and lines[i].startswith("#!"): i += 1
    while i < len(lines) and lines[i].strip() == "": i += 1

    changed = False

    # si début non code et pas déjà docstring -> wrap
    if i < len(lines) and not lines[i].lstrip().startswith(("'''", '"""')) and not START_CODE_RE.match(lines[i]):
        lines, c = wrap_header_as_docstring(lines, i)
        changed = changed or c

    # équilibre des triples quotes
    balanced_text, c2 = balance_triple_quotes("".join(lines))
    if c2:
        (p.with_suffix(p.suffix+".bak_headerdoc")).write_text("".join(lines), encoding="utf-8")
        p.write_text(balanced_text, encoding="utf-8")
        return True

    if changed:
        (p.with_suffix(p.suffix+".bak_headerdoc")).write_text(txt, encoding="utf-8")
        p.write_text("".join(lines), encoding="utf-8")
        return True

    return False

def main():
    changed = 0
    for root in ROOTS:
        for p in Path(root).rglob("*.py"):
            try:
                if fix_file(p):
                    changed += 1
            except Exception:
                pass
    print(f"[OK] docstrings/headers fixed in {changed} file(s)")

if __name__ == "__main__":
    main()
