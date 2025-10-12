import re, pathlib, sys

TARGET = pathlib.Path("zz-scripts/chapter09/generate_data_chapter09.py")
if not TARGET.exists():
    print(f"[ERREUR] Introuvable: {TARGET}", file=sys.stderr)
    sys.exit(2)

src = TARGET.read_text(encoding="utf-8")

# --- A) Nettoyage: si un helper a déjà été injecté au mauvais endroit, on le retire d'abord
src = re.sub(
    r"^\s*#\s*=== MCGT Hotfix: robust defaults.*?^def _mcgt_safe_float\([^\n]*\n(?:.*\n)*?^ +return float\(default\)\n",
    "",
    src,
    flags=re.MULTILINE
)

# --- Calculer l’endroit correct d’injection: après shebang/coding + bloc future-imports
lines = src.splitlines(keepends=True)
insert_idx = 0

# 1) sauter le shebang et l'éventuel coding cookie + docstring initial
while insert_idx < len(lines) and (lines[insert_idx].startswith("#!") or "coding:" in lines[insert_idx]):
    insert_idx += 1

# Si la ligne suivante est une docstring triple-quoted, avançons jusqu'à sa fermeture
def _is_triple_quote(line: str) -> bool:
    return (line.lstrip().startswith('"""') or line.lstrip().startswith("'''"))

if insert_idx < len(lines) and _is_triple_quote(lines[insert_idx]):
    quote = lines[insert_idx].lstrip()[:3]
    insert_idx += 1
    while insert_idx < len(lines) and quote not in lines[insert_idx]:
        insert_idx += 1
    if insert_idx < len(lines):
        insert_idx += 1  # inclure la ligne de fermeture

# 2) passer tous les from __future__ import ...
while insert_idx < len(lines) and re.match(r'^\s*from\s+__future__\s+import\s+', lines[insert_idx]):
    insert_idx += 1

# 3) passer les imports standards (pour garder le helper après imports si possible)
while insert_idx < len(lines) and re.match(r'^\s*(?:import\s+\S+|from\s+\S+\s+import\s+)', lines[insert_idx]):
    insert_idx += 1

# --- B) Préparer le helper
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

# Injecter le helper s’il n’existe pas
if "def _mcgt_safe_float(" not in src:
    src = "".join(lines[:insert_idx] + [helper] + lines[insert_idx:])

# --- C) Remplacements étendus
defaults = {
    "m1": 30.0,
    "m2": 25.0,
    "fmin": 20.0,
    "fmax": 300.0,
    "q0": 0.0,
    "phi_ref": 0.0,
}

total = 0

def _re_sub(pattern, repl, text, flags=0):
    global total
    new_text, n = re.subn(pattern, repl, text, flags=flags)
    if n:
        total += n
    return new_text, n

for k, dv in defaults.items():
    # float(cfg["k"]) / float( cfg [ 'k' ] )  avec espaces variés
    pat1 = rf'float\(\s*cfg\s*\[\s*["\']{re.escape(k)}["\']\s*\]\s*\)'
    src, _ = _re_sub(pat1, f'_mcgt_safe_float(cfg.get("{k}"), {dv})', src)

    # float(cfg.get("k"))  /  float( cfg . get ( 'k' ) )
    pat2 = rf'float\(\s*cfg\s*\.s*get\s*\(\s*["\']{re.escape(k)}["\']\s*\)\s*\)'
    # le \.s*get n’est pas valide → utilisons un groupe permissif
    pat2 = rf'float\(\s*cfg\s*\.\s*get\s*\(\s*["\']{re.escape(k)}["\']\s*\)\s*\)'
    src, _ = _re_sub(pat2, f'_mcgt_safe_float(cfg.get("{k}"), {dv})', src)

    # Affectations directes: m1 = float(...)
    pat3 = rf'^(\s*{re.escape(k)}\s*=\s*)float\((.*?)\)\s*$'
    repl3 = rf'\1_mcgt_safe_float(\2, {dv})'
    src, _ = _re_sub(pat3, repl3, src, flags=re.MULTILINE)

# Écrire
TARGET.write_text(src, encoding="utf-8")
print(f"[OK] Patch V2 appliqué ({total} remplacement(s)).")
