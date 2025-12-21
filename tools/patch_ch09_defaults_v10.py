import re
import pathlib
import sys

TARGET = pathlib.Path("scripts/chapter09/generate_data_chapter09.py")
if not TARGET.exists():
    print(f"[ERREUR] Introuvable: {TARGET}", file=sys.stderr)
    sys.exit(2)

src = TARGET.read_text(encoding="utf-8")

# Vérif présence helper (injeté par V9).
if "_mcgt_safe_float" not in src:
    print(
        "[ERREUR] Helper _mcgt_safe_float absent. (Assure-toi que V9 est appliqué.)",
        file=sys.stderr,
    )
    sys.exit(3)

# Remplacements idempotents pour les clés critiques
defaults = {
    "m1": 30.0,
    "m2": 25.0,
    "fmin": 20.0,
    "fmax": 300.0,
    "q0star": 0.0,
    "alpha": 0.0,
    "phi0": 0.0,
    "tc": 0.0,
    "dlog": 0.01,
}

n_changes = 0
for k, dv in defaults.items():
    # float(cfg["k"])
    pattern1 = rf'float\(\s*cfg\s*\[\s*["\']{re.escape(k)}["\']\s*\]\s*\)'
    repl1 = f'_mcgt_safe_float(cfg.get("{k}"), {dv})'
    src, n1 = re.subn(pattern1, repl1, src)
    n_changes += n1
    # float(cfg.get("k"))
    pattern2 = rf'float\(\s*cfg\s*\.?get\(\s*["\']{re.escape(k)}["\']\s*\)\s*\)'
    repl2 = repl1
    src, n2 = re.subn(pattern2, repl2, src)
    n_changes += n2

# Sécuriser nanmin/nanmax(f) si encore présent
src, n3 = re.subn(
    r"float\(\s*np\.nanmin\(\s*f\s*\)\s*\)", "_mcgt_safe_float(np.nanmin(f), 20.0)", src
)
src, n4 = re.subn(
    r"float\(\s*np\.nanmax\(\s*f\s*\)\s*\)",
    "_mcgt_safe_float(np.nanmax(f), 300.0)",
    src,
)
n_changes += n3 + n4

TARGET.write_text(src, encoding="utf-8")
print(f"[OK] Patch V10 appliqué ({n_changes} remplacement(s)).")
