# zz-tools/patch_fig02_fix_block.py
#!/usr/bin/env python3
from pathlib import Path
import re

p = Path("zz-scripts/chapter09/plot_fig02_residual_phase.py")
src = p.read_text(encoding="utf-8")

# 1) Retire le bloc mal indenté (for c in ("f_Hz","phi_ref") ...), s'il existe
bad_block = re.compile(
    r'(?ms)^[ \t]*for c in \("f_Hz",\s*"phi_ref"\):\s*\n[ \t]+if c not in df\.columns:.*?$'
)
src2 = bad_block.sub("", src)

# 2) Injecte un check compact et lisible juste après le premier pd.read_csv(...)
inject_pat = re.compile(r"(\s*df\s*=\s*pd\.read_csv\([^)]*\)\s*\n)")
check = (
    'required = ["f_Hz","phi_ref"]\n'
    "missing = [c for c in required if c not in df.columns]\n"
    "if missing:\n"
    '    raise SystemExit(f"Colonnes manquantes pour fig02: {missing}")\n'
    "# Alias MCGT → phi_active\n"
    'if "phi_active" not in df.columns:\n'
    '    for c in ("phi_active","phi_mcgt","phi_mcgt_cal","phi_model","phi_mcgt_active"):\n'
    "        if c in df.columns:\n"
    '            df["phi_active"] = df[c]\n'
    "            break\n"
)
if inject_pat.search(src2) and check not in src2:
    src2 = inject_pat.sub(r"\\1" + check, src2)

if src2 != src:
    p.write_text(src2, encoding="utf-8")
    print("[OK] fig02 natif : bloc de vérification corrigé/injecté.")
else:
    print("[INFO] Aucun changement (déjà corrigé ?)")
