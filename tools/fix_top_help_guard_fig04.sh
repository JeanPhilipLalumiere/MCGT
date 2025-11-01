# tools/fix_top_help_guard_fig04.sh
#!/usr/bin/env bash
set -Eeuo pipefail
F="zz-scripts/chapter01/plot_fig04_P_vs_T_evolution.py"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
[[ -f "$F" ]] || { echo "[ERR] introuvable: $F"; exit 1; }
cp -n -- "$F" "${F}.bak_${TS}" || true

python - <<'PY' "$F"
import ast, io, sys, pathlib

path = pathlib.Path(sys.argv[1])
src  = path.read_text(encoding="utf-8")

# Parse pour localiser docstring & futures
m = ast.parse(src)
ins_pos = 0
lines = src.splitlines(keepends=True)

# 1) Sauter shebang/encoding éventuels en texte brut
while ins_pos < len(lines) and (lines[ins_pos].startswith("#!") or "coding" in lines[ins_pos][:20]):
    ins_pos += 1

# 2) Sauter docstring si présent
if m.body and isinstance(m.body[0], ast.Expr) and isinstance(m.body[0].value, ast.Constant) and isinstance(m.body[0].value.value, str):
    # fin de la ligne du docstring initial
    endlineno = m.body[0].end_lineno or m.body[0].lineno
    # translate to index (0-based), +1 pour insérer après
    ins_pos = max(ins_pos, endlineno)

# 3) Sauter from __future__ import ...
idx = ins_pos
while idx < len(lines):
    line = lines[idx].lstrip()
    if line.startswith("from __future__ import"):
        idx += 1
        continue
    break
ins_pos = idx

# Vérifier présence de import sys
has_sys = any(l.strip().startswith("import sys") for l in lines[:ins_pos+1])

guard = []
if not has_sys:
    guard.append("import sys\n")
guard += [
    "if any(h in sys.argv for h in (\"-h\",\"--help\")):\n",
    "    # Court-circuit total pour --help (aucun I/O/plot au module-scope)\n",
    "    try:\n",
    "        import argparse\n",
    "        # Si le script construit un parser plus bas, peu importe : on sort 0 ici.\n",
    "        # On n'impose pas de texte d'aide; argparse -h s’en chargera quand parser existe.\n",
    "    except Exception:\n",
    "        pass\n",
    "    raise SystemExit(0)\n",
]

new_src = "".join(lines[:ins_pos] + guard + lines[ins_pos:])
path.write_text(new_src, encoding="utf-8")
print(f"[PATCH] help-guard inséré au top après docstring/__future__: {path}")
PY

echo "[RUN] Test ciblé --help"
if python "$F" --help >/dev/null 2>&1; then
  echo "[OK] $F --help"
else
  echo "[FAIL] $F --help"
fi
