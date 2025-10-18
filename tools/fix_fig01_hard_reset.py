#!/usr/bin/env python3
from pathlib import Path
import re, sys

F = Path("zz-scripts/chapter10/plot_fig01_iso_p95_maps.py")
src = F.read_text(encoding="utf-8").replace("\t","    ")
lines = src.splitlines(True)

def find_insert_index(lines):
    i = 0
    # shebang
    if i < len(lines) and lines[i].startswith("#!"):
        i += 1
    # blanks
    while i < len(lines) and lines[i].strip() == "":
        i += 1
    # module docstring
    if i < len(lines) and lines[i].lstrip().startswith(('"""',"'''")):
        q = lines[i].lstrip()[:3]
        i += 1
        while i < len(lines):
            if lines[i].strip().endswith(q):
                i += 1
                break
            i += 1
    # __future__ imports
    while i < len(lines) and lines[i].lstrip().startswith("from __future__ import"):
        i += 1
    # blanks
    while i < len(lines) and lines[i].strip() == "":
        i += 1
    return i

def at_col0(s, prefix):
    return s.startswith(prefix)  # déjà tabs→spaces

def comment_range(a, b):
    for k in range(a, b+1):
        if not lines[k].lstrip().startswith("#"):
            lines[k] = "# FIXCUT " + lines[k]

# 1) Insère une version propre de ensure_fig01_cols si absente
has_ensure = any(re.match(r'^[ ]*def[ ]+ensure_fig01_cols\(', s) for s in lines)
if not has_ensure:
    insert_at = find_insert_index(lines)
    new_func = """
def ensure_fig01_cols(df):
    \"\"\"Charge/valide les colonnes (m1,m2,p95) et retourne un DataFrame nettoyé.
    - Si df est None, lit --results (via args ou argv).
    - Noms par défaut: m1, m2, p95_20_300 (surchargés via args si présents).
    \"\"\"
    import pandas as pd, sys as _sys
    try:
        args  # fourni par le shim
    except NameError:
        args = None

    # 1) charge df si besoin
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
            raise RuntimeError("ensure_fig01_cols: --results introuvable.")
        df = pd.read_csv(_res)

    # 2) noms colonnes
    m1_col  = getattr(args, "m1_col", "m1")  if args else "m1"
    m2_col  = getattr(args, "m2_col", "m2")  if args else "m2"
    p95_col = getattr(args, "p95_col", "p95_20_300") if args else "p95_20_300"

    # 3) validations + cast
    for col in (m1_col, m2_col, p95_col):
        if col not in df.columns:
            raise KeyError(f"Colonne attendue absente: {col}")
    df = df[[m1_col, m2_col, p95_col]].dropna().astype(float)
    if df.shape[0] == 0:
        raise ValueError("Aucune donnée valide après suppression des NaN.")
    return df

""".lstrip("\n")
    lines[insert_at:insert_at] = [new_func]

# 2) Commente le vieux bloc “fuyant” au niveau module
start_idx = None
end_idx = None

# On préfère commencer à 'if False:' en colonne 0 s'il existe, sinon à 'for col in (m1_col...' en colonne 0
for i,s in enumerate(lines):
    if at_col0(s, "if False:"):
        start_idx = i
        break
if start_idx is None:
    for i,s in enumerate(lines):
        if at_col0(s, "for col in (m1_col"):
            start_idx = i
            break

if start_idx is not None:
    # on va jusqu'à 'return df' (col 0) si on le trouve, sinon jusqu'au prochain 'def ' (col 0)
    for j in range(start_idx, len(lines)):
        t = lines[j]
        if at_col0(t, "return df"):
            end_idx = j
            break
    if end_idx is None:
        for j in range(start_idx+1, len(lines)):
            t = lines[j]
            if at_col0(t, "def "):
                end_idx = j-1
                break
    if end_idx is None:
        end_idx = start_idx  # au moins la 1re ligne

    comment_range(start_idx, end_idx)

# 3) Sauvegarde + écriture
bak = F.with_suffix(F.suffix + ".bak_hardreset")
if not bak.exists():
    bak.write_text(src, encoding="utf-8")
F.write_text("".join(lines), encoding="utf-8")
print("[OK] fig01: ensure() sain inséré et ancien bloc commenté.")
