#!/usr/bin/env python3
from pathlib import Path
import re

p = Path("zz-scripts/chapter10/plot_fig07_synthesis.py")
src = p.read_text(encoding="utf-8")

# 1) Après la création/itération des séries s (objet/tuple 's'),
#    on insère un garde: si aucune donnée numérique, on continue.
#    On se cale sur la ligne qui trace/annote, mais plus robuste:
#    on ajoute ce garde juste avant le bloc de stats (repéré par 'np.nanmean(s.coverage)').

guard = (
    "if (len(s.coverage) == 0 or (hasattr(np, 'isnan') and np.all(np.isnan(s.coverage)))) \\\n"
    "   and (len(s.width_mean) == 0 or (hasattr(np, 'isnan') and np.all(np.isnan(s.width_mean)))):\n"
    "    continue\n"
)

pat_stats = re.compile(r"(?m)^\s*mean_cov\s*=\s*np\.nanmean\(s\.coverage\)")
if pat_stats.search(src):
    # Inject le garde s'il n'existe pas déjà
    block_pat = re.compile(r"(?m)^(\s*)mean_cov\s*=\s*np\.nanmean\(s\.coverage\)")
    def _inject(m):
        indent = m.group(1)
        return indent + guard.replace("\n", "\n"+indent) + "mean_cov = np.nanmean(s.coverage)"
    dst = block_pat.sub(_inject, src, count=1)
    if dst != src:
        p.write_text(dst, encoding="utf-8")
        print("[OK] patched: skip empty series guard inserted")
    else:
        print("[SKIP] already patched?")
else:
    print("[WARN] pattern not found; no patch applied (script layout differs?)")
