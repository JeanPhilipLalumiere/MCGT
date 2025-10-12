from pathlib import Path
import re, sys

T = Path("zz-scripts/chapter09/plot_fig01_phase_overlay.py")
if not T.exists():
    print("[ERREUR] Introuvable:", T); sys.exit(2)
src = T.read_text(encoding="utf-8")

# Remplace un chargement naïf par une version tolérante au type
pat = r"""
def\s+_load_meta\(.*?\):\s*
(?:.|\n)*?
    try:\s*
        with\s+open\((?P<path>[^)]+)\)\s+as\s+f:\s*
            meta\s*=\s*json\.load\(f\)\s*
        return\s+meta\s*
    except\s+Exception\s+as\s+e:\s*
        logging\.warning\([^\n]+\)\s*
        return\s+None
"""
rep = r'''
def _load_meta(path):
    try:
        import json, logging
        with open(path) as f:
            meta = json.load(f)
        if not isinstance(meta, dict):
            logging.warning("Lecture JSON méta: objet non-dict (%s).", type(meta).__name__)
            return {}
        return meta
    except Exception as e:
        import logging
        logging.warning("Lecture JSON méta échouée (%s).", e)
        return {}
'''
new, n = re.subn(pat, rep, src, flags=re.MULTILINE | re.VERBOSE)
if n == 0:
    # Si la fonction n'existe pas sous cette forme, on insère un helper sûr
    inj = '''
def _load_meta(path):
    try:
        import json, logging
        with open(path) as f:
            meta = json.load(f)
        if not isinstance(meta, dict):
            logging.warning("Lecture JSON méta: objet non-dict (%s).", type(meta).__name__)
            return {}
        return meta
    except Exception as e:
        import logging
        logging.warning("Lecture JSON méta échouée (%s).", e)
        return {}
'''
    # insérer juste après les imports
    m = re.search(r'^(import .+?\n)(?:(?:import|from) .+?\n)*', src, flags=re.MULTILINE)
    if m:
        pos = m.end()
        new = src[:pos] + inj + src[pos:]
    else:
        new = inj + src
T.write_text(new, encoding="utf-8")
print("[OK] patch fig01_meta appliqué")
