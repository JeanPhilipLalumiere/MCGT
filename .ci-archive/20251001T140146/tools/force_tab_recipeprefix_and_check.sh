#!/usr/bin/env bash
set -euo pipefail

PAUSE="${PAUSE:-1}"
_pause(){ if [[ "${PAUSE}" != "0" && -t 0 ]]; then echo; read -r -p "✓ Terminé. Appuie sur Entrée pour fermer ce script..." _; fi; }
trap _pause EXIT

echo "== Enforce TAB recipe prefix (neutralise .RECIPEPREFIX) + checks =="

[ -f Makefile ] || { echo "❌ Makefile introuvable."; exit 1; }
bak="Makefile.bak.$(date -u +%Y%m%dT%H%M%SZ)"
cp -f Makefile "$bak"

# 1) Si .RECIPEPREFIX est défini quelque part, on COMENTE la ligne
python - <<'PY'
import re, pathlib

mf = pathlib.Path("Makefile")
txt = mf.read_text(encoding="utf-8", errors="replace").replace("\r\n","\n").replace("\r","\n")
lines = txt.split("\n")

re_recipeprefix = re.compile(r'^\s*\.RECIPEPREFIX\s*[:+?]?=')

changed = False
out = []
for line in lines:
    if re_recipeprefix.match(line) and not line.lstrip().startswith("#"):
        out.append("# " + line)
        changed = True
    else:
        out.append(line)

dst = "\n".join(out)
if not dst.endswith("\n"):
    dst += "\n"
mf.write_text(dst, encoding="utf-8")
print("OK: .RECIPEPREFIX neutralisé (si présent).")
PY

# 2) Nettoie les TABs orphelins (# / vides hors recette), au cas où
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
    if i > 0 and re_rule.match(lines[i-1]) and not lines[i-1].lstrip().startswith("#"):
        in_recipe = True
    if in_recipe and (line.strip()=="" or re_rule.match(line) or re_assign.match(line)):
        in_recipe = False

    if not in_recipe:
        if line.startswith("\t#"):
            out.append(line.lstrip("\t"))
            continue
        if line.startswith("\t") and line.strip()=="":
            out.append("")
            continue

    out.append(line)

dst = "\n".join(out)
if not dst.endswith("\n"):
    dst += "\n"
mf.write_text(dst, encoding="utf-8")
print("OK: TABs orphelins nettoyés.")
PY

echo "✅ Makefile modifié (backup: $bak)"

echo "— Recherche de .RECIPEPREFIX (après patch) —"
grep -n '^[[:space:]]*\.RECIPEPREFIX' Makefile || echo "(aucune définition active)"

echo "— Contexte 60..90 (TAB = ^I) —"
nl -ba -w3 -s': ' Makefile | sed -n '60,90p' | sed -e 's/\t/^I/g' -e 's/$/$/'

echo "— make -n fix-manifest —"
if make -n fix-manifest >/dev/null; then
  echo "✅ make -n fix-manifest : OK"
else
  echo "⚠️  make -n fix-manifest a échoué. Sortie brute :"
  make -n || true
  exit 2
fi
