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

# repères
RX_DEF_BUILD_ANY   = re.compile(r'^(\s*)def\s+build_parser\s*\([^)]*\)\s*:\s*$', re.M)
RX_NEXT_DEF_OR_MAIN= re.compile(r'^\s*def\s+\w+\s*\(|^\s*if\s+__name__\s*==\s*["\']__main__["\']\s*:', re.M)
RX_ADDARG          = re.compile(r'^\s*(?P<var>p|_p|ap|parser)\s*\.add_argument\s*\((?P<rest>.*)$', re.M)
RX_BAD_GLUE        = re.compile(r'(?m)^\s*\.\s*ArgumentParser\s*\(')                    # ligne qui commence par ".ArgumentParser("
RX_ARGS_TOP        = re.compile(r'(?m)^\s*args\s*=\s*\w+\s*\.parse_args\s*\(\s*\)\s*$') # args=... au niveau top
RX_FUTURE          = re.compile(r'^\s*from\s+__future__\s+import\s+[^\n]+$', re.M)

TEMPLATE = """{indent}def build_parser() -> argparse.ArgumentParser:
{indent}    p = argparse.ArgumentParser(description="(autofix)")
{indent}    C.add_common_plot_args(p)
{addargs}
{indent}    return p
"""

def move_future_to_top(txt: str) -> str:
    # Remonte les imports __future__ en tête (après shebang/encoding)
    lines = txt.splitlines(True)
    shebang, i = [], 0
    if lines and lines[0].startswith("#!"):
        shebang.append(lines[0]); i = 1
    if i < len(lines) and "coding" in lines[i][:40]:
        shebang.append(lines[i]); i += 1
    futures = [l for l in lines if RX_FUTURE.match(l)]
    if not futures:
        return txt
    body_wo = [l for l in lines if not RX_FUTURE.match(l)]
    # déduplique en gardant l'ordre d'apparition
    seen, uniq = set(), []
    for l in futures:
        if l not in seen: uniq.append(l); seen.add(l)
    return "".join(shebang + uniq + body_wo[i:])

def patch_file(path: Path) -> bool:
    s = path.read_text(encoding="utf-8", errors="replace")
    orig = s

    # 0) supprime le pattern ".ArgumentParser(" isolé → on le corrigera via rebuild
    s = RX_BAD_GLUE.sub("ArgumentParser(", s)

    # 1) isole le bloc build_parser (s'il existe), sinon on l'injecte minimalement
    m = RX_DEF_BUILD_ANY.search(s)
    if m:
        start = m.start()
        indent = m.group(1) or ""
        m2 = RX_NEXT_DEF_OR_MAIN.search(s, m.end())
        end = m2.start() if m2 else len(s)
        block = s[m.end():end]

        # 2) récupère les add_argument existants du bloc
        addargs_lines = []
        for mm in RX_ADDARG.finditer(block):
            # on normalise la variable utilisée vers 'p'
            rest = mm.group("rest").rstrip()
            addargs_lines.append(f"{indent}    p.add_argument({rest}")

        addargs = ""
        if addargs_lines:
            addargs = "\n" + "\n".join(addargs_lines) + "\n"
        rebuilt = TEMPLATE.format(indent=indent, addargs=addargs)

        # 3) remplace le bloc
        s = s[:start] + rebuilt + s[end:]
    else:
        # injecter un build_parser minimal juste avant le premier def/main
        m2 = RX_NEXT_DEF_OR_MAIN.search(s) or re.search(r'\Z', s)
        insert_at = m2.start() if m2 else len(s)
        rebuilt = TEMPLATE.format(indent="", addargs="")
        s = s[:insert_at] + rebuilt + "\n" + s[insert_at:]

    # 4) purge "args = ...parse_args()" parasites au top-level (ils appartiennent à main())
    s = RX_ARGS_TOP.sub("", s)

    # 5) remonte les imports __future__ si besoin
    s = move_future_to_top(s)

    if s != orig:
        path.write_text(s, encoding="utf-8")
        return True
    return False

def main():
    changed = 0
    for p in SENTINELS:
        if p.exists():
            if patch_file(p):
                changed += 1
                print("[patched]", p)
        else:
            print("[missing]", p)
    print("Done. Files changed:", changed)

if __name__ == "__main__":
    main()
