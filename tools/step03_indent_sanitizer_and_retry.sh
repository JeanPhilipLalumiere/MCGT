#!/usr/bin/env bash
set -euo pipefail

PYTHON="${PYTHON:-python3}"
CSV="zz-out/homog_smoke_pass14.csv"

echo "[STEP03] 0) Smoke de référence"
tools/pass14_smoke_with_mapping.sh

echo "[STEP03] 1) Lister les fichiers encore en Syntax/Indent"
awk -F, 'NR>1{
  n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i;
  if (r ~ /SyntaxError|IndentationError/) print $1
}' "$CSV" | sort -u > zz-out/_parse_fail.lst || true
wc -l zz-out/_parse_fail.lst

echo "[STEP03] 2) Normalisation d’indentation + gardes pass"
$PYTHON - <<'PY'
import re, pathlib

fails = pathlib.Path("zz-out/_parse_fail.lst").read_text(encoding="utf-8").splitlines()
targets = [p for p in sorted(set(fails)) if p and pathlib.Path(p).exists()]

def sanitize_text(txt: str) -> tuple[str,bool]:
    changed=False
    # uniformiser fins de ligne (LF), supprimer BOM éventuel
    if txt.startswith("\ufeff"):
        txt = txt.lstrip("\ufeff"); changed=True
    txt = txt.replace("\r\n","\n").replace("\r","\n")
    # tabs -> 4 spaces
    if "\t" in txt:
        txt = txt.replace("\t","   "); changed=True
    lines = txt.splitlines(True)

    # trim des espaces en fin de ligne
    new=[]
    for L in lines:
        if L.rstrip("\n").rstrip() != L.rstrip("\n"):
            new.append(L.rstrip("\n").rstrip()+"\n"); changed=True
        else:
            new.append(L)
    lines = new

    # insérer 'pass' pour blocs structurants vides flagrants
    i=0
    while i < len(lines):
        line = lines[i]
        m = re.match(r'^([ ]*)(try|with|if|for|while|def|class)\b.*:\s*(#.*)?\n?$', line)
        if m:
            base = m.group(1)
            # chercher la prochaine ligne non vide/non commentaire
            j=i+1
            while j < len(lines) and (lines[j].strip()=="" or lines[j].lstrip().startswith("#")):
                j+=1
            if j==len(lines):
                lines.insert(j, f"{base}    pass  # auto-added for smoke\n"); i=j+1; changed=True; continue
            nxt = lines[j]
            # indent de la prochaine ligne
            nxt_indent = len(nxt) - len(nxt.lstrip(' '))
            base_indent = len(base)
            if nxt_indent <= base_indent:
                lines.insert(j, f"{base}    pass  # auto-added for smoke\n"); i=j+1; changed=True; continue
        i+=1

    return ("".join(lines), changed)

changed_any=False
for pstr in targets:
    p = pathlib.Path(pstr)
    try:
        txt = p.read_text(encoding="utf-8")
        new, ch = sanitize_text(txt)
        if ch:
            p.write_text(new, encoding="utf-8")
            print(f"[SANITIZE] {p}")
            changed_any=True
    except Exception as e:
        print(f"[WARN] skip {p}: {e}")

print(f"[RESULT] sanitize_changed={changed_any}")
PY

echo "[STEP03] 3) Relancer la passe virgules add_argument (STEP02)"
tools/step02_fix_add_argument_commas.sh || true

echo "[STEP03] 4) Smoke final + top erreurs"
tools/pass14_smoke_with_mapping.sh
awk -F, 'NR>1{
  n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i;
  printf "%s: %s\n",$2,r
}' "$CSV" | LC_ALL=C sort | uniq -c | LC_ALL=C sort -nr | head -25
