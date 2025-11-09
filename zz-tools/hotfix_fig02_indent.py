# zz-tools/hotfix_fig02_indent.py
#!/usr/bin/env python3
from pathlib import Path
import re, sys

p = Path("zz-scripts/chapter09/plot_fig02_residual_phase.py")
s = p.read_text(encoding="utf-8")

# Normalise des indentations aberrantes de 8+ espaces à 4 dans un petit bloc heuristique
s_new = re.sub(
    r"(?m)^( {8,})(for c in \(\"f_Hz\", \"phi_ref\".*)$",
    r"    \2",
    s
)
s_new = re.sub(
    r"(?m)^( {12,})(if c not in df\.columns:.*)$",
    r"        \2",
    s_new
)
if s_new != s:
    p.write_text(s_new, encoding="utf-8")
    print("[OK] Indentation fig02 corrigée (heuristique).")
else:
    print("[INFO] Rien à corriger (ou motif non trouvé).")
