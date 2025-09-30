#!/usr/bin/env bash
set -euo pipefail

[ -f Makefile ] || { echo "❌ Makefile introuvable."; exit 1; }
bak="Makefile.bak.$(date -u +%Y%m%dT%H%M%SZ)"
cp -f Makefile "$bak"

python - <<'PY'
import re, pathlib

p = pathlib.Path("Makefile")
txt = p.read_text(encoding="utf-8", errors="replace").replace("\r\n","\n").replace("\r","\n")
lines = txt.split("\n")

# règles: "target: deps" (autorise "target(arg):")
re_rule     = re.compile(r'^[A-Za-z0-9_.%/\-]+(?:\s*\([^)]*\))?\s*:')
re_assign   = re.compile(r'^\s*[A-Za-z0-9_.%/\-]+\s*[:+?]?=')

fixed = 0
in_recipe = False

for i in range(len(lines)):
    line = lines[i]

    # entrée en recette si la ligne *précédente* était une règle non commentée
    if i > 0 and re_rule.match(lines[i-1]) and not lines[i-1].lstrip().startswith("#"):
        in_recipe = True

    # sorties de recette
    if not line.strip():                  # ligne vide
        in_recipe = False
    elif re_rule.match(line):             # nouvelle règle
        in_recipe = False
    elif re_assign.match(line):           # assignation "VAR = ..."
        in_recipe = False
    elif line.lstrip().startswith("#"):   # commentaire seul
        # reste dans le même état (commentaire au sein d'un bloc: toléré)
        pass

    if in_recipe:
        # si déjà une tab en tête -> ok
        if line.startswith("\t"):
            pass
        # si commence par des espaces -> remplace le premier bloc par une tab
        elif re.match(r'^[ ]+', line):
            new = re.sub(r'^[ ]+', "\t", line, count=1)
            # colle @ ou - à la tab si besoin
            new = re.sub(r'^\t[ ]+([@-])', r'\t\1', new)
            if new != line:
                lines[i] = new
                fixed += 1
        # si commence directement par @ ou - sans tab -> préfixe d'une tab
        elif re.match(r'^[@-]', line):
            lines[i] = "\t" + line
            fixed += 1

# normalise fin
out = "\n".join(lines).rstrip("\n") + "\n"
p.write_text(out, encoding="utf-8")
print(f"fixed={fixed}")
PY

echo "✅ Makefile corrigé (backup: $bak)"
