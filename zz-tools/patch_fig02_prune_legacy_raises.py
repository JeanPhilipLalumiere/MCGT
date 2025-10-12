# zz-tools/patch_fig02_prune_legacy_raises.py
#!/usr/bin/env python3
from pathlib import Path
import re

p = Path("zz-scripts/chapter09/plot_fig02_residual_phase.py")
src = p.read_text(encoding="utf-8")

# Supprime toute ligne legacy du type: raise SystemExit(f"Colonne manquante: {c}")
src2, n = re.subn(r'^[ \t]*raise\s+SystemExit\(\s*f?"Colonne manquante:\s*\{c\}"\s*\)\s*\n', '', src, flags=re.M)

if n:
    p.write_text(src2, encoding="utf-8")
    print(f"[OK] Legacy raise supprimé ({n} occurrence(s)).")
else:
    print("[INFO] Aucun legacy raise à supprimer (déjà propre).")
