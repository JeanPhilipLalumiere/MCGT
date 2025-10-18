#!/usr/bin/env python3
import sys, re
from pathlib import Path

START = "# >>> AUTO-ARGS-SHIM >>>"
END   = "# <<< AUTO-ARGS-SHIM <<<"

SHIM = f"""{START}
try:
    args  # may raise NameError if not yet defined
except NameError:  # inject a minimal argparse so early uses of args.* work
    import argparse as _argparse, sys as _sys
    _shim = _argparse.ArgumentParser(add_help=False)
    # Common figure flags we saw in chap.10
    _shim.add_argument('--results')
    _shim.add_argument('--x-col'); _shim.add_argument('--y-col')
    _shim.add_argument('--sigma-col'); _shim.add_argument('--group-col')
    _shim.add_argument('--n-col'); _shim.add_argument('--p95-col')
    _shim.add_argument('--orig-col'); _shim.add_argument('--recalc-col')
    _shim.add_argument('--m1-col'); _shim.add_argument('--m2-col')
    _shim.add_argument('--seed', type=int)
    _shim.add_argument('--boot-ci', action='store_true')
    _shim.add_argument('--dpi'); _shim.add_argument('--out')
    _shim.add_argument('--format'); _shim.add_argument('--transparent', action='store_true')
    # variants we saw in code: --p95-ref → args.p95_ref
    _shim.add_argument('--p95-ref', dest='p95_ref', type=float)
    try:
        args, _unk = _shim.parse_known_args(_sys.argv[1:])
    except Exception:
        class _A: pass
        args = _A()
{END}
"""

RE_FUTURE = re.compile(r'^\s*from\s+__future__\s+import\s+.+$', re.M)
RE_ENCODING = re.compile(r'^\s*#.*coding[:=]\s*([-\w.]+)')

def remove_existing_shim(txt: str) -> str:
    start = txt.find(START)
    end   = txt.find(END)
    if start != -1 and end != -1 and end >= start:
        endpos = end + len(END)
        # mange aussi les sauts de ligne adjacents
        while endpos < len(txt) and txt[endpos] in "\r\n":
            endpos += 1
        return txt[:start] + txt[endpos:]
    return txt

def find_docstring_block(lines):
    """Retourne (start_idx, end_idx) 1er docstring si en tête, sinon (None, None)."""
    i = 0
    # skip blank and comments (mais PAS shebang/encoding ici)
    while i < len(lines) and (lines[i].strip() == "" or lines[i].lstrip().startswith("#")):
        i += 1
    if i >= len(lines): 
        return (None, None)
    line = lines[i].lstrip()
    if line.startswith('"""') or line.startswith("'''"):
        quote = line[:3]
        # docstring d'une ligne ?
        if line.count(quote) >= 2:
            return (i, i)
        # chercher la fin
        j = i + 1
        while j < len(lines):
            if quote in lines[j]:
                return (i, j)
            j += 1
    return (None, None)

def insertion_index(txt: str) -> int:
    """Calcule l'index caractère où insérer le shim (après shebang, encoding, docstring, futures)."""
    lines = txt.splitlines(True)
    idx_line = 0

    # 1) shebang
    if idx_line < len(lines) and lines[idx_line].startswith("#!"):
        idx_line += 1

    # 2) encoding comment (PEP 263)
    if idx_line < len(lines) and RE_ENCODING.match(lines[idx_line]):
        idx_line += 1
    elif idx_line+1 < len(lines) and RE_ENCODING.match(lines[idx_line+1]):
        # parfois encoding en 2e ligne (après shebang)
        idx_line += 2

    # 3) docstring de module si présent immédiatement
    ds_start, ds_end = find_docstring_block(lines[idx_line:])
    if ds_start is not None:
        idx_line += (ds_end + 1)

    # 4) bloc des from __future__ import ...
    # Avance tant que les lignes suivantes sont des imports __future__ (en gardant commentaires/vides)
    while idx_line < len(lines):
        # sauter blancs/commentaires mais laisser la possibilité d'avoir plusieurs futures
        saved = idx_line
        while idx_line < len(lines) and (lines[idx_line].strip() == "" or lines[idx_line].lstrip().startswith("#")):
            idx_line += 1
        if idx_line < len(lines) and RE_FUTURE.match(lines[idx_line]):
            idx_line += 1
            continue
        else:
            idx_line = saved  # revenir au dernier blanc/comment pour insérer après le bloc
            break

    # Convertir en index caractères
    char_idx = sum(len(l) for l in lines[:idx_line])
    return char_idx

def inject_after_future(p: Path):
    txt = p.read_text(encoding="utf-8")
    txt = remove_existing_shim(txt)
    ins = insertion_index(txt)
    new = txt[:ins] + ("" if ins == 0 or txt[ins-1] == "\n" else "\n") + SHIM + ("\n" if ins < len(txt) and txt[ins] != "\n" else "") + txt[ins:]
    if new != txt:
        bak = p.with_suffix(p.suffix + ".bak_shim")
        if not bak.exists():
            bak.write_text(txt, encoding="utf-8")
        p.write_text(new, encoding="utf-8")
        print(f"[PATCH] {p}: shim args (v2) injecté après __future__/docstring")
    else:
        print(f"[OK   ] {p}: rien à faire (déjà propre)")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("usage: tools/inject_args_shim_v2.py FILE [FILE...]", file=sys.stderr); sys.exit(2)
    for a in sys.argv[1:]:
        p = Path(a)
        if not p.exists():
            print(f"[SKIP ] not found: {p}")
            continue
        inject_after_future(p)
