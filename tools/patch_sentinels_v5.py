#!/usr/bin/env python3
from __future__ import annotations
import re, sys
from pathlib import Path

SENTINELS = [
    Path("zz-scripts/chapter07/plot_fig04_dcs2_vs_k.py"),
    Path("zz-scripts/chapter10/plot_fig05_hist_cdf_metrics.py"),
    Path("zz-scripts/chapter04/plot_fig02_invariants_histogram.py"),
    Path("zz-scripts/chapter03/plot_fig01_fR_stability_domain.py"),
]

RX_MAIN      = re.compile(r'(?m)^\s*def\s+main\s*\(')
RX_ADDARG    = re.compile(r'(?m)^\s*(?:p|_p|ap|parser)\.add_argument\s*\((?P<rest>.*)\)\s*$')
RX_COMMON    = re.compile(r'(?m)^\s*C\.add_common_plot_args\s*\(\s*(?:p|_p|ap|parser)\s*\)\s*$')
RX_ORPH_DOT  = re.compile(r'(?m)^\s*\.\s*ArgumentParser\s*\(')
RX_PARSE_TOP = re.compile(r'(?m)^\s*args\s*=\s*\w+\s*\.parse_args\s*\(\s*\)\s*$')
RX_BUILD_DEF = re.compile(r'(?m)^\s*def\s+build_parser\s*\([^)]*\)\s*:\s*$')
RX_NEXT_BLOCK= re.compile(r'(?m)^\s*(?:def\s+\w+\s*\(|if\s+__name__\s*==\s*["\']__main__["\'])')
RX_PASS5     = re.compile(r'(?m)^\s*#\s*===\s*\[(?:PASS5|PASS5B)[^]]*\]\s*===.*?(?:^\s*#\s*===\s*\[/\s*(?:PASS5|PASS5B)[^]]*\]\s*===\s*$|\Z)', re.S)

def collect_addargs(txt: str) -> list[str]:
    seen, out = set(), []
    for m in RX_ADDARG.finditer(txt):
        r = m.group('rest').strip()
        if r.startswith('#'):  # déjà commenté
            continue
        # micro-fix: ", )" → ")"
        r = re.sub(r',\s*\)$', ')', r)
        r = re.sub(r'description\s*=\s*["\']\([Aa]utofix\)["\']\s*,\s*,', 'description="(autofix)",', r)
        key = r.replace(' ', '')
        if key not in seen:
            seen.add(key)
            out.append(f'    p.add_argument({r})')
    return out

HEADER = """#!/usr/bin/env python3
from __future__ import annotations
import os, sys, pathlib, argparse
import numpy as np, pandas as pd
import matplotlib.pyplot as plt
# bootstrap pour _common.cli
try:
    from _common import cli as C
except Exception:
    sys.path.append(str(pathlib.Path(__file__).resolve().parents[1]))
    from _common import cli as C
"""

TEMPLATE_BP = """
def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="(autofix)")
    C.add_common_plot_args(p)
{addargs}    return p

"""

def nuke_preamble_and_write_clean(p: Path) -> bool:
    s0 = p.read_text(encoding='utf-8', errors='replace')

    # Nettoyage préliminaire pour faciliter la coupe
    s = RX_PASS5.sub('', s0)
    s = RX_ORPH_DOT.sub('# [autofix] .ArgumentParser(', s)
    s = RX_PARSE_TOP.sub('# [autofix] moved to main(): parse_args()', s)

    # Supprimer tous les anciens build_parser()
    while True:
        m = RX_BUILD_DEF.search(s)
        if not m: break
        m2 = RX_NEXT_BLOCK.search(s, m.end())
        s = s[:m.start()] + (s[m2.start():] if m2 else '')

    # Trouver le début de main()
    mm = RX_MAIN.search(s)
    if not mm:
        # Pas de main : fallback — on insère au tout début
        body_rest = s
    else:
        body_rest = s[mm.start():]

    # Collecte des add_argument AVANT de couper le préambule
    addargs = collect_addargs(s0)
    block_args = ''.join(a + ('' if a.endswith('\n') else '\n') for a in addargs)

    new_head = HEADER + TEMPLATE_BP.format(addargs=block_args)
    new = new_head + body_rest.lstrip()

    if new != s0:
        p.write_text(new, encoding='utf-8')
        print("[patched-clean]", p)
        return True
    return False

def main():
    changed = False
    for f in SENTINELS:
        if not f.exists():
            print("[missing]", f); continue
        changed |= nuke_preamble_and_write_clean(f)
    print("Done." + (" (changed)" if changed else ""))
if __name__ == "__main__":
    main()
