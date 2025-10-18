#!/usr/bin/env python3
from pathlib import Path
import re

p = Path("zz-scripts/chapter10/plot_fig07_synthesis.py")
s = p.read_text(encoding="utf-8")
lines = s.splitlines(True)

def leading(ws: str) -> str:
    return ws[:len(ws) - len(ws.lstrip(" \t"))]

# 1) localise la ligne 'ax_tab.axis("off")' (ou '...\'off\')'
axis_ix = next((i for i,l in enumerate(lines)
                if re.search(r'ax_tab\.axis\((?:\"|\')off(?:\"|\')\)', l)), -1)
if axis_ix < 0:
    raise SystemExit("[ERR] ax_tab.axis('off') introuvable")

base_indent = leading(lines[axis_ix])

# 2) localise la borne de fin du bloc (ligne 'slopes = []')
slopes_ix = next((i for i in range(axis_ix+1, len(lines))
                  if re.match(r'^\s*slopes\s*=\s*\[\]\s*$', lines[i])), -1)
if slopes_ix < 0:
    raise SystemExit("[ERR] borne 'slopes = []' introuvable après ax_tab.axis('off')")

# 3) construit le bloc "safe table", indenté comme la ligne axis
block = [
"table = safe_make_table(ax_tab, cell_text, col_labels)\n",
"if table is not None:\n",
"    table.auto_set_font_size(False)\n",
"    table.set_fontsize(10)\n",
"    table.scale(1.0, 1.3)\n",
"    for (r, c), cell in table.get_celld().items():\n",
"        cell.set_edgecolor(\"0.3\")\n",
"        cell.set_linewidth(0.8)\n",
"        if r == 0:\n",
"            cell.set_height(cell.get_height() * 1.15)\n",
"        if c == 0:\n",
"            cell.set_width(cell.get_width() * 1.85)\n",
"\n",
]
block = [(base_indent + ln) for ln in block]

# 4) remplace tout ce qu’il y a entre axis_ix et slopes_ix par notre bloc bien indenté
new_lines = lines[:axis_ix+1] + block + lines[slopes_ix:]
p.write_text("".join(new_lines), encoding="utf-8")
print("[OK] bloc safe_table ré-indenté entre lignes", axis_ix+2, "et", slopes_ix)
