import re
import pathlib
import sys

TARGET = pathlib.Path("zz-scripts/chapter09/generate_data_chapter09.py")
if not TARGET.exists():
    print(f"[ERREUR] Introuvable: {TARGET}", file=sys.stderr)
    sys.exit(2)

src = TARGET.read_text(encoding="utf-8")

# A) Retirer tout helper injecté précédemment (où qu'il soit)
src = re.sub(
    r"(?ms)^\s*#\s*=== MCGT Hotfix: robust defaults.*?^def _mcgt_safe_float\([^)]*\):.*?^ {0,8}return float\(default\)\s*$",
    "",
    src,
)

helper = """
# === MCGT Hotfix: robust defaults when cfg has None/"" ===
def _mcgt_safe_float(x, default):
    try:
        if x is None or (isinstance(x, str) and x.strip() == ""):
            return float(default)
        return float(x)
    except Exception:
        return float(default)
"""

# B) Trouver l’endroit d’insertion :
#    1) après la première occurrence de "from __future__ import ..."
m = re.search(r"(?m)^from\s+__future__\s+import\s+.*$", src)
if m:
    # insérer juste après cette ligne (et son \n)
    endline = m.end()
    # avancer jusqu'au \n suivant si on est en plein milieu
    nlpos = src.find("\n", endline)
    insert_pos = len(src) if nlpos == -1 else nlpos + 1
else:
    # Sinon: après shebang/coding/docstring
    lines = src.splitlines(keepends=True)
    i = 0

    def is_shebang(l):
        return l.startswith("#!")

    def is_coding(l):
        return "coding:" in l

    def is_triple_start(l):
        s = l.lstrip()
        return s.startswith('"""') or s.startswith("'''")

    while i < len(lines) and (
        is_shebang(lines[i]) or is_coding(lines[i]) or lines[i].strip() == ""
    ):
        i += 1
    if i < len(lines) and is_triple_start(lines[i]):
        q = lines[i].lstrip()[:3]
        i += 1
        while i < len(lines) and q not in lines[i]:
            i += 1
        if i < len(lines):
            i += 1
    insert_pos = sum(len(l) for l in lines[:i])

# C) Injecter le helper s’il n’existe pas déjà
if "def _mcgt_safe_float(" not in src:
    src = src[:insert_pos] + helper + src[insert_pos:]

# D) Renforcer les conversions sur quelques clés critiques
defaults = {"m1": 30.0, "m2": 25.0, "fmin": 20.0, "fmax": 300.0}
total = 0


def subn(pat, repl, txt, flags=0):
    global total
    new, n = re.subn(pat, repl, txt, flags=flags)
    total += n
    return new


for k, dv in defaults.items():
    # float(cfg["k"])
    pat1 = rf'float\(\s*cfg\s*\[\s*["\']{re.escape(k)}["\']\s*\]\s*\)'
    src = subn(pat1, f'_mcgt_safe_float(cfg.get("{k}"), {dv})', src)
    # float(cfg.get("k"))
    pat2 = rf'float\(\s*cfg\s*\.\s*get\s*\(\s*["\']{re.escape(k)}["\']\s*\)\s*\)'
    src = subn(pat2, f'_mcgt_safe_float(cfg.get("{k}"), {dv})', src)
    # k = float(...)
    pat3 = rf"^(\s*{re.escape(k)}\s*=\s*)float\((.*?)\)\s*$"
    repl3 = rf"\1_mcgt_safe_float(\2, {dv})"
    src = subn(pat3, repl3, src, flags=re.MULTILINE)

TARGET.write_text(src, encoding="utf-8")
print(f"[OK] Patch V4 appliqué ({total} remplacement(s)).")
