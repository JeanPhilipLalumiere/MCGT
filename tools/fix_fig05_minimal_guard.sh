#!/usr/bin/env bash
set -Eeuo pipefail
F="zz-scripts/chapter02/plot_fig05_FG_series.py"
[[ -f "$F" ]] || { echo "[ERR] introuvable: $F"; exit 1; }
ts="$(date -u +%Y%m%dT%H%M%SZ)"; cp -n -- "$F" "${F}.bak_${ts}" || true

python - <<'PY'
import io, pathlib, re, sys
F = pathlib.Path("zz-scripts/chapter02/plot_fig05_FG_series.py")
src = F.read_text(encoding="utf-8")

# 1) si le fichier débute par le garde, injecter import sys avant
#    (en conservant shebang/encodage en tête)
pat_guard = r"(?m)^\s*if\s+any\(h\s+in\s+sys\.argv.*\):\s*$"
if re.search(pat_guard, src):
    # repère les toutes premières lignes spéciales (shebang / encodage)
    head = []
    rest = src
    m = re.match(r'(#![^\n]*\n)?((?:#\s*-\*-[^\n]*-\*-\n)?)', src)
    if m:
        head.append(m.group(1) or "")
        head.append(m.group(2) or "")
        rest = src[m.end():]
    # si "import sys" absent dans le head immédiat, l’insérer en tête du reste
    if not re.search(r'(?m)^\s*import\s+sys\s*$', rest.splitlines(True)[:10] and "".join(rest.splitlines(True)[:10]) or ""):
        rest = "import sys\n" + rest
    src = "".join(head) + rest

# 2) s’assurer que le garde possède un exit immédiat
def add_exit(block: str) -> str:
    return re.sub(
        r'(?m)^(?P<g>\s*if\s+any\(h\s+in\s+sys\.argv.*\):\s*)$',
        lambda m: m.group('g') + "\n" + (" " * (len(m.group('g')) - len(m.group('g').lstrip()))) + "raise SystemExit(0)",
        block, count=1
    )
if re.search(pat_guard, src) and "SystemExit(0)" not in src:
    src = add_exit(src)

# 3) écriture si modifié
F.write_text(src, encoding="utf-8")
print("[PATCH] fig05: import sys avant le garde + exit garanti")
PY

echo "[RUN] Test ciblé --help"
if python "$F" --help >/dev/null 2>&1; then
  echo "[OK] $F --help"
else
  echo "[FAIL] $F --help"
  exit 2
fi
