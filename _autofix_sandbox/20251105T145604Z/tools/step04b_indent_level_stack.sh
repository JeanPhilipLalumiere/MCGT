#!/usr/bin/env bash
set -euo pipefail

PYTHON="${PYTHON:-python3}"
CSV="zz-out/homog_smoke_pass14.csv"

echo "[STEP04b] 0) Smoke de référence"
tools/pass14_smoke_with_mapping.sh

echo "[STEP04b] 1) Cibler les fichiers en Syntax/Indent"
awk -F, 'NR>1{
  n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i;
  if (r ~ /SyntaxError|IndentationError/) print $1
}' "$CSV" | sort -u > zz-out/_parse_fail.lst || true
wc -l zz-out/_parse_fail.lst

echo "[STEP04b] 2) Réparation de niveaux d’indentation (pile 4 espaces) + blocs vides -> pass"
$PYTHON - <<'PY'
import pathlib, re

fail_paths = pathlib.Path("zz-out/_parse_fail.lst").read_text(encoding="utf-8").splitlines()
targets = [p for p in sorted(set(fail_paths)) if p and pathlib.Path(p).exists()]

def eol_tabs_trim(txt: str) -> tuple[str,bool]:
    ch=False
    if txt.startswith("\ufeff"):
        txt = txt.lstrip("\ufeff"); ch=True
    t = txt.replace("\r\n","\n").replace("\r","\n")
    if "\t" in t:
        t = t.replace("\t","    "); ch=True
    # trim trailing spaces
    Ls = t.splitlines(True)
    out=[]
    for L in Ls:
        if L.endswith("\n"):
            core=L[:-1]
            if core.rstrip()!=core:
                out.append(core.rstrip()+"\n"); ch=True
            else: out.append(L)
        else:
            if L.rstrip()!=L:
                out.append(L.rstrip()); ch=True
            else: out.append(L)
    # newline final
    if out and not out[-1].endswith("\n"):
        out[-1]=out[-1]+"\n"; ch=True
    return ("".join(out), ch)

def indent_of(L:str)->int:
    return len(L) - len(L.lstrip(' '))

BLOCK_STARTS = ("def ","class ","if ","for ","while ","try ","with ","elif ","else:","except","finally:")

def normalize_indent_stack(txt: str) -> tuple[str,bool]:
    changed=False
    txt, ch1 = eol_tabs_trim(txt); changed |= ch1
    lines = txt.splitlines(True)
    res=[]
    stack=[0]  # niveaux autorisés
    N=len(lines)
    i=0
    while i<N:
        L = lines[i]
        if L.strip()=="" or L.lstrip().startswith("#"):
            res.append(L); i+=1; continue

        ind = indent_of(L)
        # forcer à multiple de 4
        if ind % 4 != 0:
            new_ind = ind - (ind % 4)
            L = " " * new_ind + L.lstrip(" ")
            ind = new_ind
            changed=True

        # si dé-dent vers un niveau jamais vu -> rabattre au plus proche niveau inférieur de la pile
        if ind not in stack:
            lower = [x for x in stack if x <= ind]
            ind_adj = max(lower) if lower else 0
            if ind_adj != ind:
                L = " " * ind_adj + L.lstrip(" ")
                ind = ind_adj
                changed=True

        # si sur-indent irrégulière -> monter d’un cran = +4 depuis sommet
        top = stack[-1]
        if ind > top:
            # n’autoriser que +4
            if ind - top != 4:
                ind = top + 4
                L = " " * ind + L.lstrip(" ")
                changed=True
            stack.append(ind)
        else:
            # normaliser pile pour ce niveau
            while stack and stack[-1] > ind:
                stack.pop()
            if not stack or stack[-1] != ind:
                stack.append(ind)  # garder la trace du niveau actuel

        res.append(L)

        s = L.strip()
        if s.endswith(":") and any(s.startswith(k) for k in BLOCK_STARTS):
            base = ind
            j = i+1
            # sauter vides/commentaires
            while j<N and (lines[j].strip()=="" or lines[j].lstrip().startswith("#")):
                j+=1
            # si bloc vide ou mal indenté -> injecter un pass
            if j==N or indent_of(lines[j]) <= base:
                res.append(" "*(base+4) + "pass  # auto-added by STEP04b\n")
                changed=True
        i+=1

    out = "".join(res)
    return out, changed

def try_fix_file(p: pathlib.Path) -> bool:
    src = p.read_text(encoding="utf-8")
    improved=False
    cur = src
    for _ in range(3):
        new, ch = normalize_indent_stack(cur)
        if ch:
            improved=True
        try:
            compile(new, str(p), "exec")
            if new != src:
                p.write_text(new, encoding="utf-8")
            print(f"[INDENT+] {p}")
            return True
        except SyntaxError as e:
            cur = new
            # on continue si on a modifié qqch ; sinon on sort
            if not ch:
                if new != src:
                    p.write_text(new, encoding="utf-8")
                print(f"[WARN] still syntax: {p}:{getattr(e,'lineno',0)} {getattr(e,'msg','SyntaxError')}")
                return False
    # dernière tentative écrite quand même si différente
    if cur != src:
        p.write_text(cur, encoding="utf-8")
    print(f"[INDENT~] {p} (partial)")
    return improved

changed_any=False
for pstr in targets:
    p = pathlib.Path(pstr)
    try:
        ok = try_fix_file(p)
        changed_any |= ok
    except Exception as e:
        print(f"[SKIP] {p}: {e}")

print(f"[RESULT] indent_stack_changed={changed_any}")
PY

echo "[STEP04b] 3) Relancer STEP02 (virgules add_argument) + recompile ciblée"
tools/step02_fix_add_argument_commas.sh || true

echo "[STEP04b] 4) Smoke + top erreurs"
tools/pass14_smoke_with_mapping.sh
awk -F, 'NR>1{n=NF;r=$3;for(i=4;i<=n-3;i++)r=r","$i;printf "%s: %s\n",$2,r}' "$CSV" \
| LC_ALL=C sort | uniq -c | LC_ALL=C sort -nr | head -25
