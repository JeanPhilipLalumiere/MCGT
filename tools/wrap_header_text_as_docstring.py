#!/usr/bin/env python3
from pathlib import Path
import re

ROOTS = ["zz-scripts"]

START_CODE_RE = re.compile(r'^\s*(import |from |def |class |if __name__\s*==\s*[\'"]__main__[\'"])')

def fix_file(p: Path) -> bool:
    txt = p.read_text(encoding="utf-8", errors="ignore")
    lines = txt.splitlines(True)

    # position après shebang et blancs
    i = 0
    if i < len(lines) and lines[i].startswith("#!"):
        i += 1
    while i < len(lines) and lines[i].strip() == "":
        i += 1

    # déjà un docstring ?
    if i < len(lines) and lines[i].lstrip().startswith(("'''", '"""')):
        # vérifie équilibre des triples quotes
        whole = "".join(lines[i:])
        n1 = whole.count("'''")
        n2 = whole.count('"""')
        if (n1 % 2 != 0) or (n2 % 2 != 0):
            # ajoute une fermeture en fin de fichier
            lines.append('"""\n')
            p.with_suffix(p.suffix+".bak_headerdoc").write_text(txt, encoding="utf-8")
            p.write_text("".join(lines), encoding="utf-8")
            return True
        return False

    # si pas de docstring et que le tout début n'est pas du code python "classique"
    if i < len(lines) and not START_CODE_RE.match(lines[i]):
        # trouve le début de code
        j = i
        while j < len(lines) and not START_CODE_RE.match(lines[j]):
            j += 1
        # wrap [i:j] dans un docstring
        before = lines[:i]
        header = ['"""(auto-wrapped header)\n'] + lines[i:j]
        if not header[-1].endswith("\n"):
            header[-1] = header[-1] + "\n"
        header.append('"""\n')
        after = lines[j:]
        new = before + header + after
        p.with_suffix(p.suffix+".bak_headerdoc").write_text(txt, encoding="utf-8")
        p.write_text("".join(new), encoding="utf-8")
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
    print(f"[OK] header/docstring normalized in {changed} file(s)")

if __name__ == "__main__":
    main()
