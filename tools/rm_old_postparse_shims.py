#!/usr/bin/env python3
from pathlib import Path
import re, sys

START_RE = re.compile(r'^\s*#\s*--- compat: argparse post-parse shim(?: v(?P<ver>\d+))? ---\s*$')
END_RE   = re.compile(r'^\s*#\s*--- end compat: argparse post-parse shim(?: v\d+)? ---\s*$')

def prune(path: Path) -> bool:
    lines = path.read_text(encoding="utf-8").splitlines(True)
    blocks = []  # (start,end,ver,idx)
    i = 0
    while i < len(lines):
        m = START_RE.match(lines[i])
        if not m:
            i += 1
            continue
        ver = m.group('ver')
        j = i + 1
        while j < len(lines) and not END_RE.match(lines[j]):
            j += 1
        if j == len(lines):
            # pas de fin: abandonne ce "start" incomplet
            i += 1
            continue
        blocks.append((i, j, ver, len(blocks)))
        i = j + 1

    if not blocks:
        return False

    # choix de ce qu'on garde: garder exactement UN bloc v4 (le premier rencontré)
    keep_idx = None
    for k,(s,e,ver,_) in enumerate(blocks):
        if ver == '4':
            keep_idx = k
            break

    new = []
    drop_ranges = []
    for k,(s,e,ver,_) in enumerate(blocks):
        if ver == '4' and k == keep_idx:
            continue  # garder ce v4
        # supprimer tous les autres (y compris sans version / autres versions)
        drop_ranges.append((s, e))

    # applique la suppression
    drop_set = set()
    for s,e in drop_ranges:
        for t in range(s, e+1):
            drop_set.add(t)

    for idx, line in enumerate(lines):
        if idx not in drop_set:
            new.append(line)

    if new == lines:
        return False

    path.write_text("".join(new), encoding="utf-8")
    return True

if __name__ == "__main__":
    changed = False
    for f in [
        Path("zz-scripts/chapter10/plot_fig03b_bootstrap_coverage_vs_n.py"),
        Path("zz-scripts/chapter10/plot_fig06_residual_map.py"),
    ]:
        if prune(f):
            print(f"[CLEAN] pruned old shims in {f}")
            changed = True
        else:
            print(f"[OK] no old shims to prune in {f}")
    sys.exit(0)
