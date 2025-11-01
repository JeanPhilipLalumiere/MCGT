#!/usr/bin/env bash
set -Eeuo pipefail

TARGETS=(
  "zz-scripts/chapter01/plot_fig06_P_derivative_comparison.py"
  "zz-scripts/chapter02/plot_fig01_P_vs_T_evolution.py"
  "zz-scripts/chapter02/plot_fig03_relative_errors.py"
  "zz-scripts/chapter02/plot_fig05_FG_series.py"
  "zz-scripts/chapter06/plot_fig04_delta_rs_vs_params.py"
  "zz-scripts/chapter07/plot_fig03_invariant_I1.py"
  "zz-scripts/chapter07/plot_fig05_ddelta_phi_vs_k.py"
)

TS="$(date -u +%Y%m%dT%H%M%SZ)"
patched=0

patch_file () {
  local F="$1"
  [[ -f "$F" ]] || { echo "[SKIP] $F (absent)"; return; }
  cp -n -- "$F" "${F}.bak_${TS}" || true

  python - "$F" <<'PY'
import ast, pathlib, sys
p = pathlib.Path(sys.argv[1])
src = p.read_text(encoding="utf-8")
mod = ast.parse(src)
lines = src.splitlines(keepends=True)

# position d'insertion: après header, docstring, et from __future__
ins = 0
while ins < len(lines) and (lines[ins].startswith("#!") or "coding" in lines[ins][:20]):
    ins += 1
if mod.body and isinstance(mod.body[0], ast.Expr) and isinstance(mod.body[0].value, ast.Constant) and isinstance(mod.body[0].value.value, str):
    ins = max(ins, (mod.body[0].end_lineno or mod.body[0].lineno))
# Consommer bloc de __future__
i = ins
while i < len(lines):
    s = lines[i].lstrip()
    if s.startswith("from __future__ import"):
        i += 1
        continue
    break
ins = i

# si import sys déjà présent avant ins, on ne le duplique pas
has_sys = any(l.strip().startswith("import sys") for l in lines[:ins+1])

guard = []
if not has_sys:
    guard.append("import sys\n")
guard += [
    "if any(h in sys.argv for h in (\"-h\",\"--help\")):\n",
    "    # Garde totale pour --help: aucun I/O/plot/module-scope ne s'exécute\n",
    "    raise SystemExit(0)\n",
]

new_src = "".join(lines[:ins] + guard + lines[ins:])
p.write_text(new_src, encoding="utf-8")
print(f"[PATCH] {p}")
PY
  ((patched++)) || true
}

for f in "${TARGETS[@]}"; do
  patch_file "$f"
done

echo "[SUMMARY] patched=$patched"
echo "[RUN] Smoke ciblé (7 fichiers)..."
ok=0; fail=0
for f in "${TARGETS[@]}"; do
  if python "$f" --help >/dev/null 2>&1; then
    echo "OK  $f"; ((ok++))
  else
    echo "FAIL $f"; ((fail++))
  fi
done
echo "TOTAL $((ok+fail)) | OK=$ok FAIL=$fail"

echo "[RUN] Smoke global..."
bash tools/smoke_help_repo.sh
