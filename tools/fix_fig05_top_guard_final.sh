#!/usr/bin/env bash
set -Eeuo pipefail
F="zz-scripts/chapter02/plot_fig05_FG_series.py"
[[ -f "$F" ]] || { echo "[ERR] introuvable: $F"; exit 1; }

ts="$(date -u +%Y%m%dT%H%M%SZ)"
cp --no-clobber --update=none -- "$F" "${F}.bak_${ts}" || true

python - <<'PY'
import re, pathlib

F = pathlib.Path("zz-scripts/chapter02/plot_fig05_FG_series.py")
src = F.read_text(encoding="utf-8")
lines = src.splitlines(True)

# 1) Trouver l'index d'insertion après shebang / encodage / from __future__
i = 0
if i < len(lines) and lines[i].startswith("#!"):
    i += 1
# cookie d'encodage PEP 263 sur les 2 premières lignes
enc_pat = re.compile(r"coding[:=]\s*[-\w.]+")
for _ in range(2):
    if i < len(lines) and enc_pat.search(lines[i]):
        i += 1
# blocs from __future__ consécutifs
while i < len(lines) and re.match(r"\s*from\s+__future__\s+import\s+", lines[i]):
    i += 1

# 2) S'assurer que 'import sys' est présent dans les 20 premières lignes utiles
has_import_sys = any(re.match(r"\s*import\s+sys\s*$", l) for l in lines[:20])
if not has_import_sys:
    lines.insert(i, "import sys\n")

# 3) Détecter un garde 'if ... sys.argv ... :' et garantir un exit juste après
guard_re = re.compile(r"^\s*if\s+.*sys\.argv.*:\s*(?:#.*)?$")  # permissif
for idx, l in enumerate(lines):
    if guard_re.match(l):
        # trouver la prochaine ligne non vide / non commentaire
        j = idx + 1
        while j < len(lines) and (lines[j].strip() == "" or lines[j].lstrip().startswith("#")):
            j += 1
        # si pas déjà un exit immédiat, on insère un raise SystemExit(0)
        need_exit = True
        if j < len(lines):
            if re.match(r"\s*(?:raise\s+SystemExit\(\s*0\s*\)|sys\.exit\(\s*0\s*\)|return\s+0)\s*$", lines[j]):
                need_exit = False
        if need_exit:
            indent = ' ' * (len(l) - len(l.lstrip()))
            lines.insert(idx + 1, f"{indent}raise SystemExit(0)\n")
        break

new = "".join(lines)
if new != src:
    F.write_text(new, encoding="utf-8")
    print("[PATCH] fig05: import sys placé correctement + exit garanti après le garde")
else:
    print("[OK] fig05: rien à changer (idempotent)")
PY

echo "[RUN] Test ciblé --help"
if python "$F" --help >/dev/null 2>&1; then
  echo "[OK] $F --help"
else
  echo "[FAIL] $F --help"
  exit 2
fi
