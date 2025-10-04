#!/usr/bin/env bash
set -euo pipefail
KEEP_OPEN="${KEEP_OPEN:-1}"
stay_open(){ rc=$?; echo; echo "[fix-constants-order] Script terminé avec exit code: $rc"; if [[ "$KEEP_OPEN" == "1" && -t 1 && -z "${CI:-}" ]]; then echo "[fix-constants-order] Appuie sur Entrée pour quitter…"; read -r _; fi; }
trap 'stay_open' EXIT

cd "$(git rev-parse --show-toplevel)"

python - <<'PY'
from pathlib import Path
import re

p = Path("mcgt/constants.py")
s = p.read_text(encoding="utf-8")
orig = s

# 1) Isoler (éventuelle) docstring de module tout en haut
def split_docstring(text: str):
    lines = text.splitlines(True)
    i = 0
    # skip commentaires/blank avant docstring — autorisés par l'interpréteur
    # (ne pas conserver ces commentaires *avant* __future__ pour éviter tout risque)
    # On va les réinsérer plus bas après le header pour rester permissif.
    leading = []
    while i < len(lines) and (lines[i].strip() == "" or lines[i].lstrip().startswith("#")):
        leading.append(lines[i])
        i += 1
    if i < len(lines) and lines[i].lstrip().startswith(('"""',"'''")):
        q = '"""' if lines[i].lstrip().startswith('"""') else "'''"
        start = i
        i += 1
        while i < len(lines) and q not in lines[i]:
            i += 1
        if i < len(lines):
            i += 1  # inclure la ligne de fermeture
            doc = "".join(lines[start:i])
            rest = "".join(lines[i:])
            # On conserve aussi les commentaires/blank glanés avant comme "pre_doc"
            pre_doc = "".join(leading)
            return pre_doc, doc, rest
    # pas de docstring
    return "".join(leading), "", "".join(lines[i:])

pre_doc, doc, rest = split_docstring(s)

# 2) Purger tous les anciens __future__/Final/constants partout
def purge_patterns(text: str) -> str:
    text = re.sub(r'^[ \t]*from __future__ import annotations[ \t]*\r?\n', '', text, flags=re.MULTILINE)
    text = re.sub(r'^[ \t]*from[ \t]+typing[ \t]+import[ \t]+Final[ \t]*\r?\n', '', text, flags=re.MULTILINE)
    text = re.sub(r'^[ \t]*(C_LIGHT_M_S|C_LIGHT_KM_S|G_SI)\s*[:=][^\n]*\n?', '', text, flags=re.MULTILINE)
    # compacter les sauts de ligne
    text = re.sub(r'\n{3,}', '\n\n', text)
    return text

rest = purge_patterns(rest)

# 3) Construire l’en-tête canonique : docstring + __future__ + import Final + bloc c/G
header = ""
if doc:
    header += doc
# __future__ doit être la toute première instruction (après docstring uniquement)
header += "from __future__ import annotations\n"
header += "\nfrom typing import Final\n"
header += (
    "C_LIGHT_M_S: Final[float] = 299_792_458.0\n"
    "C_LIGHT_KM_S: Final[float] = C_LIGHT_M_S / 1000.0\n"
    "G_SI: Final[float] = 6.67430e-11\n"
)

# 4) Recomposer : header + (éventuels commentaires/vides initiaux) + reste
# On replace les commentaires/blanks initiaux *après* le header pour ne jamais devancer __future__.
new = header
if pre_doc.strip():
    new += "\n" + pre_doc
# séparer visuellement
if not new.endswith("\n\n"):
    new += "\n"
if rest and rest[0] != "\n":
    new += "\n"
new += rest

# 5) Cleanup final & sauvegarde
new = re.sub(r'\n{3,}', '\n\n', new)
if not new.endswith("\n"):
    new += "\n"

if new != orig:
    p.write_text(new, encoding="utf-8")
    print("[constants.py] ordre réparé + bloc canonique unique")
else:
    print("[constants.py] déjà conforme")
PY

# Smoke test d'import
python - <<'PY' || true
import importlib
m = importlib.import_module("mcgt.constants")
print("C_LIGHT_M_S =", getattr(m, "C_LIGHT_M_S", None))
PY

# Validation rapide
pre-commit run --files mcgt/constants.py || true

# Commit/push si diff
git add mcgt/constants.py
if ! git diff --cached --quiet; then
  git commit -m "fix(constants): ensure __future__ at top; single canonical c/G block after it"
  git push
else
  echo "Rien à committer"
fi
