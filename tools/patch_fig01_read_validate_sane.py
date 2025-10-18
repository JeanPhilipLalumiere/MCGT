#!/usr/bin/env python3
import sys, re
from pathlib import Path

if len(sys.argv) != 2:
    print("usage: patch_fig01_read_validate_sane.py PATH/plot_fig01_iso_p95_maps.py", file=sys.stderr)
    sys.exit(2)

p = Path(sys.argv[1])
src = p.read_text(encoding="utf-8")

# repérer le bloc def read_and_validate(...)
pat_start = re.compile(r'^[ ]*def[ ]+read_and_validate\s*\(', re.M)
m = pat_start.search(src)
if not m:
    print("[ERR] def read_and_validate(...) introuvable", file=sys.stderr)
    sys.exit(3)

si = m.start()

# trouver la fin du bloc: prochain def/class top-level (col 0) ou EOF
lines = src.splitlines(True)
# retrouver l'index de ligne correspondant
offsets = [0]
for s in lines: offsets.append(offsets[-1] + len(s))
# index de ligne où commence la def
start_line = next(i for i,o in enumerate(offsets) if o == si)

# indentation de la def (devrait être 0)
def indent(s): return len(s) - len(s.lstrip(" "))
base_indent = indent(lines[start_line])

end_line = len(lines)
for j in range(start_line+1, len(lines)):
    s = lines[j]
    if s.strip() == "": 
        continue
    if indent(s) <= base_indent and (s.lstrip().startswith("def ") or s.lstrip().startswith("class ")):
        end_line = j
        break

new_body = """def read_and_validate(path, m1_col=None, m2_col=None, p95_col=None):
    import pandas as pd
    # charge le CSV
    df = pd.read_csv(path)

    cols = list(df.columns)
    lower = {c.lower(): c for c in cols}

    # Résolution m1/m2
    if not m1_col or m1_col not in df.columns:
        m1_col = lower.get('m1', lower.get('mass1', lower.get('x', lower.get('phi0'))))
    if not m2_col or m2_col not in df.columns:
        m2_col = lower.get('m2', lower.get('mass2', lower.get('y', lower.get('phi_ref_fpeak'))))

    # Résolution p95
    if not p95_col or p95_col not in df.columns:
        try:
            # utilise la fonction existante si présente
            p95_col = detect_p95_column(df, p95_col)
        except Exception:
            cands = [c for c in df.columns if 'p95' in c.lower()]
            p95_col = cands[0] if cands else None

    if not m1_col or not m2_col or not p95_col:
        raise KeyError(f"Colonnes introuvables (m1={m1_col}, m2={m2_col}, p95={p95_col}).")

    # Conversion numérique + dropna
    keep = [m1_col, m2_col, p95_col]
    df = df[keep].apply(pd.to_numeric, errors='coerce').dropna()
    if df.shape[0] == 0:
        raise ValueError("Aucune ligne valable après conversion/NaN.")

    # Propager dans args si utile (pour main() qui fait df[args.m1_col]…)
    if 'args' in globals():
        try:
            if getattr(args, 'm1_col', None) is None: args.m1_col = m1_col
            if getattr(args, 'm2_col', None) is None: args.m2_col = m2_col
            if getattr(args, 'p95_col', None) is None: args.p95_col = p95_col
        except Exception:
            pass

    return df
"""

# remplace le bloc
new_src = "".join(lines[:start_line]) + new_body + "".join(lines[end_line:])
bak = p.with_suffix(p.suffix + ".bak_read_and_validate")
if not bak.exists():
    bak.write_text(src, encoding="utf-8")
p.write_text(new_src, encoding="utf-8")
print(f"[OK] read_and_validate(...) remplacée proprement dans {p}")
