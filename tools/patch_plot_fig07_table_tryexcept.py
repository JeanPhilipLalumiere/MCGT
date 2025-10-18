#!/usr/bin/env python3
from pathlib import Path

p = Path("zz-scripts/chapter10/plot_fig07_synthesis.py")
src = p.read_text(encoding="utf-8")

needle = "ax_tab.table("
i = src.find(needle)
if i == -1:
    print("[SKIP] ax_tab.table(...) introuvable")
    raise SystemExit(0)

# Trouve la fin de l'appel (parenthèses équilibrées)
j = i
depth = 0
in_str = None
while j < len(src):
    c = src[j]
    if in_str:
        if c == in_str and src[j-1] != "\\":
            in_str = None
    else:
        if c in ("'", '"'):
            in_str = c
        elif c == "(":
            depth += 1
        elif c == ")":
            depth -= 1
            if depth == 0:
                j += 1  # inclure ')'
                break
    j += 1

call_block = src[i:j]
# indent de la ligne
line_start = src.rfind("\n", 0, i) + 1
indent = src[line_start:i]

wrapped = (
    f"{indent}try:\n"
    f"{indent}    {call_block.strip()}\n"
    f"{indent}except IndexError:\n"
    f"{indent}    # table vide -> on saute proprement\n"
    f"{indent}    pass\n"
)

dst = src[:line_start] + wrapped + src[j:]
if dst != src:
    p.write_text(dst, encoding="utf-8")
    print("[OK] patched: ax_tab.table(...) protégé par try/except")
else:
    print("[SKIP] rien changé")
