#!/usr/bin/env python3
from pathlib import Path
import re, sys

p = Path("zz-scripts/chapter10/plot_fig01_iso_p95_maps.py")
if not p.exists():
    print("[ERR] introuvable:", p); sys.exit(2)

src = p.read_text(encoding="utf-8")

# On remplace TOUTE occurrence « df = ci.ensure_fig02_cols(df) » nue
# par un bloc try/except sûr + le même appel derrière.
pat = re.compile(r'^[ \t]*df\s*=\s*ci\.ensure_fig02_cols\(\s*df\s*\)\s*$', re.M)

REPL = """\
# --- auto-guard inserted ---
try:
    df  # peut lever NameError
except NameError:
    import pandas as _pd, sys as _sys
    # On s'appuie d'abord sur args (shim), sinon on fouille argv
    _res = None
    try:
        _res = args.results
    except Exception:
        for _j, _a in enumerate(_sys.argv):
            if _a == "--results" and _j + 1 < len(_sys.argv):
                _res = _sys.argv[_j + 1]
                break
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
    bak = p.with_suffix(p.suffix + ".bak_fig01")
    if not bak.exists():
        bak.write_text(src, encoding="utf-8")
    p.write_text(new, encoding="utf-8")
    print("[OK ] fig01 guard réparé →", p)
