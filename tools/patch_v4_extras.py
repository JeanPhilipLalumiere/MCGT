#!/usr/bin/env python3
from pathlib import Path

FILES = [
    Path("zz-scripts/chapter10/plot_fig03b_bootstrap_coverage_vs_n.py"),
    Path("zz-scripts/chapter10/plot_fig06_residual_map.py"),
]

BLOCK = (
    "# --- compat: argparse post-parse extras for v4 ---\n"
    "try:\n"
    "    args  # noqa: F821\n"
    "except NameError:\n"
    "    pass\n"
    "else:\n"
    "    # Uniform defaults if parser didn't create these attrs\n"
    "    if not hasattr(args, 'p95_col'): args.p95_col = None\n"
    "    if not hasattr(args, 'm1_col'):  args.m1_col  = 'phi0'\n"
    "    if not hasattr(args, 'm2_col'):  args.m2_col  = 'phi_ref_fpeak'\n"
    "# --- end compat: argparse post-parse extras for v4 ---\n"
)

START = "# --- compat: argparse post-parse shim v4 ---"
END   = "# --- end compat: argparse post-parse shim v4 ---"
SENTINEL = "# --- compat: argparse post-parse extras for v4 ---"

def patch_one(p: Path) -> bool:
    s = p.read_text(encoding="utf-8")
    if SENTINEL in s:
        return False
    lines = s.splitlines(True)
    # trouve la fin du bloc v4
    end_ix = None
    for i, line in enumerate(lines):
        if line.strip() == END:
            end_ix = i
    if end_ix is None:
        return False
    lines.insert(end_ix+1, BLOCK)
    p.write_text("".join(lines), encoding="utf-8")
    return True

if __name__ == "__main__":
    changed = False
    for f in FILES:
        if patch_one(f):
            print(f"[PATCH] extras added -> {f}")
            changed = True
        else:
            print(f"[OK] extras already present -> {f}")
    if not changed:
        print("[NOTE] nothing to change")
