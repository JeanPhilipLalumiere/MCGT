#!/usr/bin/env bash
set -euo pipefail
KEEP_OPEN="${KEEP_OPEN:-1}"
stay_open(){ rc=$?; echo; echo "[normalize-constants] Script terminé avec exit code: $rc"; if [[ "$KEEP_OPEN" == "1" && -t 1 && -z "${CI:-}" ]]; then echo "[normalize-constants] Appuie sur Entrée pour quitter…"; read -r _; fi; }
trap 'stay_open' EXIT

cd "$(git rev-parse --show-toplevel)"

python - <<'PY'
from pathlib import Path
import re

p = Path("mcgt/constants.py")
s = p.read_text(encoding="utf-8")

orig = s

# 0) S'assurer que __future__ est en tête (après docstring éventuelle)
s = re.sub(r'^[ \t]*from __future__ import annotations[ \t]*\r?\n', '', s, flags=re.MULTILINE)
lines = s.splitlines(True)

def starts_triple(line):
    ls = line.lstrip()
    if ls.startswith('"""'): return '"""'
    if ls.startswith("'''"): return "'''"
    return None

i = 0
while i < len(lines) and (lines[i].lstrip().startswith("#") or lines[i].strip() == ""):
    i += 1

q = starts_triple(lines[i]) if i < len(lines) else None
if q:
    j = i + 1
    while j < len(lines) and q not in lines[j]:
        j += 1
    if j < len(lines): i = j + 1

future_ln = "from __future__ import annotations\n"
if future_ln not in ''.join(lines[:i]):
    lines.insert(i, future_ln)
s = ''.join(lines)

# 1) Supprimer TOUTES les anciennes définitions/annotations de C_LIGHT_M_S, C_LIGHT_KM_S, G_SI
pattern = re.compile(r'^[ \t]*(C_LIGHT_M_S|C_LIGHT_KM_S|G_SI)\s*[:=][^\n]*\n?', flags=re.MULTILINE)
s = pattern.sub('', s)

# Nettoyer doubles lignes vides
s = re.sub(r'\n{3,}', '\n\n', s)

# 2) Insérer le bloc canonique juste après la/les import(s) top-level
lines = s.splitlines(True)
# position après le dernier import top-level contigu
idx = 0
while idx < len(lines) and (lines[idx].startswith(("from ", "import ", "#", "\n")) or lines[idx].strip()=="" or lines[idx].lstrip().startswith("from ")):
    idx += 1

block = (
    "\n# --- Canonical physical constants (SI) ---\n"
    "from typing import Final\n"
    "C_LIGHT_M_S: Final[float] = 299_792_458.0\n"
    "C_LIGHT_KM_S: Final[float] = C_LIGHT_M_S / 1000.0\n"
    "G_SI: Final[float] = 6.67430e-11\n"
)
lines.insert(idx, block)
s = ''.join(lines)

# Fin de fichier avec newline
if not s.endswith('\n'):
    s += '\n'

if s != orig:
    p.write_text(s, encoding="utf-8")
    print("[constants] bloc canonique réécrit (unique)")
else:
    print("[constants] déjà normalisé")
PY

# Valider vite fait
pre-commit run --files mcgt/constants.py || true
git add mcgt/constants.py
if ! git diff --cached --quiet; then
  git commit -m "chore(constants): normalize single canonical block for c & G"
  git push
else
  echo "Rien à committer"
fi
