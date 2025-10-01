#!/usr/bin/env bash
set -euo pipefail

PAUSE="${PAUSE:-1}"
_pause(){ if [[ "${PAUSE}" != "0" && -t 0 ]]; then echo; read -r -p "✓ Terminé. Appuie sur Entrée pour fermer ce script..." _; fi; }
trap _pause EXIT

echo "== Fix des TABs orphelins (commentaires/vides hors recette) =="

[ -f Makefile ] || { echo "❌ Makefile introuvable."; exit 1; }
bak="Makefile.bak.$(date -u +%Y%m%dT%H%M%SZ)"; cp -f Makefile "$bak"

python - <<'PY'
import re, pathlib

mf  = pathlib.Path("Makefile")
txt = mf.read_text(encoding="utf-8", errors="replace").replace("\r\n","\n").replace("\r","\n")
lines = txt.split("\n")

re_rule   = re.compile(r'^[A-Za-z0-9_.%/\-]+(?:\s*\([^)]*\))?\s*:')  # cible:
re_assign = re.compile(r'^\s*[A-Za-z0-9_.%/\-]+\s*[:+?]?=')           # VAR = ...
in_recipe = False
out = []

for i, line in enumerate(lines):
    # début d'un bloc recette si la ligne précédente est une règle non commentée
    if i > 0 and re_rule.match(lines[i-1]) and not lines[i-1].lstrip().startswith("#"):
        in_recipe = True

    # on sort du bloc recette sur ligne vide, nouvelle règle, ou assignation
    if in_recipe and (line.strip() == "" or re_rule.match(line) or re_assign.match(line)):
        in_recipe = False

    if not in_recipe:
        # TAB + # (commentaire orphelin) => enlever TAB(s) de tête
        if line.startswith("\t#"):
            out.append(line.lstrip("\t"))
            continue
        # ligne vide avec TAB(s) => la vider
        if line.startswith("\t") and line.strip() == "":
            out.append("")
            continue

    out.append(line)

# garantis LF final
dst = "\n".join(out)
if not dst.endswith("\n"):
    dst += "\n"
mf.write_text(dst, encoding="utf-8")
print("OK: TABs orphelins nettoyés (commentaires/vides hors recette).")
PY

echo "✅ Makefile corrigé (backup: $bak)"

echo "— Contexte 68..82 (TAB = ^I) —"
nl -ba -w3 -s': ' Makefile | sed -n '68,82p' | sed -e 's/\t/^I/g' -e 's/$/$/'

echo "— make -n fix-manifest —"
if make -n fix-manifest >/dev/null; then
  echo "✅ make -n fix-manifest : OK"
else
  echo "⚠️  make -n fix-manifest a échoué. Contexte brut :"
  make -n || true
  exit 2
fi
