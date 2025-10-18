#!/usr/bin/env python3
import sys, re
from pathlib import Path

START = "# >>> AUTO-ARGS-SHIM >>>"
END   = "# <<< AUTO-ARGS-SHIM <<<"

SHIM = f"""{START}
try:
    args
except NameError:
    import argparse as _argparse, sys as _sys
    _shim = _argparse.ArgumentParser(add_help=False)
    # I/O & colonnes
    _shim.add_argument('--results')
    _shim.add_argument('--x-col'); _shim.add_argument('--y-col')
    _shim.add_argument('--sigma-col'); _shim.add_argument('--group-col')
    _shim.add_argument('--n-col'); _shim.add_argument('--p95-col')
    _shim.add_argument('--orig-col'); _shim.add_argument('--recalc-col')
    _shim.add_argument('--m1-col'); _shim.add_argument('--m2-col')
    # Export
    _shim.add_argument('--dpi'); _shim.add_argument('--out')
    _shim.add_argument('--format'); _shim.add_argument('--transparent', action='store_true')
    # Numériques/contrôles divers
    _shim.add_argument('--npoints'); _shim.add_argument('--hires2000', action='store_true')
    _shim.add_argument('--change-eps', dest='change_eps')
    _shim.add_argument('--ref-p95', dest='ref_p95')
    _shim.add_argument('--metric'); _shim.add_argument('--bins'); _shim.add_argument('--alpha')
    _shim.add_argument('--boot-iters', dest='boot_iters'); _shim.add_argument('--seed'); _shim.add_argument('--trim')
    _shim.add_argument('--minN', dest='minN'); _shim.add_argument('--point-size', dest='point_size')
    _shim.add_argument('--zoom-w', dest='zoom_w'); _shim.add_argument('--zoom-h', dest='zoom_h')
    _shim.add_argument('--abs', action='store_true', dest='abs')
    _shim.add_argument('--p95-ref', dest='ref_p95')
    _shim.add_argument('--B', dest='B'); _shim.add_argument('--M', dest='M'); _shim.add_argument('--outer', dest='outer')
    _shim.add_argument('--cmap')
    _shim.add_argument('--zoom-x', dest='zoom_x'); _shim.add_argument('--zoom-dx', dest='zoom_dx')
    _shim.add_argument('--scale-exp', dest='scale_exp')
    _shim.add_argument('--zoom-center-n', dest='zoom_center_n')
    _shim.add_argument('--inner', dest='inner')
    _shim.add_argument('--title', dest='title')
    _shim.add_argument('--zoom-y', dest='zoom_y'); _shim.add_argument('--zoom-dy', dest='zoom_dy')
    _shim.add_argument('--vclip', dest='vclip')
    _shim.add_argument('--angular', action='store_true')
    _shim.add_argument('--hist-scale', dest='hist_scale')
    _shim.add_argument('--threshold', dest='threshold')
    _shim.add_argument('--title-left',  dest='title_left')
    _shim.add_argument('--title-right', dest='title_right')
    _shim.add_argument('--hist-x', dest='hist_x')
    _shim.add_argument('--hist-y', dest='hist_y')
    _shim.add_argument('--figsize')
    # Nouveaux
    _shim.add_argument('--with-zoom', dest='with_zoom', action='store_true')
    _shim.add_argument('--gridsize', dest='gridsize')

    try:
        args, _unk = _shim.parse_known_args(_sys.argv[1:])
    except Exception:
        class _A: pass
        args = _A()

    _DEF = {{
        'npoints': 50, 'hires2000': False, 'change_eps': 1e-6, 'ref_p95': 1e9,
        'metric': 'dp95', 'bins': 50, 'alpha': 0.7, 'boot_iters': 2000, 'trim': 0.0,
        'minN': 10, 'point_size': 10.0, 'zoom_w': 1.0, 'zoom_h': 1.0, 'abs': False,
        'B': 2000, 'M': None, 'outer': 500, 'cmap': 'viridis',
        'zoom_x': 0.0, 'zoom_dx': 1.0, 'scale_exp': 0.0,
        'zoom_center_n': None, 'inner': 2000, 'title': 'MCGT figure',
        'zoom_y': 0.0, 'zoom_dy': 1.0, 'vclip': '1,99', 'angular': False,
        'hist_scale': 1.0, 'threshold': 0.0, 'title_left': 'Left panel',
        'title_right': 'Right panel', 'hist_x': 0.0, 'hist_y': 0.0,
        'figsize': '6,4', 'with_zoom': False, 'gridsize': 60,
    }}
    for _k, _v in _DEF.items():
        if not hasattr(args, _k) or getattr(args, _k) is None:
            try: setattr(args, _k, _v)
            except Exception: pass

    def _to_int(x):
        try: return int(x)
        except: return x
    def _to_float(x):
        try: return float(x)
        except: return x

    for _k in ('dpi','B','M','outer','bins','boot_iters','npoints','minN','inner','zoom_center_n','gridsize'):
        if hasattr(args,_k): setattr(args,_k, _to_int(getattr(args,_k)))
    for _k in ('alpha','trim','change_eps','point_size','zoom_w','zoom_h','zoom_x','zoom_dx','zoom_y','zoom_dy','scale_exp','hist_scale','threshold','hist_x','hist_y'):
        if hasattr(args,_k): setattr(args,_k, _to_float(getattr(args,_k)))
{END}
"""

