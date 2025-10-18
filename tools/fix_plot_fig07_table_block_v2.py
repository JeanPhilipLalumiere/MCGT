#!/usr/bin/env python3
from pathlib import Path
import re

p = Path("zz-scripts/chapter10/plot_fig07_synthesis.py")
src = p.read_text(encoding="utf-8")

# 0) Nettoyage des trucs du genre "table = try:"
src = re.sub(r'^([ \t]*)[A-Za-z_]\w*\s*=\s*try:\s*$', r'\1try:', src, flags=re.M)

call_token = "ax_tab.table("
idx = src.find(call_token)
if idx < 0:
    print("[SKIP] ax_tab.table(...) introuvable")
    raise SystemExit(0)

# Indentation de la ligne qui contient l'appel
bol = src.rfind("\n", 0, idx) + 1
indent = src[bol:idx]  # espaces/tabs avant 'a' de ax_tab.table(

# 1) Début du bloc à remplacer : remonte au-dessus de l'appel en englobant
#    tous les 'try:' consécutifs juste avant.
start = bol
scan_start = max(0, bol - 2000)
chunk = src[scan_start:bol]
try_re = re.compile(r'^[ \t]*try:\s*$', re.M)
matches = list(try_re.finditer(chunk))
if matches:
    # dernier try: avant l'appel
    t = matches[-1]
    # remonte pour inclure une éventuelle grappe de try: consécutifs
    s = t.start()
    while True:
        prev_nl = chunk.rfind("\n", 0, s-1)
        prev_bol = 0 if prev_nl == -1 else prev_nl + 1
        if try_re.match(chunk, prev_bol):
            s = prev_bol
            continue
        break
    start = scan_start + s

# 2) Fin de l'appel : équilibre les parenthèses à partir de 'ax_tab.table('
j = idx
depth, in_str = 0, None
while j < len(src):
    c = src[j]
    if in_str:
        if c == in_str and src[j-1] != "\\":
            in_str = None
    else:
        if c in ("'", '"'):
            in_str = c
        elif c == "(":
            depth += 1
        elif c == ")":
            depth -= 1
            if depth == 0:
                j += 1
                break
    j += 1

# 3) Étendre la fin pour englober les except/assignations/table=None + lignes vides/commentaires
end = j
while end < len(src):
    line_end = src.find("\n", end)
    if line_end == -1:
        line_end = len(src)
    line = src[end:line_end]
    ls = line.lstrip()
    if (ls.startswith("except ") or ls.startswith("except:") or
        ls.startswith("table = None") or ls.startswith("#") or ls == ""):
        end = line_end + 1
        continue
    break

# 4) Bloc canonique (une seule fois), avec la bonne indentation
block = (
    f"{indent}try:\n"
    f"{indent}    table = ax_tab.table(\n"
    f"{indent}        cellText=cell_text,\n"
    f"{indent}        colLabels=col_labels,\n"
    f"{indent}        cellLoc=\"center\",\n"
    f"{indent}        colLoc=\"center\",\n"
    f"{indent}        loc=\"center\",\n"
    f"{indent}    )\n"
    f"{indent}except IndexError:\n"
    f"{indent}    # Tableau vide -> ignorer l'annotation\n"
    f"{indent}    table = None\n"
)

fixed = src[:start] + block + src[end:]
if fixed != src:
    bak = p.with_suffix(p.suffix + ".bak_tablefix_v2")
    if not bak.exists():
        bak.write_text(src, encoding="utf-8")
    p.write_text(fixed, encoding="utf-8")
    print("[OK] normalisé : bloc ax_tab.table() replacé proprement")
else:
    print("[SKIP] rien à changer")
