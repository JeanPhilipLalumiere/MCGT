import re
import pathlib
import sys
import ast

TARGET = pathlib.Path("scripts/chapter09/generate_data_chapter09.py")
if not TARGET.exists():
    print(f"[ERREUR] Introuvable: {TARGET}", file=sys.stderr)
    sys.exit(2)
src = TARGET.read_text(encoding="utf-8")

# 1) Retirer toute ancienne version du helper (même partielle)
src = re.sub(
    r"(?s)^\s*#\s*=== MCGT Hotfix:.*?def _mcgt_safe_float\([^)]*\):.*?^\s*return float\(default\)\s*$\n?",
    "",
    src,
    flags=re.MULTILINE,
)

# 2) Supprimer débris orphelins en colonne 0 (introduits par précédents patchs)
src = re.sub(r"(?m)^\s*return float\(x\)\s*$", "", src)
src = re.sub(r"(?m)^\s*except Exception:\s*$", "", src)
src = re.sub(r"(?m)^\s*return float\(default\)\s*$", "", src)
# Recompactage multi-blancs en un seul
src = re.sub(r"\n{3,}", "\n\n", src)

# 3) Extraire shebang + docstring d’en-tête
lines = src.splitlines(keepends=True)
i = 0


def is_shebang(l):
    return l.startswith("#!")


def is_blank(l):
    return l.strip() == ""


def is_doc_start(l):
    s = l.lstrip()
    return s.startswith('"""') or s.startswith("'''")


head, doc = [], []
# shebang + blancs initiaux
while i < len(lines) and (is_shebang(lines[i]) or is_blank(lines[i])):
    head.append(lines[i])
    i += 1

# docstring (multi-ligne)
if i < len(lines) and is_doc_start(lines[i]):
    q = lines[i].lstrip()[:3]
    doc.append(lines[i])
    i += 1
    if doc[0].lstrip().count(q) == 1:
        # pas fermé sur la même ligne
        while i < len(lines):
            doc.append(lines[i])
            if q in lines[i]:
                i += 1
                break
            i += 1

rest = "".join(lines[i:])

# 4) Récupérer tous les future-imports (depuis n’importe où), les enlever du corps
futures = re.findall(
    r"^\s*from\s+__future__\s+import\s+[^\n]+", rest, flags=re.MULTILINE
)
rest = re.sub(
    r"^\s*from\s+__future__\s+import\s+[^\n]+\n?", "", rest, flags=re.MULTILINE
)
# Dedup + ordre stable
futures = list(dict.fromkeys(futures))

# 5) Préparer helper unique bien indenté
helper = (
    "\n"
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


# 6) Renforcer quelques conversions (idempotent)
def reinforce(txt: str) -> str:
    # cfg[...] / cfg.get(...) -> helper avec défauts sains
    for k, dv in {"m1": 30.0, "m2": 25.0, "fmin": 20.0, "fmax": 300.0}.items():
        txt = re.sub(
            rf'float\(\s*cfg\s*\[\s*["\']{re.escape(k)}["\']\s*\]\s*\)',
            f'_mcgt_safe_float(cfg.get("{k}"), {dv})',
            txt,
        )
        txt = re.sub(
            rf'float\(\s*cfg\s*\.?\s*get\(\s*["\']{re.escape(k)}["\']\s*\)\s*\)',
            f'_mcgt_safe_float(cfg.get("{k}"), {dv})',
            txt,
        )
    # nanmin/nanmax sur f -> helper
    txt = re.sub(
        r"float\(\s*np\.nanmin\(\s*f\s*\)\s*\)",
        "_mcgt_safe_float(np.nanmin(f), 20.0)",
        txt,
    )
    txt = re.sub(
        r"float\(\s*np\.nanmax\(\s*f\s*\)\s*\)",
        "_mcgt_safe_float(np.nanmax(f), 300.0)",
        txt,
    )
    return txt


rest = reinforce(rest)


# 7) Recomposition: shebang/docstring -> futures -> helper -> reste
def J(s):
    s = "".join(s).rstrip("\n")
    return (s + "\n") if s else ""


new_src = J(head) + J(doc)
if futures:
    new_src += "\n".join(futures) + "\n"
else:
    # S’il n’y avait aucun future, insérer annotations par défaut (beaucoup de code en dépend)
    new_src += "from __future__ import annotations\n"
new_src += helper
new_src += "\n" + rest.lstrip("\n")

# Nettoyage final de blancs multiples
new_src = re.sub(r"\n{3,}", "\n\n", new_src)

# 8) Validation syntaxe
try:
    ast.parse(new_src)
except SyntaxError as e:
    print("[ERREUR] SyntaxError après patch:", e)
    ctx = new_src.splitlines()
    lo = max(0, (e.lineno or 1) - 6)
    hi = min(len(ctx), (e.lineno or 1) + 5)
    for ln in range(lo, hi):
        mark = ">>" if (ln + 1) == e.lineno else "  "
        print(f"{mark} {ln + 1:4d}: {ctx[ln]}")
    sys.exit(3)

TARGET.write_text(new_src, encoding="utf-8")
print("[OK] Patch V8 appliqué. Syntaxe valide et header reconstruit.")
