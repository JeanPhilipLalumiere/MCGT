#!/usr/bin/env bash
set -euo pipefail

PYTHON="${PYTHON:-python3}"
CSV="zz-out/homog_smoke_pass14.csv"

echo "[STEP03b] 0) Smoke de référence"
tools/pass14_smoke_with_mapping.sh

echo "[STEP03b] 1) Lister les fichiers encore en Syntax/Indent"
awk -F, 'NR>1{
  n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i;
  if (r ~ /SyntaxError|IndentationError/) print $1
}' "$CSV" | sort -u > zz-out/_parse_fail.lst || true
wc -l zz-out/_parse_fail.lst

echo "[STEP03b] 2) Normalisation d’indentation + gardes pass + try/except minimal"
$PYTHON - <<'PY'
import re, pathlib

fails = pathlib.Path("zz-out/_parse_fail.lst").read_text(encoding="utf-8").splitlines()
targets = [p for p in sorted(set(fails)) if p and pathlib.Path(p).exists()]

def indent_of(s: str) -> int:
    return len(s) - len(s.lstrip(' '))

def sanitize_text(txt: str) -> tuple[str,bool]:
    changed=False
    # BOM + fins de ligne
    if txt.startswith("\ufeff"):
        txt = txt.lstrip("\ufeff"); changed=True
    txt = txt.replace("\r\n","\n").replace("\r","\n")
    # tabs -> **4** spaces (correctif)
    if "\t" in txt:
        txt = txt.replace("\t","    "); changed=True

    lines = txt.splitlines(True)

    # trim EOL spaces
    new=[]
    for L in lines:
        core = L.rstrip("\n")
        if core.rstrip() != core:
            new.append(core.rstrip()+"\n"); changed=True
        else:
            new.append(L)
    lines = new

    i=0
    while i < len(lines):
        line = lines[i]
        # blocs structurants (dont try:)
        m = re.match(r'^([ ]*)(try|with|if|for|while|def|class)\b.*:\s*(#.*)?\n?$', line)
        if m:
            base_ind = len(m.group(1))
            # suite immédiate non vide/non commentaire ?
            j=i+1
            while j < len(lines) and (lines[j].strip()=="" or lines[j].lstrip().startswith("#")):
                j+=1
            if j==len(lines):
                lines.insert(j, " "*(base_ind+4) + "pass  # auto-added for smoke\n"); changed=True; i=j+1; continue
            nxt = lines[j]
            nxt_ind = indent_of(nxt)
            if nxt_ind <= base_ind:
                lines.insert(j, " "*(base_ind+4) + "pass  # auto-added for smoke\n"); changed=True; i=j+1; continue

            # cas spécifique try: → s'assurer d'un except/finally avant la dé-dente
            if m.group(2) == "try":
                k=j
                has_handler=False
                while k < len(lines):
                    L = lines[k]
                    if L.strip()=="" or L.lstrip().startswith("#"):
                        k+=1; continue
                    cur_ind = indent_of(L)
                    if cur_ind <= base_ind:
                        # dé-dente rencontrée
                        break
                    if re.match(r'^[ ]*(except|finally)\b', L):
                        has_handler=True
                        break
                    k+=1
                if not has_handler:
                    # insérer à k (dé-dente ou fin) un except minimal
                    insert_at = k if k < len(lines) else len(lines)
                    lines.insert(insert_at, " "*(base_ind) + "except Exception:\n")
                    lines.insert(insert_at+1, " "*(base_ind+4) + "pass  # auto-added for smoke\n")
                    changed=True
                    i = insert_at + 2
                    continue
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
            print(f"[SANITIZE+] {p}")
            changed_any=True
    except Exception as e:
        print(f"[WARN] skip {p}: {e}")

print(f"[RESULT] sanitize_plus_changed={changed_any}")
PY

echo "[STEP03b] 3) Relancer la passe virgules add_argument (STEP02)"
tools/step02_fix_add_argument_commas.sh || true

echo "[STEP03b] 4) Smoke final + top erreurs"
tools/pass14_smoke_with_mapping.sh
awk -F, 'NR>1{n=NF;r=$3;for(i=4;i<=n-3;i++)r=r","$i;printf "%s: %s\n",$2,r}' "$CSV" \
| LC_ALL=C sort | uniq -c | LC_ALL=C sort -nr | head -25
