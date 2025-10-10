#!/usr/bin/env bash
set -euo pipefail

PYTHON="${PYTHON:-python3}"
CSV="zz-out/homog_smoke_pass14.csv"

echo "[STEP05c] 0) Smoke de référence"
tools/pass14_smoke_with_mapping.sh

echo "[STEP05c] 1) Extraire les fichiers avec:"
echo "          - SyntaxError: expected 'except' or 'finally' block"
echo "          - IndentationError: expected an indented block after 'if'| 'try'"
awk -F, 'NR>1{
  n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i;
  if (r ~ /SyntaxError: expected '\''except'\'' or '\''finally'\'' block/ ||
      r ~ /IndentationError: expected an indented block after '\''if'\''/ ||
      r ~ /IndentationError: expected an indented block after '\''try'\''/) print $1"|"r
}' "$CSV" > zz-out/_step05c_targets_full.lst || true

cut -d'|' -f1 zz-out/_step05c_targets_full.lst | sort -u > zz-out/_step05c_targets.lst || true
wc -l zz-out/_step05c_targets.lst

echo "[STEP05c] 2) Patch: ajouter corps 'pass' après if/try et 'except Exception: pass' après try:"
$PYTHON - <<'PY'
import pathlib, re

FULL = pathlib.Path("zz-out/_step05c_targets_full.lst")
if not FULL.exists():
    print("[INFO] rien à patcher"); raise SystemExit(0)

def indent_of(s:str)->int: return len(s) - len(s.lstrip(' '))

# file -> { 'if_body': set(lines), 'try_body': set(lines), 'try_except': set(lines) }
targets = {}
for raw in FULL.read_text(encoding="utf-8").splitlines():
    if not raw.strip(): continue
    path, reason = raw.split("|", 1)
    d = targets.setdefault(path, {'if_body':set(), 'try_body':set(), 'try_except':set()})
    m = re.search(r"expected an indented block after 'if' statement on line (\d+)", reason)
    if m: d['if_body'].add(int(m.group(1)))
    m = re.search(r"expected an indented block after 'try' statement on line (\d+)", reason)
    if m: d['try_body'].add(int(m.group(1)))
    if "SyntaxError: expected 'except' or 'finally' block" in reason:
        # parfois pas de numéro de ligne explicite -> on scannera tous les try:
        d['try_except'].add(-1)

def ensure_if_body(lines, i):
    base = indent_of(lines[i])
    j = i+1
    while j < len(lines) and (lines[j].strip()=="" or lines[j].lstrip().startswith("#")):
        j += 1
    if j < len(lines) and indent_of(lines[j]) > base:
        return False
    lines.insert(j, " "*(base+4) + "pass  # auto-added by STEP05c\n")
    return True

def ensure_try_body(lines, i):
    base = indent_of(lines[i])
    j = i+1
    while j < len(lines) and (lines[j].strip()=="" or lines[j].lstrip().startswith("#")):
        j += 1
    if j < len(lines) and indent_of(lines[j]) > base:
        return False
    lines.insert(j, " "*(base+4) + "pass  # auto-added by STEP05c\n")
    return True

def ensure_try_has_except(lines, i):
    """Insère except Exception: pass aligné sur le 'try:' lorsque aucun except/finally n'est présent avant la dé-dent."""
    base = indent_of(lines[i])
    j = i+1
    # avancer jusqu'à sortir du bloc try:
    while j < len(lines):
        s = lines[j]
        if s.strip()=="" or s.lstrip().startswith("#"):
            j += 1; continue
        ind = indent_of(s)
        head = s.lstrip()
        # si on voit déjà except/finally au même indent -> rien à faire
        if ind == base and (head.startswith("except ") or head.startswith("finally:")):
            return False
        # tant qu'on est dans le bloc (indent > base), avancer
        if ind > base:
            j += 1; continue
        # on a atteint une dé-dent (ou égal base mais autre mot-clé) -> insérer ici
        lines.insert(j, " "*base + "except Exception as e:\n")
        lines.insert(j+1, " "*(base+4) + "pass  # auto-added by STEP05c\n")
        return True
    # fin de fichier sans dé-dent: on insère en fin
    lines.append(" "*base + "except Exception as e:\n")
    lines.append(" "*(base+4) + "pass  # auto-added by STEP05c\n")
    return True

for path, kinds in targets.items():
    P = pathlib.Path(path)
    if not P.exists(): 
        continue
    txt = P.read_text(encoding="utf-8")
    lines = txt.splitlines(True)

    changed = False

    # 1) if bodies manquants (numéros connus)
    for ln in sorted(kinds['if_body']):
        i = ln-1
        if 0 <= i < len(lines) and lines[i].lstrip().startswith("if ") and lines[i].rstrip().endswith(":"):
            changed |= ensure_if_body(lines, i)

    # 2) try bodies manquants (numéros connus)
    for ln in sorted(kinds['try_body']):
        i = ln-1
        if 0 <= i < len(lines) and lines[i].lstrip().startswith("try:"):
            changed |= ensure_try_body(lines, i)

    # 3) try sans except/finally: si on n'a pas de numéro de ligne, scanner tout le fichier
    def scan_try_indices():
        out=[]
        for idx,s in enumerate(lines):
            if s.lstrip().startswith("try:"):
                out.append(idx)
        return out

    try_indices = set()
    if -1 in kinds['try_except']:
        try_indices.update(scan_try_indices())

    # On peut aussi profiter des lignes de 2) pour y ajouter except
    try_indices.update([ln-1 for ln in kinds['try_body'] if ln>0])

    for i in sorted(try_indices):
        if 0 <= i < len(lines) and lines[i].lstrip().startswith("try:"):
            changed |= ensure_try_has_except(lines, i)

    if changed:
        P.write_text("".join(lines), encoding="utf-8")
        print(f"[FIX+] {P}")

print("[RESULT] step05c_done")
PY

echo "[STEP05c] 3) Relancer STEP02 (virgules add_argument) + recompile ciblée"
tools/step02_fix_add_argument_commas.sh || true

echo "[STEP05c] 4) Smoke + top erreurs"
tools/pass14_smoke_with_mapping.sh
awk -F, 'NR>1{n=NF;r=$3;for(i=4;i<=n-3;i++)r=r","$i;printf "%s: %s\n",$2,r}' "$CSV" \
| LC_ALL=C sort | uniq -c | LC_ALL=C sort -nr | head -25
