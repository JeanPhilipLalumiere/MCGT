import re, pathlib, sys

TARGET = pathlib.Path("zz-scripts/chapter09/generate_data_chapter09.py")
if not TARGET.exists():
    print(f"[ERREUR] Introuvable: {TARGET}", file=sys.stderr)
    sys.exit(2)

src = TARGET.read_text(encoding="utf-8")

# --- A) Retirer tout helper déjà injecté (où qu'il soit)
src = re.sub(
    r"(?ms)^\s*#\s*=== MCGT Hotfix: robust defaults.*?^def _mcgt_safe_float\([^)]*\):.*?^ {0,8}return float\(default\)\s*$",
    "",
    src,
)

# --- B) Calculer l’emplacement d’injection correct
lines = src.splitlines(keepends=True)

def is_shebang(l): return l.startswith("#!")
def is_coding(l): return "coding:" in l
def is_triple_start(l):
    s = l.lstrip()
    return s.startswith('"""') or s.startswith("'''")
def is_future(l): return re.match(r'^\s*from\s+__future__\s+import\s+', l) is not None
def is_import(l): return re.match(r'^\s*(?:import\s+\S+|from\s+\S+\s+import\s+)', l) is not None

i = 0
# 1) shebang + coding
while i < len(lines) and (is_shebang(lines[i]) or is_coding(lines[i]) or (len(lines[i].strip())==0)):
    i += 1

# 2) docstring module si présent
if i < len(lines) and is_triple_start(lines[i]):
    q = lines[i].lstrip()[:3]
    i += 1
    while i < len(lines) and q not in lines[i]:
        i += 1
    if i < len(lines):
        i += 1  # inclure la fermeture

# 3) regrouper tous les future-imports
j = i
while j < len(lines) and is_future(lines[j]):
    j += 1

# Position d’injection = juste après le dernier future-import si présent,
# sinon après docstring/shebang (i)
insert_idx = j if j > i else i

# Important: NE PAS casser le shebang — s'il existe, forçons insert après 1ère ligne
if len(lines) > 0 and is_shebang(lines[0]) and insert_idx == 0:
    insert_idx = 1

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

if "def _mcgt_safe_float(" not in src:
    src = "".join(lines[:insert_idx] + [helper] + lines[insert_idx:])
    lines = src.splitlines(keepends=True)

# --- C) Remplacements étendus
defaults = {
    "m1": 30.0,
    "m2": 25.0,
    "fmin": 20.0,
    "fmax": 300.0,
}
total = 0
def subn(pat, repl, txt, flags=0):
    global total
    new, n = re.subn(pat, repl, txt, flags=flags)
    total += n
    return new

for k, dv in defaults.items():
    # float(cfg["k"])
    pat1 = rf'float\(\s*cfg\s*\[\s*["\']{re.escape(k)}["\']\s*\]\s*\)'
    src  = subn(pat1, f'_mcgt_safe_float(cfg.get("{k}"), {dv})', src)

    # float(cfg.get("k"))
    pat2 = rf'float\(\s*cfg\s*\.\s*get\s*\(\s*["\']{re.escape(k)}["\']\s*\)\s*\)'
    src  = subn(pat2, f'_mcgt_safe_float(cfg.get("{k}"), {dv})', src)

    # affectations directes: k = float(...)
    pat3 = rf'^(\s*{re.escape(k)}\s*=\s*)float\((.*?)\)\s*$'
    repl3 = rf'\1_mcgt_safe_float(\2, {dv})'
    src  = subn(pat3, repl3, src, flags=re.MULTILINE)

TARGET.write_text(src, encoding="utf-8")
print(f"[OK] Patch V3 appliqué ({total} remplacement(s)).")
