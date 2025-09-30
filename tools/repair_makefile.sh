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

re_rule     = re.compile(r'^[A-Za-z0-9_.%/\-]+(?:\s*\([^)]*\))?\s*:')      # target:  / target(arg):
re_assign   = re.compile(r'^\s*[A-Za-z0-9_.%/\-]+\s*[:+?]?=')               # VAR = ...
re_spaces   = re.compile(r'^[ ]+')
re_cmd_at   = re.compile(r'^[@-]')
re_gt_only  = re.compile(r'^\s*>')                                          # ligne qui commence par '>'

fixed_tabs = 0
fixed_gt   = 0
in_recipe  = False

for i, line in enumerate(lines):
    # entrée recette si ligne précédente est une règle non commentée
    if i > 0 and re_rule.match(lines[i-1]) and not lines[i-1].lstrip().startswith("#"):
        in_recipe = True

    # sorties recette
    if not line.strip():
        in_recipe = False
    elif re_rule.match(line):
        in_recipe = False
    elif re_assign.match(line):
        in_recipe = False

    if in_recipe:
        if line.startswith("\t"):
            pass
        elif re_spaces.match(line):
            new = re_spaces.sub("\t", line, count=1)
            new = re.sub(r'^\t[ ]+([@-])', r'\t\1', new)  # nettoie tab + espaces + @/-
            if new != line:
                lines[i] = new
                fixed_tabs += 1
        elif re_cmd_at.match(line):
            lines[i] = "\t" + line
            fixed_tabs += 1
    else:
        # Hors recette : si la ligne commence par '>', commente-la
        if re_gt_only.match(line) and not line.lstrip().startswith("#"):
            lines[i] = "# " + line
            fixed_gt += 1

out = "\n".join(lines).rstrip("\n") + "\n"
p.write_text(out, encoding="utf-8")
print(f"fixed_tabs={fixed_tabs} fixed_gt={fixed_gt}")
PY

echo "✅ Makefile réparé (backup: $bak)"

# Affiche le contexte autour de 74 avec les tabs visibles (^I)
echo "— Contexte Makefile lignes 70..78 (tabs = ^I) —"
nl -ba -w3 -s': ' Makefile | sed -n '70,78p' | sed -e 's/\t/^I/g' -e 's/$/$/'

# Dry-run make
echo "— make -n —"
if make -n >/dev/null 2>&1; then
  echo "✅ make -n: OK"
else
  echo "⚠️  make -n a signalé des erreurs:"
  make -n 2>&1 | sed 's/^/  /'
  exit 2
fi
