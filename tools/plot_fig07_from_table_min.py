#!/usr/bin/env python3
import csv, math
from pathlib import Path
import matplotlib.pyplot as plt

CSV = Path("zz-figures/chapter10/10_fig_07_synthesis.table.csv")
OUT = Path("zz-figures/chapter10/10_fig_07_synthesis.png")

def to_float_safe(x):
    try: return float(x)
    except: return math.nan

rows = list(csv.DictReader(CSV.open(encoding="utf-8")))
# garde uniquement lignes numériques
N = [to_float_safe(r.get("N","")) for r in rows]
C = [to_float_safe(r.get("coverage","")) for r in rows]
W = [to_float_safe(r.get("width_mean","")) for r in rows]
N, C, W = zip(*[(n,c,w) for n,c,w in zip(N,C,W) if (not math.isnan(n) and (not math.isnan(c) or not math.isnan(w)) )]) if rows else ([],[],[])

fig, (ax1, ax2) = plt.subplots(1,2, figsize=(10,4), constrained_layout=True)
if N:
    ax1.plot(N, C, marker='o'); ax1.set_title("Coverage vs N"); ax1.set_ylim(0,1); ax1.set_xlabel("N"); ax1.set_ylabel("coverage")
    ax2.plot(N, W, marker='o'); ax2.set_title("Width vs N"); ax2.set_xlabel("N"); ax2.set_ylabel("width (rad)")
else:
    ax1.text(0.5,0.5,"No data", ha="center", va="center"); ax2.text(0.5,0.5,"No data", ha="center", va="center")
fig.savefig(OUT, dpi=300)
print(f"[OK] figure écrite: {OUT}")