RE_FUTURE = re.compile(r'^\s*from\s+__future__\s+import\s+.+$', re.M)
RE_ENCODING = re.compile(r'^\s*#.*coding[:=]\s*([-\w.]+)')

def _remove_existing_shim(txt: str) -> str:
    s = txt.find(START); e = txt.find(END)
    if s != -1 and e != -1 and e >= s:
        e += len(END)
        while e < len(txt) and txt[e] in "\r\n": e += 1
        return txt[:s] + txt[e:]
    return txt

def _find_docstring_block(lines):
    i = 0
    while i < len(lines) and (lines[i].strip()=="" or lines[i].lstrip().startswith("#")): i += 1
    if i >= len(lines): return (None, None)
    line = lines[i].lstrip()
    if line.startswith('\"\"\"') or line.startswith("'''"):
        quote = line[:3]
        if line.count(quote) >= 2: return (i, i)
        j = i + 1
        while j < len(lines):
            if quote in lines[j]: return (i, j)
            j += 1
    return (None, None)

def _insertion_index(txt: str) -> int:
    lines = txt.splitlines(True)
    idx_line = 0
    if idx_line < len(lines) and lines[idx_line].startswith("#!"): idx_line += 1
    if idx_line < len(lines) and RE_ENCODING.match(lines[idx_line]):
        idx_line += 1
    elif idx_line+1 < len(lines) and RE_ENCODING.match(lines[idx_line+1]):
        idx_line += 2
    ds_start, ds_end = _find_docstring_block(lines[idx_line:])
    if ds_start is not None: idx_line += (ds_end + 1)
    while idx_line < len(lines):
        saved = idx_line
        while idx_line < len(lines) and (lines[idx_line].strip()=="" or lines[idx_line].lstrip().startswith("#")):
            idx_line += 1
        if idx_line < len(lines) and RE_FUTURE.match(lines[idx_line]):
            idx_line += 1; continue
        else:
            idx_line = saved; break
    return sum(len(l) for l in lines[:idx_line])

def inject_after_future(p: Path):
    txt = p.read_text(encoding="utf-8")
    txt = _remove_existing_shim(txt)
    ins = _insertion_index(txt)
    need_nl_before = (ins != 0 and (ins > 0 and txt[ins-1] != "\n"))
    need_nl_after  = (ins < len(txt) and txt[ins] != "\n")
    new = txt[:ins] + ("\n" if need_nl_before else "") + SHIM + ("\n" if need_nl_after else "") + txt[ins:]
    if new != txt:
        bak = p.with_suffix(p.suffix + ".bak_shim9")
        if not bak.exists(): bak.write_text(txt, encoding="utf-8")
        p.write_text(new, encoding="utf-8")
        print(f"[PATCH] {p}: shim args (v9) injecté")
    else:
        print(f"[OK   ] {p}: rien à faire")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("usage: tools/inject_args_shim_v9.py FILE [FILE...]", file=sys.stderr); sys.exit(2)
    for a in sys.argv[1:]:
        p = Path(a)
        if not p.exists():
            print(f"[SKIP ] not found: {p}"); continue
        inject_after_future(p)
