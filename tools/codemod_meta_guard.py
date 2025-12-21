from pathlib import Path
import re
import sys

target = Path(sys.argv[1]) if len(sys.argv) > 1 else None
if not target or not target.exists():
    print("[ERREUR] fichier cible manquant")
    sys.exit(2)
src = target.read_text(encoding="utf-8")

# Ajoute un guard minimal après la 1ère assignation meta = json.load(...)
pat = re.compile(r"^(\s*meta\s*=\s*json\.load\([^)]*\)\s*)$", re.M)
if "if not isinstance(meta, dict)" not in src:
    m = pat.search(src)
    if m:
        indent = re.match(r"^\s*", m.group(1)).group(0)
        guard = f"{indent}if not isinstance(meta, dict):\n{indent}    meta = {{}}\n"
        src = src[: m.end()] + "\n" + guard + src[m.end() :]

target.write_text(src, encoding="utf-8")
print("[OK] meta-guard appliqué:", target)
