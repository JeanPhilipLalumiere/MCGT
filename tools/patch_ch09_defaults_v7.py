import re
import pathlib
import sys
import ast

TARGET = pathlib.Path("scripts/chapter09/generate_data_chapter09.py")
if not TARGET.exists():
    print(f"[ERREUR] Introuvable: {TARGET}", file=sys.stderr)
    sys.exit(2)
src = TARGET.read_text(encoding="utf-8")

# --- Retirer toute occurrence antérieure (même cassée) du helper
src = re.sub(
    r"(?s)#\s*=== MCGT Hotfix:.*?def _mcgt_safe_float\(.*?return float\(default\)\s*\n\s*\n",
    "",
    src,
)

# --- Découper en lignes et isoler entête: shebang, blank/coding, docstring, futures
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
head = []
# shebang / coding / blancs (conservent l’ordre)
while i < len(lines) and (
    is_shebang(lines[i]) or is_coding(lines[i]) or is_blank(lines[i])
):
    head.append(lines[i])
    i += 1

# docstring multi/monoligne
doc = []
if i < len(lines) and is_doc_start(lines[i]):
    q = lines[i].lstrip()[:3]
    doc.append(lines[i])
    i += 1
    # bloc si pas fermé sur la même ligne
    if doc[0].lstrip().count(q) == 1:
        while i < len(lines):
            doc.append(lines[i])
            if q in lines[i]:
                i += 1
                break
            i += 1

# futures consécutifs
futures = []
while i < len(lines) and is_future(lines[i]):
    futures.append(lines[i])
    i += 1

body = "".join(lines[i:])  # corps sans entête/futures


# --- Normaliser: 1 ligne blanche entre sections
def join_block(parts):
    out = "".join(parts).rstrip("\n")
    return (out + "\n") if out else ""


head_s = join_block(head)
doc_s = join_block(doc)
fut_s = join_block(futures)

# --- Helper bien indenté (4 espaces)
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


# --- Renforcer les conversions (idempotent)
def reinforce(txt):
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
    # durcir nanmin/nanmax sur fmin/fmax dans helpers internes
    subn(
        r"float\(\s*np\.nanmin\(\s*f\s*\)\s*\)", "_mcgt_safe_float(np.nanmin(f), 20.0)"
    )
    subn(
        r"float\(\s*np\.nanmax\(\s*f\s*\)\s*\)", "_mcgt_safe_float(np.nanmax(f), 300.0)"
    )
    return txt, total


body2, nsubs = reinforce(body)

# --- Recomposer: futures restent en haut (exigence Python), helper juste après
new_src = ""
new_src += head_s
new_src += doc_s
new_src += fut_s
new_src += "\n" if not new_src.endswith("\n") else ""
new_src += helper
new_src += body2.lstrip("\n")

# --- Valider
try:
    ast.parse(new_src)
except SyntaxError as e:
    print("[ERREUR] SyntaxError après patch:", e)
    # contexte lisible
    ctx = new_src.splitlines()
    lo = max(0, (e.lineno or 1) - 6)
    hi = min(len(ctx), (e.lineno or 1) + 5)
    for ln in range(lo, hi):
        mark = ">>" if (ln + 1) == e.lineno else "  "
        print(f"{mark} {ln + 1:4d}: {ctx[ln]}")
    sys.exit(3)

TARGET.write_text(new_src, encoding="utf-8")
print(f"[OK] Patch V7 appliqué. Renforcements: {nsubs}. Syntaxe valide.")
