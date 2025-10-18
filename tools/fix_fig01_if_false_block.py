#!/usr/bin/env python3
from pathlib import Path
import re, sys

path = Path("zz-scripts/chapter10/plot_fig01_iso_p95_maps.py")
txt = path.read_text(encoding="utf-8").replace("\t","    ")
lines = txt.splitlines(True)

def indent(s): return len(s) - len(s.lstrip(" "))

# 1) repère la 1re occurrence de "if False:"
i_if = next((i for i,s in enumerate(lines) if "if False:" in s), None)
if i_if is None:
    print("[SKIP] Pas de 'if False:' trouvé"); sys.exit(0)

# 2) indent de base = dernière ligne non vide avant i_if
j = i_if-1
while j >= 0 and lines[j].strip() == "":
    j -= 1
base = indent(lines[j]) if j>=0 else 0
base_str = " " * base
body4   = " " * (base+4)
body8   = " " * (base+8)

# 3) force 'if False:' au niveau base, et sa 1re ligne utile au niveau base+4
lines[i_if] = f"{base_str}if False:\n"
k = i_if+1
while k < len(lines) and lines[k].strip()=="":
    k += 1
if k < len(lines):
    lines[k] = body4 + lines[k].lstrip(" ")

# 4) normalise les lignes suivantes clés au niveau attendu (base+4 / +8)
pat_levels = [
    (re.compile(r'^\s*for\s+col\s+in\s*\(m1_col,\s*m2_col,\s*p95_col\)\s*:\s*$'), body4),
    (re.compile(r'^\s*if\s+col\s+not\s+in\s+df\.columns\b.*$'),                     body8),
    (re.compile(r'^\s*df\s*=\s*df\[\[m1_col,\s*m2_col,\s*p95_col\]\]\.dropna\(\)\.astype\(float\).*'), body4),
    (re.compile(r'^\s*if\s+df\.shape\[0\]\s*==\s*0\b.*$'),                           body4),
    (re.compile(r'^\s*return\s+df\s*$'),                                            body4),
]

# on ne touche qu'à partir de i_if vers le bas (jusqu'à prochain def/class au niveau <= base)
end = len(lines)
for t in range(i_if+1, len(lines)):
    s = lines[t]
    if s.strip()=="":
        continue
    if indent(s) <= base and (s.lstrip().startswith("def ") or s.lstrip().startswith("class ")):
        end = t
        break

for t in range(i_if+1, end):
    s = lines[t]
    for rgx, lead in pat_levels:
        if rgx.match(s):
            lines[t] = lead + s.lstrip(" ")
            break

new = "".join(lines)
if new != txt:
    path.write_text(new, encoding="utf-8")
    print("[PATCH] fig01: bloc 'if False' et suite re-indentés (alignés sur le niveau fonction).")
else:
    print("[INFO] fig01: rien à changer.")
