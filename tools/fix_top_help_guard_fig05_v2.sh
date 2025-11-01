#!/usr/bin/env bash
set -Eeuo pipefail
F="zz-scripts/chapter02/plot_fig05_FG_series.py"
[[ -f "$F" ]] || { echo "[ERR] introuvable: $F"; exit 1; }

ts="$(date -u +%Y%m%dT%H%M%SZ)"
cp --no-clobber --update=none -- "$F" "${F}.bak_${ts}" || true

python - <<'PY'
import ast, io, pathlib, sys
F = pathlib.Path("zz-scripts/chapter02/plot_fig05_FG_series.py")
src = F.read_text(encoding="utf-8")
mod = ast.parse(src)

# 1) calcule l'indice d'insertion après docstring + __future__
ins_at = 0
if mod.body and isinstance(mod.body[0], ast.Expr) and isinstance(mod.body[0].value, ast.Constant) and isinstance(mod.body[0].value.value, str):
    ins_at = 1
while ins_at < len(mod.body):
    n = mod.body[ins_at]
    if isinstance(n, ast.ImportFrom) and n.module == "__future__":
        ins_at += 1
    else:
        break

lines = src.splitlines(True)

# 2) assure import sys avant tout accès à sys.argv (dans les 25 premières lignes)
head25 = "".join(lines[:25])
if "import sys" not in head25:
    lines.insert(ins_at, "import sys\n")

# 3) normalise le garde top: s'il existe déjà un if any(... sys.argv ...) sans SystemExit, on l'arme;
#    sinon on l'ajoute proprement.
guard_idx = None
for i, L in enumerate(lines[:40]):
    if "sys.argv" in L and "('-h','--help')" in L.replace(" ", ""):
        guard_idx = i
        break
if guard_idx is None:
    # insère un garde minimaliste, juste après import sys nouvellement/anciennement présent
    # (recalcule ins_at car on a peut-être inséré import sys)
    mod2 = ast.parse("".join(lines))
    ins_at2 = 0
    if mod2.body and isinstance(mod2.body[0], ast.Expr) and isinstance(mod2.body[0].value, ast.Constant) and isinstance(mod2.body[0].value.value, str):
        ins_at2 = 1
    while ins_at2 < len(mod2.body):
        n = mod2.body[ins_at2]
        if isinstance(n, ast.ImportFrom) and n.module == "__future__":
            ins_at2 += 1
        elif isinstance(n, ast.Import) and any(a.name == "sys" for a in n.names):
            ins_at2 += 1
            break
        else:
            break
    guard = (
        "if any(h in sys.argv for h in ('-h','--help')):\n"
        "    raise SystemExit(0)\n"
    )
    lines.insert(ins_at2, guard)
else:
    # s'assure qu'on a bien un raise SystemExit(0) juste après
    j = guard_idx + 1
    need_raise = True
    if j < len(lines) and "SystemExit" in lines[j]:
        need_raise = False
    if need_raise:
        lines.insert(j, "    raise SystemExit(0)\n")

F.write_text("".join(lines), encoding="utf-8")
print("[PATCH] fig05: import sys + top-guard assurés")
PY

echo "[RUN] Test ciblé --help"
if python "$F" --help >/dev/null 2>&1; then
  echo "[OK] $F --help"
else
  echo "[FAIL] $F --help"
  exit 2
fi
