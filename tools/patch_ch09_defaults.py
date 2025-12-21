import re
import pathlib
import sys

TARGET = pathlib.Path("scripts/chapter09/generate_data_chapter09.py")
if not TARGET.exists():
    print(f"[ERREUR] Introuvable: {TARGET}", file=sys.stderr)
    sys.exit(2)

src = TARGET.read_text(encoding="utf-8")

# 1) Injecter helper sûr si absent
if "def _mcgt_safe_float(" not in src:
    inject = """
# === MCGT Hotfix: robust defaults when cfg has None/"" ===
def _mcgt_safe_float(x, default):
    try:
        if x is None or (isinstance(x, str) and x.strip() == ""):
            return float(default)
        return float(x)
    except Exception:
        return float(default)
"""
    # Insérer après le dernier import si possible
    m = list(
        re.finditer(
            r"^(?:from\\s+\\S+\\s+import\\s+.*|import\\s+\\S+.*)\\n",
            src,
            flags=re.MULTILINE,
        )
    )
    if m:
        idx = m[-1].end()
        src = src[:idx] + inject + src[idx:]
    else:
        src = inject + src

# 2) Remplacements ciblés
defaults = {
    "m1": 30.0,
    "m2": 25.0,
    "fmin": 20.0,
    "fmax": 300.0,
    "q0": 0.0,
    "phi_ref": 0.0,
}
total = 0
for k, dv in defaults.items():
    # float(cfg["k"])  et  float(cfg['k'])
    for pat in (
        rf'float\\(cfg\\["{re.escape(k)}"\\]\\)',
        rf"float\\(cfg\\['{re.escape(k)}'\\]\\)",
    ):
        repl = f'_mcgt_safe_float(cfg.get("{k}"), {dv})'
        src, n = re.subn(pat, repl, src)
        total += n
        if n:
            print(f"[INFO] Remplacement {k} -> default={dv} ({n})")

    # float(cfg.get("k"))  et  float(cfg.get('k'))
    for pat in (
        rf'float\\(cfg\\.get\\("{re.escape(k)}"\\)\\)',
        rf"float\\(cfg\\.get\\('{re.escape(k)}'\\)\\)",
    ):
        repl = f'_mcgt_safe_float(cfg.get("{k}"), {dv})'
        src, n = re.subn(pat, repl, src)
        total += n
        if n:
            print(f"[INFO] Renforcement get() {k} -> default={dv} ({n})")

TARGET.write_text(src, encoding="utf-8")
print(f"[OK] Patch appliqué ({total} remplacement(s)).")
