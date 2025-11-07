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

# --- repères/regex robustes --------------------------------------------------
RX_SHEBANG   = re.compile(r'^#!.*\n?')
RX_ENCODING  = re.compile(r'^[ \t]*#.*coding[:=].*\n', re.M)
RX_FUTURE    = re.compile(r'^\s*from\s+__future__\s+import\s+[^\n]+$', re.M)

RX_HAVE_ARGPARSE = re.compile(r'^\s*import\s+argparse\b', re.M)
RX_HAVE_C        = re.compile(r'^\s*from\s+_common\s+import\s+cli\s+as\s+C\b', re.M)

RX_BUILD_HDR = re.compile(r'^(\s*)def\s+build_parser\s*\([^)]*\)\s*:\s*$', re.M)
RX_NEXT_DEF_OR_MAIN = re.compile(r'^\s*(?:def\s+\w+\s*\(|if\s+__name__\s*==\s*["\']__main__["\'])', re.M)

RX_TL_PARSER_START = re.compile(r'^(?P<ind>\s*)(?P<var>p|_p|ap|parser)\s*=\s*argparse\.ArgumentParser\s*\(', re.M)
RX_TL_PARSE_ARGS   = re.compile(r'^\s*args\s*=\s*\w+\s*\.parse_args\s*\(\s*\)\s*$', re.M)
RX_DOT_ARGUMENTPARSER = re.compile(r'(?m)^\s*\.\s*ArgumentParser\s*\(')

RX_ADDARG_ANY  = re.compile(r'^\s*(?:p|_p|ap|parser)\.add_argument\s*\((?P<rest>.*)\)\s*$', re.M)
RX_COMMON_ADD  = re.compile(r'^\s*C\.add_common_plot_args\s*\(\s*(?:p|_p|ap|parser)\s*\)\s*$', re.M)

RX_PASS5_OPEN  = re.compile(r'^\s*#\s*===\s*\[(?:PASS5|PASS5B)[^]]*\]\s*===\s*$', re.M)
RX_PASS5_CLOSE = re.compile(r'^\s*#\s*===\s*\[/\s*(?:PASS5|PASS5B)[^]]*\]\s*===\s*$', re.M)

# petites réparations syntaxiques
RX_DBL_COMMA_DESC = re.compile(r'description\s*=\s*["\']\([Aa]utofix\)["\']\s*,\s*,')
RX_COMMA_PAREN    = re.compile(r',\s*\)')

TEMPLATE = """def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="(autofix)")
    C.add_common_plot_args(p)
{addargs}    return p
"""

def ensure_header(txt: str) -> str:
    she = RX_SHEBANG.match(txt); prefix = she.group(0) if she else ''
    rest = txt[len(prefix):]
    enc = RX_ENCODING.match(rest); encs = enc.group(0) if enc else ''
    body = rest[len(encs):]

    futures = RX_FUTURE.findall(body)
    body = RX_FUTURE.sub('', body)

    head = []
    if prefix: head.append(prefix)
    if encs: head.append(encs)
    for f in futures:
        head.append(f if f.endswith('\n') else f + '\n')
    if not RX_HAVE_ARGPARSE.search(body): head.append('import argparse\n')
    if not RX_HAVE_C.search(body):        head.append('from _common import cli as C\n')
    return ''.join(head) + body.lstrip()

def comment_block(lines: list[str], start_i: int) -> int:
    """commente depuis start_i (ligne ouvrante) jusqu'à fermeture parenthèses"""
    depth = 0
    i = start_i
    # première ligne
    depth += lines[i].count('(') - lines[i].count(')')
    lines[i] = '# [autofix] moved: ' + lines[i]
    i += 1
    while i < len(lines):
        depth += lines[i].count('(') - lines[i].count(')')
        lines[i] = '# ' + lines[i]
        if depth <= 0:
            return i + 1
        i += 1
    return i

