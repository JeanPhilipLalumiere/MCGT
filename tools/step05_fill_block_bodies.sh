#!/usr/bin/env bash
set -euo pipefail

PYTHON="${PYTHON:-python3}"
CSV="zz-out/homog_smoke_pass14.csv"

echo "[STEP05] 0) Smoke de référence"
tools/pass14_smoke_with_mapping.sh

echo "[STEP05] 1) Cibler les 'expected an indented block after ... on line N'"
awk -F, 'NR>1{
  n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i;
  if (r ~ /IndentationError: expected an indented block after/) print $1"|"r
}' "$CSV" > zz-out/_indent_expected_full.lst || true

cut -d'|' -f1 zz-out/_indent_expected_full.lst | sort -u > zz-out/_indent_expected.lst || true
wc -l zz-out/_indent_expected.lst

echo "[STEP05] 2) Patch ciblé: insertion de 'pass' au bon niveau après la ligne fautive"
$PYTHON - <<'PY'
import csv, pathlib, re

CSV_PATH = pathlib.Path("zz-out/_indent_expected_full.lst")
if not CSV_PATH.exists():
    print("[INFO] rien à patcher"); raise SystemExit(0)

# file -> set(line_numbers)
targets = {}
for raw in CSV_PATH.read_text(encoding="utf-8").splitlines():
    if not raw.strip(): continue
    path, reason = raw.split("|", 1)
    m = re.search(r"expected an indented block after '(\w+)' statement on line (\d+)", reason)
    if not m: 
        continue
    line_no = int(m.group(2))
    targets.setdefault(path, set()).add(line_no)

def indent_of(s:str)->int: 
    return len(s) - len(s.lstrip(' '))

def ensure_pass(path: pathlib.Path, line_no: int) -> bool:
    """Insère un 'pass' à indent+4 juste après line_no si le bloc est vide ou mal indenté."""
    txt = path.read_text(encoding="utf-8")
    lines = txt.splitlines(True)
    i = line_no - 1
    if i < 0 or i >= len(lines): 
        return False
    base = indent_of(lines[i])

    # chercher premier non-vide/commentaire après i
    j = i + 1
    while j < len(lines) and (lines[j].strip() == "" or lines[j].lstrip().startswith("#")):
        j += 1

    # si déjà un contenu à indent > base -> OK, rien à faire
    if j < len(lines) and indent_of(lines[j]) > base:
        return False

    # si la ligne j contient déjà 'pass' au niveau base+4 -> rien à faire
    if j < len(lines):
        stripped = lines[j].strip()
        if stripped.startswith("pass"):
            return False

    # insérer un pass à base+4 à l'index j
    ins = " " * (base + 4) + "pass  # auto-added by STEP05\n"
    lines.insert(j, ins)

    new = "".join(lines)
    try:
        compile(new, str(path), "exec")
    except SyntaxError:
        # si compile échoue quand même, on garde la modif (elle pourra permettre le passage suivant)
        pass

    if new != txt:
        path.write_text(new, encoding="utf-8")
        print(f"[PASS+] {path}:{line_no}")
        return True
    return False

changed_any = False
for p, lineset in targets.items():
    P = pathlib.Path(p)
    if not P.exists(): 
        continue
    for ln in sorted(lineset):
        try:
            changed_any |= ensure_pass(P, ln)
        except Exception as e:
            print(f"[WARN] {P}:{ln} -> {e}")

print(f"[RESULT] step05_changed={changed_any}")
PY

echo "[STEP05] 3) Relancer STEP02 (virgules add_argument) + recompile ciblée"
tools/step02_fix_add_argument_commas.sh || true

echo "[STEP05] 4) Smoke + top erreurs"
tools/pass14_smoke_with_mapping.sh
awk -F, 'NR>1{n=NF;r=$3;for(i=4;i<=n-3;i++)r=r","$i;printf "%s: %s\n",$2,r}' "$CSV" \
| LC_ALL=C sort | uniq -c | LC_ALL=C sort -nr | head -25
