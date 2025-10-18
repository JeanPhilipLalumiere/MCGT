#!/usr/bin/env python3
from pathlib import Path
import re

p = Path("zz-scripts/chapter10/plot_fig01_iso_p95_maps.py")
src = p.read_text(encoding="utf-8").replace("\t", "    ").splitlines(True)

def find_block(lines, start_pat):
    si = None
    for i,s in enumerate(lines):
        if re.match(start_pat, s):
            si = i; break
    if si is None: return None, None
    base = len(src[si]) - len(src[si].lstrip(" "))
    ei = len(lines)
    for j in range(si+1, len(lines)):
        t = lines[j]
        if t.strip()=="": continue
        ind = len(t) - len(t.lstrip(" "))
        if ind <= base and (t.lstrip().startswith("def ") or t.lstrip().startswith("class ")):
            ei = j; break
    return si, ei

start, end = find_block(src, r'^[ ]*def[ ]+ensure_fig01_cols\(')
if start is None:
    raise SystemExit("[ERR] def ensure_fig01_cols(...) introuvable")

new_block = """
def ensure_fig01_cols(df):
    \"\"\"Retourne un DataFrame avec (m1_col, m2_col, p95_col) nettoyés.
    - Si df est None, on tente de lire --results.
    - Les noms de colonnes peuvent venir de args.* (shim) sinon défauts: m1, m2, p95_20_300.
    \"\"\"
    import pandas as pd, sys as _sys
    try:
        args  # fourni par le shim
    except NameError:
        args = None

    # charge df depuis --results si besoin
    if df is None:
        _res = None
        if args is not None and getattr(args, "results", None):
            _res = args.results
        else:
            av = _sys.argv
            for j,a in enumerate(av):
                if a == "--results" and j+1 < len(av):
                    _res = av[j+1]; break
        if _res is None:
            raise RuntimeError("ensure_fig01_cols: impossible d'inférer le CSV (args.results manquant).")
        df = pd.read_csv(_res)

    # noms de colonnes
    m1_col  = getattr(args, "m1_col", "m1")  if args else "m1"
    m2_col  = getattr(args, "m2_col", "m2")  if args else "m2"
    p95_col = getattr(args, "p95_col", "p95_20_300") if args else "p95_20_300"

    # validations & nettoyage
    for col in (m1_col, m2_col, p95_col):
        if col not in df.columns:
            raise KeyError(f"Colonne attendue absente: {col}")
    df = df[[m1_col, m2_col, p95_col]].dropna().astype(float)
    if df.shape[0] == 0:
        raise ValueError("Aucune donnée valide après suppression des NaN.")

    return df
""".lstrip("\n").replace("\t","    ")

backup = p.with_suffix(p.suffix + ".bak_fullfunc")
if not backup.exists():
    backup.write_text("".join(src), encoding="utf-8")

src[start:end] = [new_block]
p.write_text("".join(src), encoding="utf-8")
print("[OK] ensure_fig01_cols remplacée proprement.")
