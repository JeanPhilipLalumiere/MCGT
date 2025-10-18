#!/usr/bin/env python3
from pathlib import Path

def insert_after_imports(path: Path, block: str, sentinel: str) -> bool:
    s = path.read_text(encoding="utf-8")
    if sentinel in s:
        return False
    lines = s.splitlines(True)
    i = 0
    # shebang
    if i < len(lines) and lines[i].startswith("#!"):
        i += 1
    # blanks & comments
    while i < len(lines) and (lines[i].strip() == "" or lines[i].lstrip().startswith("#")):
        i += 1
    # optional module docstring
    if i < len(lines) and lines[i].lstrip().startswith(("'''", '\"\"\"')):
        q = lines[i].lstrip()[:3]; i += 1
        while i < len(lines):
            if lines[i].strip().endswith(q):
                i += 1
                break
            i += 1
    # __future__ imports
    while i < len(lines) and lines[i].lstrip().startswith("from __future__ import"):
        i += 1
    # regular imports (import/from) — on s'arrête dès que ce n'est plus un import
    last = i
    while i < len(lines) and lines[i].lstrip().startswith(("import ", "from ")):
        last = i + 1
        i += 1
    lines.insert(last, block)
    path.write_text("".join(lines), encoding="utf-8")
    return True

# fig03b: assurer args.p95_col (None => auto-détection)
f03b = Path("zz-scripts/chapter10/plot_fig03b_bootstrap_coverage_vs_n.py")
b03b = (
    "\n# --- compat: ensure args.p95_col exists ---\n"
    "if 'args' in globals() and not hasattr(args, 'p95_col'):\n"
    "    args.p95_col = None  # trigger detect_p95_column(...)\n"
)
insert_after_imports(f03b, b03b, "compat: ensure args.p95_col")

# fig06: assurer args.m1_col / args.m2_col
f06  = Path("zz-scripts/chapter10/plot_fig06_residual_map.py")
b06  = (
    "\n# --- compat: ensure args.m1_col/m2_col exist ---\n"
    "if 'args' in globals() and not hasattr(args, 'm1_col'):\n"
    "    args.m1_col = 'phi0'\n"
    "if 'args' in globals() and not hasattr(args, 'm2_col'):\n"
    "    args.m2_col = 'phi_ref_fpeak'\n"
)
insert_after_imports(f06, b06, "compat: ensure args.m1_col/m2_col")

print("[OK] fallbacks inserted (idempotent)")
