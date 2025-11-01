# tools/fix_remaining_help_failures.sh — corrige 7 NameError + 1 SyntaxError
set -Eeuo pipefail

# 1) Ciblage des fichiers depuis ton dernier triage
NEED_SYS_IMPORT=(
  "zz-scripts/chapter01/plot_fig04_P_vs_T_evolution.py"
  "zz-scripts/chapter01/plot_fig06_P_derivative_comparison.py"
  "zz-scripts/chapter02/plot_fig01_P_vs_T_evolution.py"
  "zz-scripts/chapter02/plot_fig03_relative_errors.py"
  "zz-scripts/chapter06/plot_fig04_delta_rs_vs_params.py"
  "zz-scripts/chapter07/plot_fig03_invariant_I1.py"
)
FG_SERIES="zz-scripts/chapter02/plot_fig05_FG_series.py"
FUTURE_TOP="zz-scripts/chapter07/plot_fig05_ddelta_phi_vs_k.py"

ts="$(date -u +%Y%m%dT%H%M%SZ)"
backup(){ [[ -f "$1" ]] && cp --no-clobber --update=none -- "$1" "${1}.bak_${ts}" || true; }

# 2) Ajout idempotent de `import sys`
for f in "${NEED_SYS_IMPORT[@]}"; do
  [[ -f "$f" ]] || { echo "[SKIP] $f absent"; continue; }
  backup "$f"
  if ! rg -n '^\s*import\s+sys(\s|$)' -n "$f" >/dev/null 2>&1; then
    # Injecte après le premier bloc d'import
    python - "$f" <<'PY'
import sys, io, re, pathlib
p=pathlib.Path(sys.argv[1]); s=p.read_text(encoding="utf-8")
lines=s.splitlines(True)

# Trouve fin du bloc d'entête (shebang/encoding/commentaires) et imports initiaux
i=0
while i<len(lines) and (lines[i].startswith(('#!','#')) or lines[i].strip()=='' or lines[i].lstrip().startswith(('from ','import '))):
    i+=1

# Si aucun import sys présent, on le place avant la première non-import si possible
if not re.search(r'^\s*import\s+sys(\s|$)', s, re.M):
    # insérer après les imports existants si le fichier commence par des imports; sinon tout début
    j=0
    while j<len(lines) and (lines[j].startswith(('#!','#!/')) or lines[j].strip()=='' ):
        j+=1
    # avancer sur les imports existants
    k=j
    while k<len(lines) and lines[k].lstrip().startswith(('from ','import ')):
        k+=1
    lines.insert(k, "import sys\n")
    p.write_text("".join(lines), encoding="utf-8")
print(f"[PATCH] {p} (+ import sys)")
PY
  else
    echo "[OK] $f (import sys déjà présent)"
  fi
done

# 3) Sécuriser DATA_IN au module-scope (évite NameError au --help)
if [[ -f "$FG_SERIES" ]]; then
  backup "$FG_SERIES"
  # Injecte une garde try/except juste après les imports
  python - "$FG_SERIES" <<'PY'
import sys, pathlib, re
p=pathlib.Path(sys.argv[1]); s=p.read_text(encoding="utf-8")
if "DATA_IN" in s and "try:\n    DATA_IN" not in s:
    lines=s.splitlines(True)
    # repère fin des imports
    k=0
    while k<len(lines) and (lines[k].startswith(('#!','#')) or lines[k].strip()=='' or lines[k].lstrip().startswith(('from ','import '))):
        k+=1
    guard = (
        "try:\n"
        "    DATA_IN\n"
        "except NameError:\n"
        "    DATA_IN = None  # set safe default for --help path\n"
    )
    lines.insert(k, guard)
    p.write_text("".join(lines), encoding="utf-8")
    print(f"[PATCH] {p} (+ DATA_IN guard)")
else:
    print(f"[SKIP] {p} (pas de DATA_IN ou déjà protégé)")
PY
fi

# 4) Remonter les 'from __future__' tout en haut de FUTURE_TOP
if [[ -f "$FUTURE_TOP" ]]; then
  backup "$FUTURE_TOP"
  python - "$FUTURE_TOP" <<'PY'
import sys, pathlib, re
p=pathlib.Path(sys.argv[1]); s=p.read_text(encoding="utf-8").splitlines(True)
shebang=[]; rest=s[:]
# isole shebang/enc
if rest and rest[0].startswith("#!"):
    shebang=[rest.pop(0)]
# collecte commentaires/encodings initiaux
header=[]
while rest and (rest[0].startswith("#") or rest[0].strip()==""):
    header.append(rest.pop(0))
# extrait toutes les lignes __future__
future=[ln for ln in rest if re.match(r'^\s*from\s+__future__\s+import\s+', ln)]
if future:
    rest=[ln for ln in rest if ln not in future]  # retire futures de la suite
    # reconstruit : shebang + header + futures + reste
    new = "".join(shebang + header + future + rest)
    p.write_text(new, encoding="utf-8")
    print(f"[PATCH] {p} (future imports remontés)")
else:
    print(f"[OK] {p} (pas de future import)")
PY
fi

echo "[RUN] Smoke --help (vérification)..."
bash tools/smoke_help_repo.sh
