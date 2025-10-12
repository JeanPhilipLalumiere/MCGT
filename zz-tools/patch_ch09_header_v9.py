import re, pathlib, sys, ast

TARGET = pathlib.Path("zz-scripts/chapter09/generate_data_chapter09.py")
if not TARGET.exists():
    print(f"[ERREUR] Introuvable: {TARGET}", file=sys.stderr); sys.exit(2)
src = TARGET.read_text(encoding="utf-8")

# --- 1) Enlever toute ancienne version du helper (même partielle)
src = re.sub(
    r"(?s)^\s*#\s*=== MCGT Hotfix:.*?def _mcgt_safe_float\([^)]*\):.*?^\s*return float\(default\)\s*$\n?",
    "",
    src,
    flags=re.MULTILINE,
)

# --- 2) Extraire shebang + docstring d’en-tête
lines = src.splitlines(keepends=True)
i = 0
def is_shebang(l): return l.startswith("#!")
def is_blank(l): return l.strip() == ""
def is_doc_start(l):
    s = l.lstrip()
    return s.startswith('"""') or s.startswith("'''")

head = []
while i < len(lines) and (is_shebang(lines[i]) or is_blank(lines[i])):
    head.append(lines[i]); i += 1

doc = []
if i < len(lines) and is_doc_start(lines[i]):
    quote = lines[i].lstrip()[:3]
    doc.append(lines[i]); i += 1
    # docstring multi-lignes jusqu'à fermeture
    if doc[0].lstrip().count(quote) == 1:
        while i < len(lines):
            doc.append(lines[i])
            if quote in lines[i]:
                i += 1
                break
            i += 1

rest = "".join(lines[i:])

# --- 3) Récupérer tous les future-imports où qu'ils soient (on les remontera)
futures = re.findall(r"^\s*from\s+__future__\s+import\s+[^\n]+", rest, flags=re.MULTILINE)
rest = re.sub(r"^\s*from\s+__future__\s+import\s+[^\n]+\n?", "", rest, flags=re.MULTILINE)
# dedup
futures = list(dict.fromkeys(futures))
if not any("annotations" in f for f in futures):
    futures.insert(0, "from __future__ import annotations")

# --- 4) Supprimer tout le junk entre la docstring et le premier import réel
m = re.search(r"(?m)^(?:import\s+\S+|from\s+(?!__future__)\S+\s+import\s+)", rest)
if m:
    rest = rest[m.start():]
else:
    # si pas trouvé (peu probable), on garde tel quel
    pass

# --- 5) Injecter helper unique et propre
helper = (
    "\n"
    "# === MCGT Hotfix: robust defaults when cfg has None/\"\" ===\n"
    "def _mcgt_safe_float(x, default):\n"
    "    try:\n"
    "        if x is None or (isinstance(x, str) and x.strip() == \"\"):\n"
    "            return float(default)\n"
    "        return float(x)\n"
    "    except Exception:\n"
    "        return float(default)\n"
    "\n"
)

# --- 6) Renforcer quelques conversions (idempotent)
def reinforce(txt: str) -> str:
    rep = {
        "m1": 30.0,
        "m2": 25.0,
        "fmin": 20.0,
        "fmax": 300.0,
    }
    for k, dv in rep.items():
        txt = re.sub(rf'float\(\s*cfg\s*\[\s*["\']{re.escape(k)}["\']\s*\]\s*\)',
                     f'_mcgt_safe_float(cfg.get("{k}"), {dv})', txt)
        txt = re.sub(rf'float\(\s*cfg\s*\.?get\(\s*["\']{re.escape(k)}["\']\s*\)\s*\)',
                     f'_mcgt_safe_float(cfg.get("{k}"), {dv})', txt)
    # nanmin/nanmax(f) -> helper
    txt = re.sub(r'float\(\s*np\.nanmin\(\s*f\s*\)\s*\)', '_mcgt_safe_float(np.nanmin(f), 20.0)', txt)
    txt = re.sub(r'float\(\s*np\.nanmax\(\s*f\s*\)\s*\)', '_mcgt_safe_float(np.nanmax(f), 300.0)', txt)
    return txt

rest = reinforce(rest)

# --- 7) Recomposer le fichier propre
def join_block(lines_list):
    s = "".join(lines_list).rstrip("\n")
    return (s + "\n") if s else ""

new_src  = join_block(head)
new_src += join_block(doc)
new_src += "\n".join(futures) + "\n"
new_src += helper
new_src += rest.lstrip("\n")

# Normalisation des blancs excessifs
new_src = re.sub(r"\n{3,}", "\n\n", new_src)

# --- 8) Validation syntaxe
try:
    ast.parse(new_src)
except SyntaxError as e:
    print("[ERREUR] SyntaxError après patch:", e)
    ctx = new_src.splitlines()
    lo = max(0, (e.lineno or 1)-6); hi = min(len(ctx), (e.lineno or 1)+5)
    for ln in range(lo, hi):
        mark = ">>" if (ln+1)==e.lineno else "  "
        print(f"{mark} {ln+1:4d}: {ctx[ln]}")
    sys.exit(3)

TARGET.write_text(new_src, encoding="utf-8")
print("[OK] Patch V9 appliqué. Syntaxe valide, header nettoyé, helper unique.")