def comment_top_level_glue(txt: str) -> str:
    # 1) commente tout bloc p = argparse.ArgumentParser( … ) au top-level
    lines = txt.splitlines(True)
    i = 0
    while i < len(lines):
        if RX_TL_PARSER_START.match(lines[i]):
            i = comment_block(lines, i); continue
        if RX_TL_PARSE_ARGS.match(lines[i]):
            lines[i] = '# [autofix] args=parse_args() moved into main()\n'
        i += 1
    txt = ''.join(lines)
    # 2) commente les ".ArgumentParser(" orphelins
    txt = RX_DOT_ARGUMENTPARSER.sub('# [autofix] .ArgumentParser(', txt)
    # 3) commente tout C.add_common_plot_args(...) qui traîne au top-level
    txt = RX_COMMON_ADD.sub('# [autofix] moved: C.add_common_plot_args(p)', txt)
    return txt

def comment_pass5_shims(txt: str) -> str:
    lines = txt.splitlines(True)
    out = []
    in_shim = False
    for ln in lines:
        if RX_PASS5_OPEN.match(ln):
            in_shim = True
            out.append(('# ' + ln) if not ln.startswith('#') else ln)
            continue
        if in_shim:
            out.append('# ' + ln if not ln.startswith('#') else ln)
            if RX_PASS5_CLOSE.match(ln):
                in_shim = False
            continue
        out.append(ln)
    return ''.join(out)

def strip_all_build_parser(txt: str) -> str:
    # supprime toutes les définitions existantes de build_parser()
    while True:
        m = RX_BUILD_HDR.search(txt)
        if not m:
            break
        start = m.start()
        m2 = RX_NEXT_DEF_OR_MAIN.search(txt, m.end())
        end = m2.start() if m2 else len(txt)
        txt = txt[:start] + txt[end:]
    return txt

def collect_addargs(raw_txt: str) -> list[str]:
    addargs = []
    seen = set()
    for m in RX_ADDARG_ANY.finditer(raw_txt):
        rest = m.group('rest').strip()
        # ignorer les rest déjà commentés
        if rest.startswith('#'):
            continue
        # micro-fix évidents sur rest
        r = RX_DBL_COMMA_DESC.sub('description="(autofix)",', rest)
        r = RX_COMMA_PAREN.sub(')', r)
        key = r.replace(' ', '')
        if key not in seen:
            seen.add(key)
            addargs.append(f'    p.add_argument({r})')
    return addargs

def tiny_fixes(txt: str) -> str:
    txt = RX_DBL_COMMA_DESC.sub('description="(autofix)",', txt)
    txt = RX_COMMA_PAREN.sub(')', txt)
    return txt

def insert_fresh_build_parser(txt: str, addargs: list[str]) -> str:
    block = ''.join(a + ('' if a.endswith('\n') else '\n') for a in addargs)
    ins = TEMPLATE.format(addargs=block)
    m2 = RX_NEXT_DEF_OR_MAIN.search(txt)
    if m2:
        return txt[:m2.start()] + ins + '\n' + txt[m2.start():]
    return (txt.rstrip('\n') + '\n\n' + ins + '\n')

def patch_file(p: Path) -> bool:
    s0 = p.read_text(encoding='utf-8', errors='replace')

    # collecte des add_argument AVANT de commenter/supprimer
    addargs = collect_addargs(s0)

    s = ensure_header(s0)
    s = comment_pass5_shims(s)
    s = comment_top_level_glue(s)
    s = strip_all_build_parser(s)
    s = insert_fresh_build_parser(s, addargs)
    s = tiny_fixes(s)

    if s != s0:
        p.write_text(s, encoding='utf-8')
        print("[patched]", p)
        return True
    return False

def main():
    changed = False
    for f in SENTINELS:
        if f.exists():
            changed |= patch_file(f)
        else:
            print("[missing]", f)
    print("Done." + (" (changed)" if changed else ""))
if __name__ == "__main__":
    main()
