#!/usr/bin/env python3
from pathlib import Path
import re

p = Path("zz-scripts/chapter10/plot_fig07_synthesis.py")
s = p.read_text(encoding="utf-8")

# --- 1) Injecte le helper s'il n'existe pas encore ---
if "def safe_make_table(" not in s:
    # place le helper après le dernier import
    m = list(re.finditer(r'^(?:from\s+\S+\s+import\s+.+|import\s+\S+.*)$', s, re.M))
    insert_at = m[-1].end() if m else 0
    helper = """

def safe_make_table(ax_tab, cell_text, col_labels):
    \"\"\"Construit le tableau si utile, sinon None (sans lever d'IndexError).\"\"\"
    if not cell_text:
        return None
    try:
        t = ax_tab.table(
            cellText=cell_text,
            colLabels=col_labels,
            cellLoc="center",
            colLoc="center",
            loc="center",
        )
        return t
    except IndexError:
        return None

"""
    s = s[:insert_at] + helper + s[insert_at:]

# --- 2) Nettoie d'éventuels restes de patchs ("xxx = try:") ---
s = re.sub(r'^[ \t]*[A-Za-z_]\w*\s*=\s*try:\s*$', 'try:', s, flags=re.M)

# --- 3) Remplace le bloc après ax_tab.axis('off') jusqu'à "slopes = []" ---
axis = re.search(r'^[ \t]*ax_tab\.axis\(["\']off["\']\)\s*$', s, flags=re.M)
slopes = re.search(r'^[ \t]*slopes\s*=\s*\[\]\s*$', s, flags=re.M)

if axis and slopes and slopes.start() > axis.end():
    before = s[:axis.end()]
    after  = s[slopes.start():]
    new_block = """

table = safe_make_table(ax_tab, cell_text, col_labels)
if table is not None:
    table.auto_set_font_size(False)
    table.set_fontsize(10)
    table.scale(1.0, 1.3)
    for (r, c), cell in table.get_celld().items():
        cell.set_edgecolor("0.3")
        cell.set_linewidth(0.8)
        if r == 0:
            cell.set_height(cell.get_height() * 1.15)
        if c == 0:
            cell.set_width(cell.get_width() * 1.85)

"""
    s = before + new_block + after

p.write_text(s, encoding="utf-8")
print("[OK] helper intégré et bloc table normalisé")
