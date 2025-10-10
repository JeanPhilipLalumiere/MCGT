#!/usr/bin/env bash
set -euo pipefail
export PYTHONPATH="${PYTHONPATH:-}:$PWD"
CSV="zz-out/homog_smoke_pass14.csv"

echo "[STEP28] 0) Smoke de référence"
tools/pass14_smoke_with_mapping.sh

echo "[STEP28] 1) Cibler: cannot-assign / '== ?' / expected body after if"
awk -F, 'NR>1{
  n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i;
  if (r ~ /cannot assign to expression here/ ||
      r ~ /Maybe you meant '\''=='\''/ ||
      r ~ /invalid syntax\. Maybe you meant '\''==/ ||
      r ~ /IndentationError: expected an indented block after '\''if'\''/) print $1
}' "$CSV" | sort -u > zz-out/_step28_targets.lst || true
wc -l zz-out/_step28_targets.lst

echo "[STEP28] 2) Patch guidé par compile(): '=' -> '==' dans la tête fautive + 'pass' si nécessaire"
python3 - <<'PY'
from pathlib import Path
import io, re, sys

targets = Path("zz-out/_step28_targets.lst").read_text(encoding="utf-8").splitlines()
targets = [t for t in sorted(set(targets)) if t and Path(t).exists()]

OPEN, CLOSE = "([{" , ")]}"
HEAD_START = re.compile(r'^(\s*)(if|elif|while)\b')
NEXT_KWS   = re.compile(r'^\s*(elif|else|except|finally)\b')

def head_span(lines, i, max_look=100):
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
                    pass
                else:
                    pos.append(i)
        i += 1
    return pos

def is_kwarg_of_call(head_text, eq_index):
    stack=[]
    for i,ch in enumerate(head_text):
        if ch in OPEN: stack.append((ch,i))
        elif ch in CLOSE and stack: stack.pop()
        if i == eq_index: break
    if not stack: return False
    opener, pos = stack[-1]
    if opener != '(': return False
    k = pos-1
    while k >= 0 and head_text[k].isspace(): k -= 1
    if k < 0: return False
    return (head_text[k].isalnum() or head_text[k] in '._)]')

def replace_eq_near_offset(head_text, caret_col):
    # choisir l' '=' la plus proche du caret et non-kwarg; fallback: première non-kwarg
    eqs = [p for p in eq_positions_all(head_text) if not is_kwarg_of_call(head_text, p)]
    if not eqs: return head_text, 0
    eq = min(eqs, key=lambda p: abs(p - caret_col))
    return head_text[:eq] + "==" + head_text[eq+1:], 1

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

changed_files=0; tot_eq=0; tot_pass=0
for file in targets:
    p = Path(file)
    text = p.read_text(encoding="utf-8")
    lines = text.splitlines(keepends=True)
    made_change=False

    for _ in range(8):  # au plus 8 itérations/fichier
        try:
            compile("".join(lines), file, "exec")
            break
        except IndentationError as e:
            msg = str(e)
            if "expected an indented block after 'if' statement" in msg:
                ln = (e.lineno or e.args[1][1]) - 1
                # trouver le début de la tête correspondante
                i = ln
                while i >= 0 and not HEAD_START.match(lines[i]): i -= 1
                if i < 0: break
                end, _head = head_span(lines, i)
                if end is None: break
                if insert_pass_if_needed(lines, i, end):
                    tot_pass += 1; made_change=True
                    continue
            # sinon on ne traite pas
            break
        except SyntaxError as e:
            msg = str(e)
            # On ne vise que les '=' suspects
            if ("cannot assign to expression here" in msg) or ("Maybe you meant '=='" in msg):
                ln = (e.lineno or e.args[1][1]) - 1
                col = (e.offset or 1) - 1
                # localiser la tête qui englobe la ligne
                i = ln
                while i >= 0 and not HEAD_START.match(lines[i]): i -= 1
                if i < 0:
                    break
                end, head_txt = head_span(lines, i)
                if end is None: break
                # construire chunk et remplacer près du caret
                chunk = "".join(lines[i:end+1])
                # caret relatif au chunk: somme des longueurs jusqu'à ln + col
                rel = 0
                for k in range(i, ln):
                    rel += len(lines[k])
                rel += col
                new_head, patched = replace_eq_near_offset(head_txt, rel)
                if patched:
                    # remplace uniquement la partie tête dans chunk
                    pre = chunk[:len(chunk)-len(head_txt)]
                    new_chunk = pre + new_head
                    new_lines = new_chunk.splitlines(keepends=True)
                    lines[i:end+1] = new_lines
                    tot_eq += 1; made_change=True
                    continue
            # pas notre cas -> arrêt
            break

    if made_change:
        p.write_text("".join(lines), encoding="utf-8")
        changed_files += 1
        print(f"[STEP28-FIX] {file}")

print(f"[RESULT] step28_changed_files={changed_files} eq_total={tot_eq} pass_total={tot_pass}")
PY

echo "[STEP28] 3) Re-smoke + top erreurs"
tools/pass14_smoke_with_mapping.sh
awk -F, 'NR>1{ n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i; printf "%s: %s\n",$2,r }' "$CSV" \
  | LC_ALL=C sort | uniq -c | LC_ALL=C sort -nr | head -25
