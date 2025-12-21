import re
import pathlib
import sys
import ast

TARGET = pathlib.Path("scripts/chapter09/generate_data_chapter09.py")
if not TARGET.exists():
    print(f"[ERREUR] Introuvable: {TARGET}", file=sys.stderr)
    sys.exit(2)

src = TARGET.read_text(encoding="utf-8")

# A) Retirer tout helper précédemment injecté
src = re.sub(
    r"(?ms)^\s*#\s*=== MCGT Hotfix: robust defaults.*?^def _mcgt_safe_float\([^)]*\):.*?^\s*return float\(default\)\s*$",
    "",
    src,
)

# B) Trouver l’emplacement correct: après docstring initiale (si présente) et après TOUTES les lignes `from __future__ import ...`
lines = src.splitlines(keepends=True)


def is_shebang(l):
    return l.startswith("#!")


def is_coding(l):
    return "coding:" in l


def is_blank(l):
    return l.strip() == ""


def is_doc_start(l):
    s = l.lstrip()
    return s.startswith('"""') or s.startswith("'''")


def is_future(l):
    return re.match(r"^\s*from\s+__future__\s+import\s+", l) is not None


i = 0
while i < len(lines) and (
    is_shebang(lines[i]) or is_coding(lines[i]) or is_blank(lines[i])
):
    i += 1

# Docstring initiale (ligne unique ou bloc)
if i < len(lines) and is_doc_start(lines[i]):
    q = lines[i].lstrip()[:3]
    if lines[i].count(q) >= 2:  # docstring sur une seule ligne
        i += 1
    else:
        i += 1
        while i < len(lines) and q not in lines[i]:
            i += 1
        if i < len(lines):
            i += 1

# Bloc de futures consécutifs
j = i
while j < len(lines) and is_future(lines[j]):
    j += 1

insert_pos = sum(len(l) for l in lines[:j])

helper = (
    "\n\n"
    '# === MCGT Hotfix: robust defaults when cfg has None/"" ===\n'
    "def _mcgt_safe_float(x, default):\n"
    "    try:\n"
    '        if x is None or (isinstance(x, str) and x.strip() == ""):\n'
    "            return float(default)\n"
    "        return float(x)\n"
    "    except Exception:\n"
    "        return float(default)\n"
    "\n"
)

if "def _mcgt_safe_float(" not in src:
    src = src[:insert_pos] + helper + src[insert_pos:]


# C) Durcir les conversions (idempotent)
def total_subs(txt):
    total = 0

    def subn(pat, repl, flags=0):
        nonlocal txt, total
        new, n = re.subn(pat, repl, txt, flags=flags)
        txt = new
        total += n

    for k, dv in {"m1": 30.0, "m2": 25.0, "fmin": 20.0, "fmax": 300.0}.items():
        subn(
            rf'float\(\s*cfg\s*\[\s*["\']{re.escape(k)}["\']\s*\]\s*\)',
            f'_mcgt_safe_float(cfg.get("{k}"), {dv})',
        )
        subn(
            rf'float\(\s*cfg\s*\.?\s*get\(\s*["\']{re.escape(k)}["\']\s*\)\s*\)',
            f'_mcgt_safe_float(cfg.get("{k}"), {dv})',
        )
        subn(
            rf"^(\s*{re.escape(k)}\s*=\s*)float\((.*?)\)\s*$",
            rf"\1_mcgt_safe_float(\2, {dv})",
            flags=re.MULTILINE,
        )
    return txt, total


src, nsubs = total_subs(src)

# D) Écrire + valider la syntaxe
TARGET.write_text(src, encoding="utf-8")
try:
    ast.parse(src)
    print(f"[OK] Patch V6 appliqué et syntaxe valide ({nsubs} remplacement(s)).")
except SyntaxError as e:
    print("[ERREUR] SyntaxError après patch:")
    print(f"  {e.msg} (ligne {e.lineno}, col {e.offset})")
    # Afficher un contexte de 10 lignes autour
    context = src.splitlines()
    lo = max(0, (e.lineno or 1) - 6)
    hi = min(len(context), (e.lineno or 1) + 5)
    for ln in range(lo, hi):
        mark = ">>" if (ln + 1) == e.lineno else "  "
        print(f"{mark} {ln + 1:4d}: {context[ln]}")
    sys.exit(3)
