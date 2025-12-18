import re, pathlib, sys

TARGET = pathlib.Path("zz-scripts/chapter09/generate_data_chapter09.py")
if not TARGET.exists():
    print(f"[ERREUR] Introuvable: {TARGET}", file=sys.stderr); sys.exit(2)

src = TARGET.read_text(encoding="utf-8")

if "_mcgt_safe_float" not in src:
    print("[ERREUR] Helper _mcgt_safe_float absent (applique d'abord V9).", file=sys.stderr)
    sys.exit(3)

# Renforcement pour 'tol'
pattern1 = r'float\(\s*cfg\s*\[\s*["\']tol["\']\s*\]\s*\)'
pattern2 = r'float\(\s*cfg\s*\.?get\(\s*["\']tol["\']\s*\)\s*\)'
repl     = '_mcgt_safe_float(cfg.get("tol"), 1e-6)'

n = 0
src, n1 = re.subn(pattern1, repl, src); n += n1
src, n2 = re.subn(pattern2, repl, src); n += n2

TARGET.write_text(src, encoding="utf-8")
print(f"[OK] Patch V11 appliqué ({n} remplacement(s)).")
