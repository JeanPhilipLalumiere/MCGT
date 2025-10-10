#!/usr/bin/env bash
set -euo pipefail
export PYTHONPATH="${PYTHONPATH:-}:$PWD"
CSV="zz-out/homog_smoke_pass14.csv"

echo "[STEP25] 0) Smoke de référence"
tools/pass14_smoke_with_mapping.sh

echo "[STEP25] 1) Cibler: 'cannot assign…' + 'Maybe you meant ==…' + 'expected an indented block after if'"
awk -F, 'NR>1{
  n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i;
  if (r ~ /cannot assign to expression here/ ||
      r ~ /Maybe you meant '\''=='\''/ ||
      r ~ /Maybe you meant '\''=='\'' or '\':'='\'' instead of '\''='\''/ ||
      r ~ /IndentationError: expected an indented block after '\''if'\''/) print $1
}' "$CSV" | sort -u > zz-out/_step25_targets.lst || true
wc -l zz-out/_step25_targets.lst

echo "[STEP25] 2) Profondeur: '=' dans têtes (incl. parenthèses) en évitant les kwargs d'appel + 'pass' si nécessaire"
python3 - <<'PY'
from pathlib import Path
import re

targets = Path("zz-out/_step25_targets.lst").read_text(encoding="utf-8").splitlines()
targets = [t for t in sorted(set(targets)) if t and Path(t).exists()]

OPEN, CLOSE = "([{" , ")]}"
NEXT_KWS = re.compile(r'^\s*(elif|else|except|finally)\b')
HEAD_START = re.compile(r'^(\s*)(if|elif|while)\b')

def head_span(lines, i, max_look=40):
    """Capture depuis la ligne i jusqu'au ':' de fin de tête au niveau 0. Renvoie (j_end, text)."""
    d=0; sq=dq=False; buf=[]; j=i
    while j < len(lines) and j < i+max_look:
        s = lines[j]; buf.append(s); k=0
        while k < len(s):
            c=s[k]
            if sq:
                if c == "\\": k += 2; continue
                if c == "'": sq=False
            elif dq:
                if c == "\\": k += 2; continue
                if c == '"': dq=False
            else:
                if c == '#': break
                if c == "'": sq=True
                elif c == '"': dq=True
                elif c in OPEN: d += 1
                elif c in CLOSE: d = max(0, d-1)
                elif c == ':' and d == 0:
                    return j, "".join(buf)
            k += 1
        j += 1
    return None, "".join(buf)

def eq_positions_all(head_text):
    """Tous les '=' (hors ==, !=, <=, >=, :=) même sous parenthèses, mais hors chaînes/commentaires."""
    pos=[]; d=0; sq=dq=False; i=0
    while i < len(head_text):
        c=head_text[i]
        if sq:
            if c == "\\": i += 2; continue
            if c == "'": sq=False
        elif dq:
            if c == "\\": i += 2; continue
            if c == '"': dq=False
        else:
            if c == '#': break
            if c in OPEN: d += 1
            elif c in CLOSE: d = max(0, d-1)
            elif c == '=':
                prev = head_text[i-1] if i>0 else ''
                nxt  = head_text[i+1] if i+1 < len(head_text) else ''
                if nxt == '=' or prev in ('!','<','>') or prev==':':
                    pass  # ==, !=, <=, >=, := -> on ignore
                else:
                    pos.append(i)
        i += 1
    return pos

def is_kwarg_of_call(head_text, eq_index):
    """Heuristique: si l' '=' est dans des '()' précédés d'un identifiant/.)/], on considère un appel -> kwarg."""
    # trouver la paren ouvrante qui englobe eq_index
    stack=[]
    for i,ch in enumerate(head_text):
        if ch in OPEN:
            stack.append((ch,i))
        elif ch in CLOSE and stack:
            opener, pos = stack.pop()
        if i == eq_index:
            break
    # si aucune paren ouverte encore sur la pile, pas dans () -> pas un kwarg d'appel
    if not stack: 
        return False
    # paren englobante = le dernier élément de la pile
    opener, pos = stack[-1]
    if opener != '(':
        return False
    # regarder le char non-espace juste avant cette '('
    k = pos-1
    while k >= 0 and head_text[k].isspace():
        k -= 1
    if k < 0: 
        return False
    ch = head_text[k]
    # si identifiant/.)/] => fortement probable que ce soit un appel
    if ch.isalnum() or ch in '._)]':
        return True
    return False

def apply_eq_fixes(chunk, head_text):
    """Remplace les '=' candidats par '==', sauf kwargs d'appel."""
    positions = eq_positions_all(head_text)
    # filtrer kwargs
    todo = [p for p in positions if not is_kwarg_of_call(head_text, p)]
    if not todo: 
        return chunk, 0
    out=list(chunk)
    for p in reversed(todo):
        out[p:p+1] = ['=','=']
    return "".join(out), len(todo)

def insert_pass_if_needed(lines, head_start_i, head_end_j):
    base_indent = len(lines[head_start_i]) - len(lines[head_start_i].lstrip(" "))
    k = head_end_j + 1
    while k < len(lines) and (lines[k].strip()=="" or lines[k].lstrip().startswith("#")):
        k += 1
    need_pass = (k >= len(lines) or
                 (len(lines[k]) - len(lines[k].lstrip(" ")) <= base_indent) or
                 NEXT_KWS.match(lines[k]))
    if need_pass:
        lines.insert(head_end_j+1, " "*(base_indent+4) + "pass\n")
        return True
    return False

tot_files=0; tot_eq=0; tot_pass=0
for path in targets:
    p=Path(path)
    raw=p.read_text(encoding="utf-8")
    lines=raw.splitlines(keepends=True)
    changed=False; i=0
    while i < len(lines):
        m = HEAD_START.match(lines[i])
        if not m: 
            i += 1; continue
        j_end, head_text = head_span(lines, i)
        if j_end is None:
            i += 1; continue
        chunk = "".join(lines[i:j_end+1])
        new_chunk, nfix = apply_eq_fixes(chunk, head_text)
        if nfix:
            lines[i:j_end+1] = new_chunk.splitlines(keepends=True)
            changed=True; tot_eq += nfix
        if insert_pass_if_needed(lines, i, j_end):
            changed=True; tot_pass += 1
            i = j_end + 2
        else:
            i = j_end + 1
    new="".join(lines)
    if new != raw:
        p.write_text(new, encoding="utf-8")
        tot_files += 1
        print(f"[STEP25-FIX] {path}: eq_fixes={tot_eq} pass_added={tot_pass}")
print(f"[RESULT] step25_changed_files={tot_files} eq_total={tot_eq} pass_total={tot_pass}")
PY

echo "[STEP25] 3) Smoke + Top erreurs"
tools/pass14_smoke_with_mapping.sh
awk -F, 'NR>1{ n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i; printf "%s: %s\n",$2,r }' "$CSV" \
  | LC_ALL=C sort | uniq -c | LC_ALL=C sort -nr | head -25
