#!/usr/bin/env python3
from __future__ import annotations
import re
from pathlib import Path

SENTINELS = [
    Path("zz-scripts/chapter07/plot_fig04_dcs2_vs_k.py"),
    Path("zz-scripts/chapter10/plot_fig05_hist_cdf_metrics.py"),
    Path("zz-scripts/chapter04/plot_fig02_invariants_histogram.py"),
    Path("zz-scripts/chapter03/plot_fig01_fR_stability_domain.py"),
]

RX_BUILD_HDR      = re.compile(r'^(\s*)def\s+build_parser\s*\([^)]*\)\s*:\s*$', re.M)
RX_NEXT_DEF_OR_IF = re.compile(r'^\s*def\s+\w+\s*\(|^\s*if\s+__name__\s*==\s*["\']__main__["\']\s*:', re.M)

# Glue et débris au niveau top-level
RX_BAD_GLUE       = re.compile(r'(?m)^\s*\.\s*ArgumentParser\s*\(')
RX_TL_AP          = re.compile(r'(?m)^(?P<ind>\s*)(?P<var>p|_p|ap|parser)\s*=\s*argparse\.ArgumentParser\s*\(')
RX_TL_PARSE       = re.compile(r'(?m)^\s*args\s*=\s*\w+\s*\.parse_args\s*\(\s*\)\s*$')

# Import guards
RX_HAVE_ARGPARSE  = re.compile(r'^\s*import\s+argparse\b', re.M)
RX_HAVE_C         = re.compile(r'^\s*from\s+_common\s+import\s+cli\s+as\s+C\b', re.M)

# Petites réparations de syntaxe
RX_DBL_COMMA      = re.compile(r'description\s*=\s*["\']\([Aa]utofix\)["\']\s*,\s*,')
RX_COMMA_PAREN    = re.compile(r',\s*\)')

TEMPLATE = """{indent}def build_parser() -> argparse.ArgumentParser:
{indent}    p = argparse.ArgumentParser(description="(autofix)")
{indent}    C.add_common_plot_args(p)
{addargs}{indent}    return p
"""

# add_argument capturés (on normalise la variable vers p)
RX_ADDARG = re.compile(r'^\s*(?P<var>p|_p|ap|parser)\.add_argument\s*\((?P<rest>.*)$', re.M)

def ensure_imports(txt: str) -> str:
    hdr = []
    rest = txt
    # Shebang / encoding en tête conservés
    lines = txt.splitlines(True)
    i = 0
    if lines and lines[0].startswith('#!'):
        hdr.append(lines[0]); i = 1
    if i < len(lines) and 'coding' in lines[i][:40]:
        hdr.append(lines[i]); i += 1
    body = ''.join(lines[i:])

    need_argparse = RX_HAVE_ARGPARSE.search(body) is None
    need_c        = RX_HAVE_C.search(body) is None

    ins = ''
    if need_argparse: ins += 'import argparse\n'
    if need_c:        ins += 'from _common import cli as C\n'
    if ins:
        body = ins + body
    return ''.join(hdr) + body

def rebuild_build_parser(txt: str) -> str:
    m = RX_BUILD_HDR.search(txt)
    if not m:
        # injecte build_parser minimal avant la 1ère def/main
        m2 = RX_NEXT_DEF_OR_IF.search(txt)
        insert_at = m2.start() if m2 else len(txt)
        rebuilt = TEMPLATE.format(indent='', addargs='')
        return txt[:insert_at] + rebuilt + '\n' + txt[insert_at:]

    indent = m.group(1) or ''
    m2 = RX_NEXT_DEF_OR_IF.search(txt, m.end())
    end = m2.start() if m2 else len(txt)
    block = txt[m.end():end]

    addargs_lines = []
    for mm in RX_ADDARG.finditer(block):
        addargs_lines.append(f"{indent}    p.add_argument({mm.group('rest')}")

    addargs = ''
    if addargs_lines:
        addargs = ''.join(l + ("\n" if not l.endswith("\n") else "") for l in addargs_lines)

    rebuilt = TEMPLATE.format(indent=indent, addargs=addargs)
    return txt[:m.start()] + rebuilt + txt[end:]

def neutralize_toplevel(txt: str) -> str:
    # colle "argparse" + ".ArgumentParser(" si le point est seul en début de ligne
    txt = RX_BAD_GLUE.sub('ArgumentParser(', txt)
    # commente toute création d'ArgumentParser au top-level (hors build_parser)
    txt = RX_TL_AP.sub(r'\g<ind># [autofix] moved into build_parser: \g<var> = argparse.ArgumentParser(', txt)
    # supprime args = ....parse_args() au top-level
    txt = RX_TL_PARSE.sub('# [autofix] args=parse_args() moved into main()', txt)
    return txt

def tiny_syntax_fixes(txt: str) -> str:
    txt = RX_DBL_COMMA.sub('description="(autofix)",', txt)
    txt = RX_COMMA_PAREN.sub(')', txt)
    return txt

def patch_one(path: Path) -> bool:
    s0 = path.read_text(encoding='utf-8', errors='replace')
    s  = s0
    s  = neutralize_toplevel(s)
    s  = rebuild_build_parser(s)
    s  = tiny_syntax_fixes(s)
    s  = ensure_imports(s)
    if s != s0:
        path.write_text(s, encoding='utf-8')
        print("[patched]", path)
        return True
    return False

def main():
    changed = 0
    for p in SENTINELS:
        if p.exists():
            changed |= patch_one(p)
        else:
            print("[missing]", p)
    print("Done.")
if __name__ == "__main__":
    main()
