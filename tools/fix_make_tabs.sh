#!/usr/bin/env bash
set -euo pipefail

# Garde-fou
[ -f Makefile ] || { echo "❌ Makefile introuvable."; exit 1; }

bak="Makefile.bak.$(date -u +%Y%m%dT%H%M%SZ)"
cp -f Makefile "$bak"

python - <<'PY'
import re, sys, pathlib

p = pathlib.Path("Makefile")
txt = p.read_text(encoding="utf-8", errors="replace").replace("\r\n","\n").replace("\r","\n")
lines = txt.split("\n")

# Heuristique: on entre en bloc-recette après une ligne "target: deps"
# et on en sort sur ligne vide, nouvelle règle, ou assignation.
re_rule     = re.compile(r'^[A-Za-z0-9_.%/\-]+(?:\s*\([^)]*\))?\s*:')  # ex: target: or target(arg):
re_assign   = re.compile(r'^\s*[A-Za-z0-9_.%/\-]+\s*[:+?]?=')
re_rulecont = re.compile(r'^\s*\t')   # lignes déjà-tab (recette)
re_rule2    = re_rule  # prochaine règle

fixed = 0
in_recipe = False

for i, line in enumerate(lines):
    if i == 0:
        prev = ""
    else:
        prev = lines[i-1]

    # Détecte entrée en recette: la ligne précédente était une règle
    if i > 0 and re_rule.match(prev) and not prev.lstrip().startswith("#"):
        in_recipe = True

    # Sorties de recette:
    if not line.strip():                      # ligne vide
        in_recipe = False
    elif re_rule.match(line):                 # nouvelle règle
        in_recipe = False
    elif re_assign.match(line):               # assignation var = ...
        in_recipe = False

    if in_recipe:
        # Si déjà tab en tête -> ok
        if line.startswith("\t"):
            pass
        # Si commence par espaces + éventuellement @ ou - : remplace par une tab
        elif re.match(r'^[ ]+[@-]?', line):
            line2 = re.sub(r'^[ ]+', '\t', line, count=1)
            # Coller @ ou - directement après la tab
            line2 = re.sub(r'^\t[ ]+([@-])', r'\t\1', line2)
            if line2 != line:
                fixed += 1
                line = line2
        # Si la ligne commence directement par @ ou -, mais sans tab -> ajoute une tab
        elif re.match(r'^[@-]', line):
            lines[i] = "\t" + line
            fixed += 1
            continue

    lines[i] = line

# Normaliser fin de fichier: une seule newline
out = "\n".join(lines).rstrip("\n") + "\n"
p.write_text(out, encoding="utf-8")
print(f"fixed={fixed}")
PY

echo "✅ Makefile corrigé (backup: $bak)"
