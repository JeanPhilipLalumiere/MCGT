#!/usr/bin/env python3
from pathlib import Path
import re

p = Path("zz-scripts/chapter10/plot_fig07_synthesis.py")
src = p.read_text(encoding="utf-8")

# 0) Nettoyage des lignes du type "xxx = try:" qui traînent
src = re.sub(r'^([ \t]*)[A-Za-z_]\w*\s*=\s*try:\s*$',
             r'\1try:', src, flags=re.M)

lines = src.splitlines(True)

def find_line_containing(token: str):
    for i, ln in enumerate(lines):
        if token in ln:
            return i
    return -1

call_li = find_line_containing("ax_tab.table(")
if call_li < 0:
    print("[SKIP] ax_tab.table(...) introuvable")
    raise SystemExit(0)

# Indentation de la ligne qui contient l'appel
call_indent = lines[call_li][:len(lines[call_li]) - len(lines[call_li].lstrip(" \t"))]

# 1) Début du bloc à remplacer : remonte pour englober une grappe éventuelle de try:
start_li = call_li
i = call_li - 1
while i >= 0 and lines[i].strip() == "":
    i -= 1
# remonte au-dessus des 'try:' consécutifs
while i >= 0 and lines[i].lstrip().startswith("try:"):
    start_li = i
    i -= 1
    while i >= 0 and lines[i].strip() == "":
        start_li = i
        i -= 1

# 2) Fin du bloc à remplacer : on s’arrête au début du stylage du tableau
cfg_li = find_line_containing("table.auto_set_font_size(")
if cfg_li < 0:
    # fallback : si pas trouvé, on prend juste la fin de l’appel en équilibrant les parenthèses
    # puis on s’arrête avant la prochaine ligne non vide de même niveau d’indentation.
    # (cas rare, mais on couvre quand même)
    text_from_call = "".join(lines[call_li:])
    j, depth, in_str = 0, 0, None
    while j < len(text_from_call):
        c = text_from_call[j]
        if in_str:
            if c == in_str and text_from_call[j-1] != "\\":
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
    end_pos = j
    # remonte en lignes
    consumed = "".join(lines[call_li:])
    upto = consumed[:end_pos]
    end_li = call_li + upto.count("\n")
else:
    end_li = cfg_li  # on remplace jusqu'au stylage

# 3) Construit le bloc canonique
indent4 = ("\t" if "\t" in call_indent else "    ")
block = (
    f"{call_indent}try:\n"
    f"{call_indent}{indent4}# Si pas de données utiles, on laisse table=None\n"
    f"{call_indent}{indent4}if not cell_text:\n"
    f"{call_indent}{indent4}{indent4}table = None\n"
    f"{call_indent}{indent4}else:\n"
    f"{call_indent}{indent4}{indent4}table = ax_tab.table(\n"
    f"{call_indent}{indent4}{indent4}{indent4}cellText=cell_text,\n"
    f"{call_indent}{indent4}{indent4}{indent4}colLabels=col_labels,\n"
    f"{call_indent}{indent4}{indent4}{indent4}cellLoc=\"center\",\n"
    f"{call_indent}{indent4}{indent4}{indent4}colLoc=\"center\",\n"
    f"{call_indent}{indent4}{indent4}{indent4}loc=\"center\",\n"
    f"{call_indent}{indent4}{indent4})\n"
    f"{call_indent}except IndexError:\n"
    f"{call_indent}{indent4}# Tableau vide -> ignorer l'annotation\n"
    f"{call_indent}{indent4}table = None\n"
)

# 4) Remplace la zone [start_li, end_li)
new_lines = lines[:start_li] + [block] + lines[end_li:]
lines = new_lines

# 5) Enveloppe le stylage du tableau par un "if table is not None:"
#    On part de la ligne 'table.auto_set_font_size(' et on englobe jusqu'à ce que
#    l'indentation retombe strictement sous l'indentation de cette ligne.
cfg_li = find_line_containing("table.auto_set_font_size(")
if cfg_li >= 0:
    base_indent = lines[cfg_li][:len(lines[cfg_li]) - len(lines[cfg_li].lstrip(" \t"))]
    indent_unit = ("\t" if "\t" in base_indent else "    ")
    j = cfg_li
    # trouve la fin du bloc stylistique
    k = j
    while k < len(lines):
        ln = lines[k]
        if ln.strip() == "":
            k += 1
            continue
        ind = ln[:len(ln) - len(ln.lstrip(" \t"))]
        if len(ind) < len(base_indent):
            break
        # si on est revenu au même niveau mais que la ligne ne commence pas par "table."
        # et n'est pas la boucle 'for (r, c)...', on considère que le bloc s'arrête
        if (len(ind) == len(base_indent)
            and not ln.lstrip().startswith("table.")
            and not ln.lstrip().startswith("for ")):
            break
        k += 1
    # extrait et indente
    styl_lines = lines[j:k]
    styl_lines_indented = [base_indent + indent_unit + s if s.strip() != "" else s for s in styl_lines]
    guard = f"{base_indent}if table is not None:\n"
    lines = lines[:j] + [guard] + styl_lines_indented + lines[k:]

fixed = "".join(lines)

if fixed != src:
    bak = p.with_suffix(p.suffix + ".bak_tablefix_v3")
    if not bak.exists():
        bak.write_text(src, encoding="utf-8")
    p.write_text(fixed, encoding="utf-8")
    print("[OK] patch appliqué : bloc table normalisé + stylage sous garde")
else:
    print("[SKIP] rien à changer")
