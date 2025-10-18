#!/usr/bin/env python3
from pathlib import Path
import re

SENTINEL_ANY = re.compile(r"# --- compat: argparse post-parse shim v\d+ ---")
START = "# --- compat: argparse post-parse shim v4 ---"
END   = "# --- end compat: argparse post-parse shim v4 ---"

PATCH = f"""
{START}
import argparse as _argparse
def _mcgt__augment(ns):
    defaults = {{
        "p95_col": "p95_20_300",   # fig03b
        "m1_col": "phi0",          # fig06
        "m2_col": "phi_ref_fpeak",
        "ymin_coverage": None, "ymax_coverage": None,
        "mincnt": 1, "gridsize": 60, "figsize": None,
        "hist_x": 0, "hist_y": 0,  # fig04
    }}
    for k,v in defaults.items():
        if not hasattr(ns,k):
            setattr(ns,k,v)
    return ns
_orig_pa  = _argparse.ArgumentParser.parse_args
_orig_pka = _argparse.ArgumentParser.parse_known_args
def _pa(self,*a,**kw):  ns=_orig_pa(self,*a,**kw);  return _mcgt__augment(ns)
def _pka(self,*a,**kw): ns,unk=_orig_pka(self,*a,**kw);  return _mcgt__augment(ns),unk
_argparse.ArgumentParser.parse_args = _pa
_argparse.ArgumentParser.parse_known_args = _pka
try: args
except NameError: pass
else: _mcgt__augment(args)
{END}
""".lstrip("\n")

def move_future_to_top(lines):
    i=0
    if i<len(lines) and lines[i].startswith("#!"): i+=1
    while i<len(lines) and lines[i].strip()=="": i+=1
    if i<len(lines) and lines[i].lstrip().startswith(("'''",'"""')):
        q=lines[i].lstrip()[:3]; i+=1
        while i<len(lines):
            if lines[i].strip().endswith(q): i+=1; break
            i+=1
    fut, keep = [], []
    for s in lines:
        (fut if s.lstrip().startswith("from __future__ import") else keep).append(s)
    if not fut: return lines
    insert_at = 1 if keep and keep[0].startswith("#!") else 0
    keep[insert_at:insert_at] = fut
    return keep

def install(path: Path):
    s = path.read_text(encoding="utf-8")
    # supprime tous les anciens blocs vN
    lines = []
    skip = False
    for line in s.splitlines(True):
        if not skip and SENTINEL_ANY.search(line):
            skip = True; continue
        if skip and line.strip().startswith("# --- end compat: argparse post-parse shim"):
            skip = False; continue
        if not skip: lines.append(line)
    lines = move_future_to_top(lines)
    # place après les imports
    i=0
    if i<len(lines) and lines[i].startswith("#!"): i+=1
    while i<len(lines) and (lines[i].strip()=="" or lines[i].lstrip().startswith("#")): i+=1
    if i<len(lines) and lines[i].lstrip().startswith(("'''",'"""')):
        q=lines[i].lstrip()[:3]; i+=1
        while i<len(lines):
            if lines[i].strip().endswith(q): i+=1; break
            i+=1
    while i<len(lines) and lines[i].lstrip().startswith("from __future__ import"): i+=1
    last=i
    while i<len(lines) and lines[i].lstrip().startswith(("import ","from ")): last=i+1; i+=1
    lines.insert(last, PATCH)
    path.write_text("".join(lines), encoding="utf-8")

if __name__ == "__main__":
    for t in [
        Path("zz-scripts/chapter10/plot_fig03b_bootstrap_coverage_vs_n.py"),
        Path("zz-scripts/chapter10/plot_fig06_residual_map.py"),
    ]:
        install(t)
    print("[OK] single post-parse shim v4 installed")
