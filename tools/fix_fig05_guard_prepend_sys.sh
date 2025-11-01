#!/usr/bin/env bash
set -Eeuo pipefail
F="zz-scripts/chapter02/plot_fig05_FG_series.py"
[[ -f "$F" ]] || { echo "[ERR] introuvable: $F"; exit 1; }

ts="$(date -u +%Y%m%dT%H%M%SZ)"; cp -n -- "$F" "${F}.bak_${ts}" || true

python - <<'PY'
import re, pathlib
F = pathlib.Path("zz-scripts/chapter02/plot_fig05_FG_series.py")
src = F.read_text(encoding="utf-8")
lines = src.splitlines(True)

# repères structuraux
i = 0
if i < len(lines) and lines[i].startswith("#!"):  # shebang
    i += 1
enc_pat = re.compile(r"coding[:=]\s*[-\w.]+")
for _ in range(2):                                # cookie encodage (dans 2 premières lignes)
    if i < len(lines) and enc_pat.search(lines[i]):
        i += 1
while i < len(lines) and re.match(r"\s*from\s+__future__\s+import\s+", lines[i]):
    i += 1

guard_re = re.compile(r"^\s*if\s+.*sys\.argv.*:\s*(?:#.*)?$")
import_sys_re = re.compile(r"^\s*import\s+sys\s*$")

# localiser premier garde et premier import sys
guard_idx = next((k for k,l in enumerate(lines) if guard_re.match(l)), None)
import_idx = next((k for k,l in enumerate(lines) if import_sys_re.match(l)), None)

changed = False

# 1) S'assurer que import sys est AVANT le garde (ou à défaut insérer avant le garde, mais après shebang/enc/.__future__)
if guard_idx is not None:
    must_insert_at = min(guard_idx, i) if guard_idx < i else i  # si garde avant blocs spéciaux (cas patho), on force à i
    if import_idx is None or import_idx > guard_idx:
        lines.insert(must_insert_at, "import sys\n")
        changed = True

# 2) Garantir l'exit immédiat après le garde
if guard_idx is not None:
    # si on vient d'insérer import sys avant, le garde a pris +1
    if changed and (import_idx is None or import_idx > guard_idx):
        guard_idx += 1
    # chercher la première ligne significative après le garde
    j = guard_idx + 1
    while j < len(lines) and (lines[j].strip() == "" or lines[j].lstrip().startswith("#")):
        j += 1
    if not (j < len(lines) and re.match(r"\s*(?:raise\s+SystemExit\(\s*0\s*\)|sys\.exit\(\s*0\s*\)|return\s+0)\s*$", lines[j] or "")):
        indent = ' ' * (len(lines[guard_idx]) - len(lines[guard_idx].lstrip()))
        lines.insert(guard_idx + 1, f"{indent}raise SystemExit(0)\n")
        changed = True

new = "".join(lines)
if changed:
    F.write_text(new, encoding="utf-8")
    print("[PATCH] fig05: import sys déplacé/inséré avant le garde + exit garanti")
else:
    print("[OK] fig05: rien à changer")
PY

echo "[RUN] Test ciblé --help"
python "$F" --help >/dev/null 2>&1 && echo "[OK] $F --help" || { echo "[FAIL] $F --help"; exit 2; }
