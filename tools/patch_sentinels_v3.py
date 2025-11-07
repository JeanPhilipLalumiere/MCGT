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

# Repères de blocs
RX_BUILD_HDR       = re.compile(r'^(\s*)def\s+build_parser\s*\([^)]*\)\s*:\s*$', re.M)
RX_NEXT_DEF_OR_MAIN= re.compile(r'^\s*(?:def\s+\w+\s*\(|if\s+__name__\s*==\s*["\']__main__["\'])', re.M)

# Imports
RX_SHEBANG         = re.compile(r'^#!.*\n?')
RX_ENCODING        = re.compile(r'^[ \t]*#.*coding[:=].*\n', re.M)
RX_FUTURE          = re.compile(r'^\s*from\s+__future__\s+import\s+[^\n]+$', re.M)
RX_HAVE_ARGPARSE   = re.compile(r'^\s*import\s+argparse\b', re.M)
RX_HAVE_C          = re.compile(r'^\s*from\s+_common\s+import\s+cli\s+as\s+C\b', re.M)

# Détection top-level "glue" et parse
RX_TL_PARSER_START = re.compile(
    r'^(?P<ind>\s*)(?P<var>p|_p|ap|parser)\s*=\s*argparse\.ArgumentParser\s*\(',
    re.M
)
RX_TL_PARSE_ARGS   = re.compile(r'^\s*args\s*=\s*\w+\s*\.parse_args\s*\(\s*\)\s*$', re.M)

# add_argument (quel que soit le nom de variable)
RX_ADDARG_ANY      = re.compile(r'^\s*(?:p|_p|ap|parser)\.add_argument\s*\((?P<rest>.*)\)\s*$', re.M)

# Petites réparations syntaxiques fréquentes
RX_BAD_GLUE        = re.compile(r'(?m)^\s*\.\s*ArgumentParser\s*\(')            # ligne qui commence par ".ArgumentParser("
RX_DBL_COMMA_DESC  = re.compile(r'description\s*=\s*["\']\([Aa]utofix\)["\']\s*,\s*,')
RX_COMMA_PAREN     = re.compile(r',\s*\)')

TEMPLATE = """def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="(autofix)")
    C.add_common_plot_args(p)
{addargs}    return p
"""

def ensure_header(txt: str) -> str:
    # Shebang + encoding au tout début
    she = RX_SHEBANG.match(txt)
    prefix = she.group(0) if she else ''
    rest = txt[len(prefix):]
    enc = RX_ENCODING.match(rest)
    encs = enc.group(0) if enc else ''
    rest2 = rest[len(encs):]

    # Rassembler tous les __future__ en tête
    futures = RX_FUTURE.findall(rest2)
    rest2 = RX_FUTURE.sub('', rest2)

    lines = []
    if prefix: lines.append(prefix)
    if encs: lines.append(encs)
    for f in futures:
        if not f.endswith('\n'): f = f + '\n'
        lines.append(f)
    # Imports minimaux
    if not RX_HAVE_ARGPARSE.search(rest2):
        lines.append('import argparse\n')
    if not RX_HAVE_C.search(rest2):
        lines.append('from _common import cli as C\n')

    return ''.join(lines) + rest2.lstrip()

def comment_multiline_parenthesized_blocks(txt: str) -> str:
    """Commente tout bloc multi-ligne démarrant par '<var>=argparse.ArgumentParser(' au top-level."""
    out_lines = []
    in_block = False
    depth = 0
    for line in txt.splitlines(True):
        if not in_block:
            m = RX_TL_PARSER_START.match(line)
            if m:
                in_block = True
                depth = line.count('(') - line.count(')')
                out_lines.append(m.group('ind') + '# [autofix] moved into build_parser: ' + line.lstrip())
                continue
            if RX_TL_PARSE_ARGS.match(line):
                out_lines.append('# [autofix] args=parse_args() moved into main()\n')
                continue
            out_lines.append(line)
        else:
            # on est dans le bloc parenthésé
            depth += line.count('(') - line.count(')')
            out_lines.append('# ' + line)
            if depth <= 0:
                in_block = False
    # Si bloc resté ouvert par erreur, tout est commenté → pas de syntaxe cassée
    return ''.join(out_lines)

def rebuild_build_parser(txt: str) -> str:
    # Collecte tous les add_argument(...) dispersés
    addargs = []
    for m in RX_ADDARG_ANY.finditer(txt):
        rest = m.group('rest')
        # Restaure la parenthèse fermante si elle n'est pas dans le match
        if not rest.strip().endswith(')'):
            # on suppose qu'on a capturé jusqu'à ')', sinon ce sera rejoué tel quel
            pass
        addargs.append(f'    p.add_argument({rest})')

    addargs_block = ''
    if addargs:
        addargs_block = ''.join(a + ('' if a.endswith('\n') else '\n') for a in addargs)

    # Supprime le bloc existant de build_parser, s'il existe
    m = RX_BUILD_HDR.search(txt)
    if m:
        start = m.start()
        m2 = RX_NEXT_DEF_OR_MAIN.search(txt, m.end())
        end = m2.start() if m2 else len(txt)
        txt = txt[:start] + TEMPLATE.format(addargs=addargs_block) + txt[end:]
    else:
        # insère avant la première def / if __main__ sinon en fin de fichier
        m2 = RX_NEXT_DEF_OR_MAIN.search(txt)
        ins = TEMPLATE.format(addargs=addargs_block)
        if m2:
            txt = txt[:m2.start()] + ins + '\n' + txt[m2.start():]
        else:
            if not txt.endswith('\n'):
                txt += '\n'
            txt = txt + '\n' + ins + '\n'
    return txt

def tiny_syntax_fixes(txt: str) -> str:
    txt = RX_BAD_GLUE.sub('ArgumentParser(', txt)
    txt = RX_DBL_COMMA_DESC.sub('description="(autofix)",', txt)
    txt = RX_COMMA_PAREN.sub(')', txt)
    return txt

def patch_one(path: Path) -> bool:
    s0 = path.read_text(encoding='utf-8', errors='replace')
    s = s0
    s = ensure_header(s)
    s = comment_multiline_parenthesized_blocks(s)
    s = rebuild_build_parser(s)
    s = tiny_syntax_fixes(s)
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
