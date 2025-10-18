#!/usr/bin/env python3
from pathlib import Path

p = Path("zz-scripts/chapter10/plot_fig07_synthesis.py")
src = p.read_text(encoding="utf-8")

# 1) Clean up any leftovers from older patches like "table = try:"
src = src.replace("table = try:", "try:")

def wrap_one_call(s: str, start_pos: int) -> tuple[str, int]:
    """
    Replace the whole line containing ax_tab.table(...) with a safe try/except block.
    Returns (new_src, next_search_pos).
    """
    call_idx = start_pos
    # Start of line / indentation (tabs or spaces only)
    bol = s.rfind("\n", 0, call_idx) + 1
    # Find end of the call by balancing parentheses
    j, depth, in_str = call_idx, 0, None
    while j < len(s):
        c = s[j]
        if in_str:
            if c == in_str and s[j-1] != "\\":
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

    # Include the trailing newline if present
    if j < len(s) and s[j:j+1] != "\n":
        # consume until end of line
        while j < len(s) and s[j] != "\n":
            j += 1
        if j < len(s) and s[j] == "\n":
            j += 1

    line_prefix = s[bol:call_idx]          # everything before 'ax_tab.table(' on that line
    # real indentation (only whitespace at the start of the line)
    indent = line_prefix[:len(line_prefix) - len(line_prefix.lstrip(" \t"))]

    call_text = s[call_idx:j].strip()      # ax_tab.table(...)
    wrapped = (
        f"{indent}try:\n"
        f"{indent}    table = {call_text}\n"
        f"{indent}except IndexError:\n"
        f"{indent}    # Tableau vide -> ignorer l'annotation\n"
        f"{indent}    table = None\n"
    )
    s = s[:bol] + wrapped + s[j:]
    return s, bol + len(wrapped)

# 2) Wrap ALL occurrences (in case there are more than one)
needle = "ax_tab.table("
pos = 0
changed = False
while True:
    idx = src.find(needle, pos)
    if idx == -1:
        break
    src, pos = wrap_one_call(src, idx)
    changed = True

if changed:
    p.write_text(src, encoding="utf-8")
    print("[OK] patched: all ax_tab.table(...) wrapped with try/except (v4)")
else:
    print("[SKIP] no ax_tab.table(...) found or nothing changed")
