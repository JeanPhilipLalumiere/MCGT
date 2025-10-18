#!/usr/bin/env python3
from pathlib import Path

p = Path("zz-scripts/chapter10/plot_fig07_synthesis.py")
src = p.read_text(encoding="utf-8")

# on vise le premier "ax_tab.table(" rencontré
call_idx = src.find("ax_tab.table(")
if call_idx == -1:
    print("[SKIP] ax_tab.table(...) introuvable")
    raise SystemExit(0)

# indentation de la ligne qui contient l'appel
line_start = src.rfind("\n", 0, call_idx) + 1
indent = src[line_start:call_idx]  # espaces/tabs précédant 'ax_tab.table('

# retrouve la fermeture de parenthèses
j = call_idx
depth, in_str = 0, None
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
                j += 1
                break
    j += 1

call_text = src[call_idx:j].strip()               # ex: ax_tab.table(...)

# on remplace TOUTE la ligne depuis line_start jusqu'à la fin de l'appel
wrapped = (
    f"{indent}try:\n"
    f"{indent}    table = {call_text}\n"
    f"{indent}except IndexError:\n"
    f"{indent}    # tableau vide -> ignorer\n"
    f"{indent}    table = None\n"
)

dst = src[:line_start] + wrapped + src[j:]
if dst != src:
    p.write_text(dst, encoding="utf-8")
    print("[OK] patched: ax_tab.table(...) protégé par try/except")
else:
    print("[SKIP] rien changé")
