#!/usr/bin/env python3
from pathlib import Path

FILES = [
    Path("zz-scripts/chapter10/plot_fig03b_bootstrap_coverage_vs_n.py"),
    Path("zz-scripts/chapter10/plot_fig06_residual_map.py"),
]

BLOCK = (
    "# --- compat: argparse parse-hook extras v5 ---\n"
    "import argparse as _ap\n"
    "def _v5_fill(ns):\n"
    "    # compléments uniformes si absents\n"
    "    if not hasattr(ns, 'p95_col'): ns.p95_col = None\n"
    "    if not hasattr(ns, 'm1_col'):  ns.m1_col  = 'phi0'\n"
    "    if not hasattr(ns, 'm2_col'):  ns.m2_col  = 'phi_ref_fpeak'\n"
    "    return ns\n"
    "if not hasattr(_ap.ArgumentParser, '_v5_orig_parse_args'):\n"
    "    _ap.ArgumentParser._v5_orig_parse_args = _ap.ArgumentParser.parse_args\n"
    "    def _v5_parse_args(self, *a, **k):\n"
    "        return _v5_fill(self._v5_orig_parse_args(*a, **k))\n"
    "    _ap.ArgumentParser.parse_args = _v5_parse_args\n"
    "if not hasattr(_ap.ArgumentParser, '_v5_orig_parse_known_args'):\n"
    "    _ap.ArgumentParser._v5_orig_parse_known_args = _ap.ArgumentParser.parse_known_args\n"
    "    def _v5_parse_known_args(self, *a, **k):\n"
    "        ns, unk = self._v5_orig_parse_known_args(*a, **k)\n"
    "        return _v5_fill(ns), unk\n"
    "    _ap.ArgumentParser.parse_known_args = _v5_parse_known_args\n"
    "try:\n"
    "    args  # noqa: F821\n"
    "except NameError:\n"
    "    pass\n"
    "else:\n"
    "    args = _v5_fill(args)\n"
    "# --- end compat: argparse parse-hook extras v5 ---\n"
)

START_SENT = "# --- compat: argparse parse-hook extras v5 ---"

def insert_after_imports(path: Path, block: str) -> bool:
    s = path.read_text(encoding="utf-8")
    if START_SENT in s:
        return False
    lines = s.splitlines(True)
    i = 0
    # shebang
    if i < len(lines) and lines[i].startswith("#!"): i += 1
    # blanks & comments
    while i < len(lines) and (lines[i].strip()=="" or lines[i].lstrip().startswith("#")): i += 1
    # optional module docstring
    if i < len(lines) and lines[i].lstrip().startswith(("'''", '\"\"\"')):
        q = lines[i].lstrip()[:3]; i += 1
        while i < len(lines):
            if lines[i].strip().endswith(q): i += 1; break
            i += 1
    # __future__ imports
    while i < len(lines) and lines[i].lstrip().startswith("from __future__ import"): i += 1
    # normal imports
    last = i
    while i < len(lines) and lines[i].lstrip().startswith(("import ", "from ")):
        last = i + 1; i += 1
    lines.insert(last, block)
    path.write_text("".join(lines), encoding="utf-8")
    return True

if __name__ == "__main__":
    changed = False
    for f in FILES:
        if insert_after_imports(f, BLOCK):
            print(f"[PATCH] v5 parse-hook inserted -> {f}")
            changed = True
        else:
            print(f"[OK] v5 parse-hook already present -> {f}")
    if not changed:
        print("[NOTE] nothing to change")
