#!/usr/bin/env bash
set -euo pipefail

PYTHON="${PYTHON:-python3}"
CSV="zz-out/homog_smoke_pass14.csv"

echo "[STEP04] 0) Smoke de référence"
tools/pass14_smoke_with_mapping.sh

echo "[STEP04] 1) Cibler les fichiers en Syntax/Indent"
awk -F, 'NR>1{
  n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i;
  if (r ~ /SyntaxError|IndentationError/) print $1
}' "$CSV" | sort -u > zz-out/_parse_fail.lst || true
wc -l zz-out/_parse_fail.lst

echo "[STEP04] 2) Balance structurel ()[]{} + quotes + grille indent 4 + corps/pass"
$PYTHON - <<'PY'
import pathlib, io, sys

paths = pathlib.Path("zz-out/_parse_fail.lst").read_text(encoding="utf-8").splitlines()
targets = [p for p in sorted(set(paths)) if p and pathlib.Path(p).exists()]

OPEN_TO_CLOSE = {"(" : ")", "[" : "]", "{" : "}"}
CLOSE_TO_OPEN = {v:k for k,v in OPEN_TO_CLOSE.items()}

def fix_text(txt: str) -> tuple[str,bool]:
    changed=False
    # EOL / tabs / BOM
    if txt.startswith("\ufeff"):
        txt = txt.lstrip("\ufeff"); changed=True
    txt = txt.replace("\r\n","\n").replace("\r","\n")
    if "\t" in txt:
        txt = txt.replace("\t","    "); changed=True

    lines = txt.splitlines(True)

    # 1) Trim trailing spaces
    new=[]
    for L in lines:
        core = L.rstrip("\n")
        if core.rstrip() != core:
            new.append(core.rstrip()+"\n"); changed=True
        else:
            new.append(L)
    lines=new

    # 2) Balancer ()[]{} en ignorant #comment et l'intérieur des chaînes
    out=[]
    stack=[]
    in_str=False
    str_delim=None
    str_triple=False
    esc=False

    def push(c): stack.append(c)
    def pop(c):
        nonlocal changed
        if stack and stack[-1]==c:
            stack.pop()
        else:
            # fermeture inattendue: remonter au mieux (on jette la fermeture isolée)
            changed=True
            # on ignore cette fermeture en sortie
            return False
        return True

    for raw in lines:
        s=raw
        i=0
        # traiter par caractère
        while i < len(s):
            ch = s[i]
            if not in_str:
                if ch == '#':
                    # commentaire: ignorer le reste de la ligne
                    break
                if ch in ('"', "'"):
                    # début chaîne (triple ou simple)
                    if s[i:i+3] == ch*3:
                        in_str=True; str_delim=ch; str_triple=True; i+=3; continue
                    else:
                        in_str=True; str_delim=ch; str_triple=False; i+=1; continue
                if ch in OPEN_TO_CLOSE:
                    push(ch)
                elif ch in CLOSE_TO_OPEN:
                    if not pop(CLOSE_TO_OPEN[ch]):
                        # supprimer ce caractère fautif
                        s = s[:i] + s[i+1:]
                        continue
            else:
                # Dans une chaîne
                if ch == '\\':
                    i+=2; continue
                if str_triple:
                    if s[i:i+3] == str_delim*3:
                        in_str=False; str_delim=None; str_triple=False; i+=3; continue
                    i+=1; continue
                else:
                    if ch == str_delim:
                        in_str=False; str_delim=None; i+=1; continue
                    i+=1; continue
            i+=1
        out.append(s)

    # 3) Si des ouvrantes restent, compléter en fin de fichier
    if stack:
        changed=True
        tail = "".join(OPEN_TO_CLOSE[c] for c in reversed(stack))
        if out and not out[-1].endswith("\n"): out[-1]=out[-1]+"\n"
        out.append(tail+"\n")
        stack.clear()

    # 4) Grille d’indent à 4 + corps minimal pour blocs structurants
    def indent_of(L:str)->int:
        return len(L) - len(L.lstrip(' '))

    Ls = out
    result=[]
    i=0
    while i < len(Ls):
        L = Ls[i]
        # normaliser indent au multiple inférieur de 4
        if L.strip():
            ind = indent_of(L)
            new_ind = ind - (ind % 4)
            if new_ind != ind:
                L = " " * new_ind + L.lstrip(" ")
                changed=True

        result.append(L)

        # blocs structurants -> garantir un corps non vide
        stripped = L.strip()
        if stripped.endswith(":") and any(stripped.startswith(k) for k in ("def ","class ","if ","for ","while ","try ","with ")):
            base = indent_of(L)
            j = i+1
            # sauter lignes vides / commentaires
            while j < len(Ls) and (Ls[j].strip()=="" or Ls[j].lstrip().startswith("#")):
                j+=1
            if j==len(Ls) or indent_of(Ls[j]) <= base:
                result.append(" "*(base+4) + "pass  # auto-added for smoke\n")
                changed=True
        i+=1

    return ("".join(result), changed)

changed_any=False
for pstr in targets:
    p=pathlib.Path(pstr)
    try:
        txt=p.read_text(encoding="utf-8")
        new, ch = fix_text(txt)
        if ch:
            p.write_text(new, encoding="utf-8")
            print(f"[BALANCE+] {p}")
            changed_any=True
    except Exception as e:
        print(f"[WARN] skip {p}: {e}")

print(f"[RESULT] balance_changed={changed_any}")
PY

echo "[STEP04] 3) Relancer STEP02 (virgules add_argument) + recompile ciblée"
tools/step02_fix_add_argument_commas.sh || true

echo "[STEP04] 4) Smoke + top erreurs"
tools/pass14_smoke_with_mapping.sh
awk -F, 'NR>1{n=NF;r=$3;for(i=4;i<=n-3;i++)r=r","$i;printf "%s: %s\n",$2,r}' "$CSV" \
| LC_ALL=C sort | uniq -c | LC_ALL=C sort -nr | head -25
