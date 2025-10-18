#!/usr/bin/env python3
from pathlib import Path

p = Path("zz-scripts/chapter10/plot_fig07_synthesis.py")
s = p.read_text(encoding="utf-8")
lines = s.splitlines(True)

def leading(ws: str) -> str:
    return ws[:len(ws) - len(ws.lstrip(" \t"))]

# 1) repère la ligne avec ax_tab.axis('off')
axis_ix = next((i for i,l in enumerate(lines)
                if "ax_tab.axis(\"off\")" in l or "ax_tab.axis('off')" in l), -1)
if axis_ix < 0:
    print("[SKIP] ax_tab.axis('off') introuvable")
    raise SystemExit(0)

base_indent = leading(lines[axis_ix])

# 2) repère le prochain 'try:' après cette ligne
try_ix = next((i for i in range(axis_ix+1, len(lines))
               if lines[i].lstrip().startswith("try:")), -1)
if try_ix < 0:
    print("[SKIP] try: suivant introuvable")
    raise SystemExit(0)

try_indent = leading(lines[try_ix])

# 3) si déjà aligné, rien à faire
if len(try_indent) == len(base_indent):
    print("[SKIP] indentation déjà correcte")
else:
    # fin du bloc = ligne 'if table is not None:' (garde stylage)
    end_ix = next((i for i in range(try_ix, len(lines))
                   if lines[i].lstrip().startswith("if table is not None:")), -1)
    if end_ix < 0:
        # fallback: s'arrête quand on redescend à <= base_indent
        end_ix = try_ix + 1
        def is_end(ln):
            ls = ln.lstrip()
            return ln.strip() and len(leading(ln)) <= len(base_indent) and not ls.startswith(("except", "finally", "else:"))
        while end_ix < len(lines) and not is_end(lines[end_ix]):
            end_ix += 1

    # 4) dé-dente exactement l'excédent
    extra = try_indent[len(base_indent):]

    def dedent_prefix(ln: str) -> str:
        if ln.startswith(base_indent + extra):
            return base_indent + ln[len(base_indent + extra):]
        if ln.startswith(extra):
            return ln[len(extra):]
        return ln

    for i in range(try_ix, end_ix):
        if lines[i].strip():
            lines[i] = dedent_prefix(lines[i])

    p.write_text("".join(lines), encoding="utf-8")
    print(f"[OK] dé-denté le bloc try/except ({try_ix+1}-{end_ix}) pour l'aligner sur ax_tab.axis('off')")
