#!/usr/bin/env python3
from pathlib import Path
import re

def insert_after_imports(path, block, sentinel):
    p = Path(path)
    s = p.read_text(encoding="utf-8")
    if sentinel in s:
        return False
    lines = s.splitlines(True)

    i = 0
    # shebang
    if i < len(lines) and lines[i].startswith("#!"):
        i += 1
    # blank lines
    while i < len(lines) and lines[i].strip() == "":
        i += 1
    # optional module docstring
    if i < len(lines) and lines[i].lstrip().startswith(("'''", '"""')):
        q = lines[i].lstrip()[:3]
        i += 1
        while i < len(lines):
            if lines[i].strip().endswith(q):
                i += 1
                break
            i += 1
    # __future__ imports
    while i < len(lines) and lines[i].lstrip().startswith("from __future__ import"):
        i += 1
    # normal imports
    last = i
    while i < len(lines) and lines[i].lstrip().startswith(("import ", "from ")):
        last = i + 1
        i += 1

    lines.insert(last, block)
    p.write_text("".join(lines), encoding="utf-8")
    return True

def sed_replace(path, pat, repl):
    p = Path(path)
    txt = p.read_text(encoding="utf-8")
    new = re.sub(pat, repl, txt)
    if new != txt:
        p.write_text(new, encoding="utf-8")
        return True
    return False

changed = False

# --- fig03b: add safe fallbacks for ymin/ymax coverage titles/limits
sentinel_03b = "# --- AUTO-FALLBACKS (ch10: fig03b) ---"
block_03b = f"""
{sentinel_03b}
try:
    args
except NameError:
    from argparse import Namespace as _NS
    args = _NS()
if not hasattr(args, 'ymin_coverage'): args.ymin_coverage = None
if not hasattr(args, 'ymax_coverage'): args.ymax_coverage = None
# --- END AUTO-FALLBACKS (ch10: fig03b) ---
"""
changed |= insert_after_imports(
    "zz-scripts/chapter10/plot_fig03b_bootstrap_coverage_vs_n.py",
    block_03b, sentinel_03b
)

# --- fig05: ensure ref_p95 is float
# replace any 'args.ref_p95' occurrences with a safe float() getter
changed |= sed_replace(
    "zz-scripts/chapter10/plot_fig05_hist_cdf_metrics.py",
    r"\bargs\.ref_p95\b",
    'float(getattr(args, "ref_p95", 0.0))'
)

# --- fig06: defaults for mincnt/gridsize/figsize
sentinel_06 = "# --- AUTO-FALLBACKS (ch10: fig06) ---"
block_06 = f"""
{sentinel_06}
try:
    args
except NameError:
    from argparse import Namespace as _NS
    args = _NS()
if not hasattr(args, 'mincnt'): args.mincnt = 1
if not hasattr(args, 'gridsize'): args.gridsize = 60
if not hasattr(args, 'figsize'): args.figsize = '6,5'
# --- END AUTO-FALLBACKS (ch10: fig06) ---
"""
changed |= insert_after_imports(
    "zz-scripts/chapter10/plot_fig06_residual_map.py",
    block_06, sentinel_06
)

print('[OK] patches applied' if changed else '[NOTE] nothing to change')
