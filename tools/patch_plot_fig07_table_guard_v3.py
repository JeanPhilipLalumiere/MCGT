#!/usr/bin/env python3
from pathlib import Path

p = Path("zz-scripts/chapter10/plot_fig07_synthesis.py")
src = p.read_text(encoding="utf-8")

call_idx = src.find("ax_tab.table(")
if call_idx == -1:
    print("[SKIP] ax_tab.table(...) introuvable")
    raise SystemExit(0)

# Début de ligne / indentation réelle (espaces/tabs uniquement)
bol = src.rfind("\n", 0, call_idx) + 1
line_prefix = src[bol:call_idx]
indent = line_prefix[:len(line_prefix) - len(line_prefix.lstrip(" \t"))]

# Fin de l'appel (parenthèses équilibrées)
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

call_text = src[call_idx:j].strip()  # "ax_tab.table(...)"

wrapped = (
    f"{indent}try:\n"
    f"{indent}    table = {call_text}\n"
    f"{indent}except IndexError:\n"
    f"{indent}    # tableau vide -> ignorer l'annotation\n"
    f"{indent}    table = None\n"
)

dst = src[:bol] + wrapped + src[j:]
if dst != src:
    p.write_text(dst, encoding="utf-8")
    print("[OK] patched: ax_tab.table(...) protégé par try/except (v3)")
else:
    print("[SKIP] rien changé")
