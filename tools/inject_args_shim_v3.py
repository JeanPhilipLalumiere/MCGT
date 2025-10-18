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
    # Fichiers / colonnes usuels (chap.10)
    _shim.add_argument('--results')
    _shim.add_argument('--x-col'); _shim.add_argument('--y-col')
    _shim.add_argument('--sigma-col'); _shim.add_argument('--group-col')
    _shim.add_argument('--n-col'); _shim.add_argument('--p95-col')
    _shim.add_argument('--orig-col'); _shim.add_argument('--recalc-col')
    _shim.add_argument('--m1-col'); _shim.add_argument('--m2-col')
    # Qualité d’image / export
    _shim.add_argument('--dpi'); _shim.add_argument('--out')
    _shim.add_argument('--format'); _shim.add_argument('--transparent', action='store_true')
    # Options analytiques rencontrées dans les scripts
    _shim.add_argument('--npoints', type=int)          # taille de grille N
    _shim.add_argument('--hires2000', action='store_true')
    _shim.add_argument('--change-eps', dest='change_eps', type=float)
    _shim.add_argument('--ref-p95', dest='ref_p95', type=float)
    _shim.add_argument('--metric', type=str)
    _shim.add_argument('--bins', type=int)
    _shim.add_argument('--alpha', type=float)
    _shim.add_argument('--boot-iters', dest='boot_iters', type=int)
    _shim.add_argument('--seed', type=int)
    # Variante orthographique déjà vue :
    _shim.add_argument('--p95-ref', dest='ref_p95', type=float)
    try:
        args, _unk = _shim.parse_known_args(_sys.argv[1:])
    except Exception:
        class _A: pass
        args = _A()
    # Valeurs par défaut robustes si manquantes
    _DEF = {{
        'npoints': 50,
        'hires2000': False,
        'change_eps': 1e-6,
        'ref_p95': 1e9,
        'metric': 'dp95',
        'bins': 50,
        'alpha': 0.7,
        'boot_iters': 2000,
    }}
    for _k, _v in _DEF.items():
        if not hasattr(args, _k) or getattr(args, _k) is None:
            try:
                setattr(args, _k, _v)
            except Exception:
                pass
{END}
"""

RE_FUTURE = re.compile(r'^\s*from\s+__future__\s+import\s+.+$', re.M)
RE_ENCODING = re.compile(r'^\s*#.*coding[:=]\s*([-\w.]+)')

def _remove_existing_shim(txt: str) -> str:
    start = txt.find(START)
    end   = txt.find(END)
    if start != -1 and end != -1 and end >= start:
        endpos = end + len(END)
        while endpos < len(txt) and txt[endpos] in "\r\n":
            endpos += 1
        return txt[:start] + txt[endpos:]
    return txt

def _find_docstring_block(lines):
    i = 0
    while i < len(lines) and (lines[i].strip() == "" or lines[i].lstrip().startswith("#")):
        i += 1
    if i >= len(lines):
        return (None, None)
    line = lines[i].lstrip()
    if line.startswith('"""') or line.startswith("'''"):
        quote = line[:3]
        if line.count(quote) >= 2:
            return (i, i)
        j = i + 1
        while j < len(lines):
            if quote in lines[j]:
                return (i, j)
            j += 1
    return (None, None)

def _insertion_index(txt: str) -> int:
    lines = txt.splitlines(True)
    idx_line = 0
    if idx_line < len(lines) and lines[idx_line].startswith("#!"):
        idx_line += 1
    if idx_line < len(lines) and RE_ENCODING.match(lines[idx_line]):
        idx_line += 1
    elif idx_line+1 < len(lines) and RE_ENCODING.match(lines[idx_line+1]):
        idx_line += 2
    ds_start, ds_end = _find_docstring_block(lines[idx_line:])
    if ds_start is not None:
        idx_line += (ds_end + 1)
    while idx_line < len(lines):
        saved = idx_line
        while idx_line < len(lines) and (lines[idx_line].strip() == "" or lines[idx_line].lstrip().startswith("#")):
            idx_line += 1
        if idx_line < len(lines) and RE_FUTURE.match(lines[idx_line]):
            idx_line += 1
            continue
        else:
            idx_line = saved
            break
    return sum(len(l) for l in lines[:idx_line])

def inject_after_future(p: Path):
    txt = p.read_text(encoding="utf-8")
    txt = _remove_existing_shim(txt)
    ins = _insertion_index(txt)
    new = txt[:ins] + ("" if ins == 0 or txt[ins-1] == "\n" else "\n") + SHIM + ("\n" if ins < len(txt) and txt[ins] != "\n" else "") + txt[ins:]
    if new != txt:
        bak = p.with_suffix(p.suffix + ".bak_shim")
        if not bak.exists():
            bak.write_text(txt, encoding="utf-8")
        p.write_text(new, encoding="utf-8")
        print(f"[PATCH] {p}: shim args (v3) injecté après __future__/docstring")
    else:
        print(f"[OK   ] {p}: rien à faire (déjà propre)")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("usage: tools/inject_args_shim_v3.py FILE [FILE...]", file=sys.stderr); sys.exit(2)
    for a in sys.argv[1:]:
        p = Path(a)
        if not p.exists():
            print(f"[SKIP ] not found: {p}")
            continue
        inject_after_future(p)
