#!/usr/bin/env python3
from pathlib import Path
import re, sys

p = Path("zz-scripts/chapter10/plot_fig01_iso_p95_maps.py")
if not p.exists():
    print("[ERR] introuvable:", p); sys.exit(2)

src = p.read_text(encoding="utf-8")

# 1) supprime tout 'try:' orphelin juste avant la ligne cible (1 ou 2 lignes max)
def strip_broken_try_just_above(text: str) -> str:
    lines = text.splitlines(True)
    out = lines[:]
    i = 0
    while i < len(out):
        if re.search(r'ci\.ensure_fig02_cols\(\s*df\s*\)', out[i]):
            # regarde 1-2 lignes au-dessus
            for k in (1, 2):
                j = i - k
                if j >= 0 and re.match(r'^\s*try:\s*$', out[j]):
                    # supprime la ligne 'try:'
                    out.pop(j)
                    i -= 1
        i += 1
    return "".join(out)

src = strip_broken_try_just_above(src)

# 2) remplace la ligne simple par un guard robuste
pat = re.compile(r'^[ \t]*df\s*=\s*ci\.ensure_fig02_cols\(\s*df\s*\)\s*$', re.M)
REPL = """\
# --- auto-guard rebuilt ---
try:
    df  # peut lever NameError
except NameError:
    import pandas as _pd, sys as _sys
    _res = None
    try:
        _res = args.results
    except Exception:
        for _j, _a in enumerate(_sys.argv):
            if _a == "--results" and _j + 1 < len(_sys.argv):
                _res = _sys.argv[_j + 1]; break
    if _res is None:
        raise RuntimeError("Cannot infer --results (fig01)")
    df = _pd.read_csv(_res)
df = ci.ensure_fig02_cols(df)
# --- end auto-guard ---
"""

new = pat.sub(REPL, src)
if new == src:
    print("[WARN] Aucun remplacement effectué (rien à patcher ?)")
else:
    bak = p.with_suffix(p.suffix + ".bak_fig01_fix")
    if not bak.exists():
        bak.write_text(src, encoding="utf-8")
    p.write_text(new, encoding="utf-8")
    print("[OK ] fig01 guard(s) réparé(s) →", p)
