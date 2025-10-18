#!/usr/bin/env python3
from pathlib import Path

p = Path("zz-scripts/chapter10/plot_fig07_synthesis.py")
src = p.read_text(encoding="utf-8")

# Locate the ax_tab.table( call
call = "ax_tab.table("
idx = src.find(call)
if idx < 0:
    print("[SKIP] ax_tab.table(...) not found")
    raise SystemExit(0)

# Compute indentation where the call currently sits
bol_call = src.rfind("\n", 0, idx) + 1
indent = src[bol_call:idx]  # whitespace before 'a' in ax_tab.table(

# Find the start of the try block to replace (crawl back over stacked 'try:' lines if present)
import re
try_re = re.compile(r'^[ \t]*try:\s*$', re.M)

start = bol_call
# look back up to ~8 lines for a 'try:'; if multiple consecutive, grab the first of the run
scan_start = max(0, bol_call - 2000)
prev_chunk = src[scan_start:bol_call]
tries = list(try_re.finditer(prev_chunk))
if tries:
    # take the last 'try:' before call, then walk back to include any directly preceding 'try:' lines
    t = tries[-1]
    start = scan_start + t.start()
    # Walk back over contiguous 'try:' lines
    while True:
        prev_prev = prev_chunk.rfind("\n", 0, t.start()) + 1
        if prev_prev <= 0:
            break
        m = try_re.match(prev_chunk, prev_prev)
        if not m:
            break
        t = m
        start = scan_start + t.start()

# Find the end of the ax_tab.table(...) call by balancing parentheses
j = idx
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

# Extend to include any following except blocks / table=None lines / blank lines
end = j
while end < len(src):
    line_end = src.find("\n", end)
    if line_end == -1:
        line_end = len(src)
    line = src[end:line_end]
    stripped = line.lstrip()
    if stripped.startswith("except ") or stripped.startswith("except:") \
       or stripped.startswith("#") or stripped == "" \
       or stripped.startswith("table = None"):
        end = line_end + 1
        continue
    # Stop when we hit a real next statement
    break

# Build the canonical replacement block
block = (
    f"{indent}try:\n"
    f"{indent}    table = ax_tab.table(\n"
    f"{indent}        cellText=cell_text,\n"
    f"{indent}        colLabels=col_labels,\n"
    f"{indent}        cellLoc=\"center\",\n"
    f"{indent}        colLoc=\"center\",\n"
    f"{indent}        loc=\"center\",\n"
    f"{indent}    )\n"
    f"{indent}except IndexError:\n"
    f"{indent}    # Tableau vide -> ignorer l'annotation\n"
    f"{indent}    table = None\n"
)

before = src[:start]
after  = src[end:]
fixed = before + block + after

if fixed != src:
    bak = p.with_suffix(p.suffix + ".bak_tablefix")
    if not bak.exists():
        bak.write_text(src, encoding="utf-8")
    p.write_text(fixed, encoding="utf-8")
    print("[OK] normalized ax_tab.table() try/except block")
else:
    print("[SKIP] nothing changed")
