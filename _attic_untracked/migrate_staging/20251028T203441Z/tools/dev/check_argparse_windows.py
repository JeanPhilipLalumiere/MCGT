#!/usr/bin/env python3
import re, subprocess, sys, pathlib

files = subprocess.check_output(
    ["bash","-lc","git ls-files 'zz-scripts/**/plot_*.py'"]
).decode().split()

bad_after = []   # files with add_argument(...) after parse_args()
bad_dupes = []   # files with multiple parse_args lines

for f in files:
    text = pathlib.Path(f).read_text(encoding="utf-8")
    lines = text.splitlines()

    m = re.search(r'^\s*([A-Za-z_]\w*)\s*=\s*argparse\.ArgumentParser\(', text, re.M)
    p = m.group(1) if m else "parser"

    # find all parse_args lines (canonical or bare)
    rx_pa = re.compile(rf'^\s*(?:args\s*=\s*)?{re.escape(p)}\.parse_args\(\)\s*$')
    pa_idxs = [i for i,l in enumerate(lines) if rx_pa.match(l)]
    if not pa_idxs:
        continue

    # flag duplicate parse_args
    if len(pa_idxs) > 1:
        bad_dupes.append(f)

    first_pa = min(pa_idxs)

    # any add_argument AFTER first parse_args?
    rx_add = re.compile(rf'^\s*{re.escape(p)}\.add_argument\(')
    if any(rx_add.match(l) for l in lines[first_pa+1:]):
        bad_after.append(f)

ok = True
if bad_after:
    print("ERROR: add_argument after parse_args in:")
    for f in bad_after: print(f" - {f}")
    ok = False

if bad_dupes:
    print("ERROR: multiple parse_args() lines in:")
    for f in bad_dupes: print(f" - {f}")
    ok = False

if ok:
    print("OK: argparse windows look clean.")
sys.exit(0 if ok else 1)
