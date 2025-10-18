#!/usr/bin/env python3
from pathlib import Path

ROOTS = ["zz-scripts"]

TRIGS = (
    "parser.add_argument(",
    "parser.set_defaults(",
    "args = parser.parse_args(",
)

def needed_indent(prev_nonempty: str) -> str:
    # récupère l'indentation (espaces/tabs) de la ligne précédente non vide
    return prev_nonempty[:len(prev_nonempty) - len(prev_nonempty.lstrip('\t '))]

def should_fix(line: str) -> bool:
    if line.startswith((" ", "\t")):
        return False  # déjà indenté
    ls = line.lstrip()
    return any(ls.startswith(t) for t in TRIGS)

def process(p: Path) -> bool:
    txt = p.read_text(encoding="utf-8", errors="ignore")
    lines = txt.splitlines(True)

    changed = False
    last_code = ""  # dernière ligne non vide (garde indentation de contexte)
    for i, ln in enumerate(lines):
        if ln.strip():  # non vide
            if should_fix(ln):
                indent = needed_indent(last_code) if last_code else ""
                if indent:
                    lines[i] = indent + ln  # réinjecte l'indentation du contexte
                    changed = True
            last_code = ln

    if changed:
        bak = p.with_suffix(p.suffix + ".bak_reindent")
        if not bak.exists():
            bak.write_text(txt, encoding="utf-8")
        p.write_text("".join(lines), encoding="utf-8")
    return changed

def main():
    fixed = 0
    for root in ROOTS:
        for p in Path(root).rglob("*.py"):
            try:
                if process(p):
                    fixed += 1
            except Exception:
                pass
    print(f"[OK] re-indented argparse lines in {fixed} file(s)")

if __name__ == "__main__":
    main()
