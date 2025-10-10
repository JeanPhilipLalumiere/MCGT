#!/usr/bin/env bash
set -euo pipefail
export PYTHONPATH="${PYTHONPATH:-}:$PWD"
CSV="zz-out/homog_smoke_pass14.csv"

echo "[STEP28e] 0) Smoke de référence"
tools/pass14_smoke_with_mapping.sh

echo "[STEP28e] 1) Cibler: cannot-assign / '== ?' / expected body after if"
awk -F, 'NR>1{
  n=NF; r=$3; for (i=4;i<=n-3;i++) r=r","$i;
  if (r ~ /cannot assign to expression here/ ||
      r ~ /Maybe you meant '\''=='\''/ ||
      r ~ /invalid syntax\. Maybe you meant '\''==/ ||
      r ~ /IndentationError: expected an indented block after '\''if'\''/) print $1
}' "$CSV" | sort -u > zz-out/_step28e_targets.lst || true
wc -l zz-out/_step28e_targets.lst

echo "[STEP28e] 2) Fix '=' dans têtes if/elif/while (multi-ligne, hors kwargs) + 'pass' si corps manquant"
python3 - <<'PY'
from pathlib import Path
import re

targets = Path("zz-out/_step28e_targets.lst").read_text(encoding="utf-8").splitlines()
targets = [t for t in sorted(set(targets)) if t and Path(t).exists()]

OPEN, CLOSE = "([{" , ")]}"
HEAD_START = re.compile(r'^\s*(if|elif|while)\b')
NEXT_KWS   = re.compile(r'^\s*(elif|else|except|finally)\b')

def head_span(lines, i, max_look=200):
    """Return (end_line_index, head_text_including_colon)."""
    depth=sq=dq=0; acc=[]; j=i
    while j < len(lines) and j < i+max_look:
        s=lines[j]; acc.append(s); k=0
        while k < len(s):
            c=s[k]
            if sq:
                if c=="\\": k+=2; continue
                if c=="'": sq=0
            elif dq:
                if c=="\\": k+=2; continue
                if c=='"': dq=0
            else:
                if c=="#": break
                if c in OPEN: depth+=1
                elif c in CLOSE: depth=max(0, depth-1)
                elif c==':' and depth==0: return j, "".join(acc)
                elif c=="'": sq=1
                elif c=='"': dq=1
            k+=1
        j+=1
    return None, "".join(acc)

def lone_eq_positions(txt):
    """'=' not part of '==', '!=', '>=', '<=', ':=', nor '=>'."""
    pos=[]; depth=sq=dq=0
    for i,c in enumerate(txt):
        if sq:
            if c=="\\": continue
            if c=="'": sq=0
            continue
        if dq:
            if c=="\\": continue
            if c=='"': dq=0
            continue
        if c=="#": break
        if c in OPEN: depth+=1
        elif c in CLOSE: depth=max(0, depth-1)
        elif c=="'": sq=1
        elif c=='"': dq=1
        elif c=='=':
            prev = txt[i-1] if i>0 else ''
            nxt  = txt[i+1] if i+1<len(txt) else ''
            if nxt in ('=','>') or prev in ('=','!','<','>') or (prev==':' and nxt==' '):
                continue
            pos.append(i)
    return pos

def is_kwarg_of_call(txt, idx):
    """True if '=' at idx sits within (...) that look like a function call."""
    # Find the nearest unmatched '(' to the left of idx.
    stack=[]
    for j,ch in enumerate(txt[:idx+1]):
        if ch in OPEN: stack.append((ch,j))
        elif ch in CLOSE and stack: stack.pop()
    if not stack: return False
    op, open_pos = stack[-1]
    if op != '(': return False
    # Heuristic: if there's an identifier/dot/closing bracket before '(' it's probably a call.
    k=open_pos-1
    while k>=0 and txt[k].isspace(): k-=1
    return k>=0 and (txt[k].isalnum() or txt[k] in '._)]')

def replace_eq_near(head_txt, caret_col):
    cands = [p for p in lone_eq_positions(head_txt) if not is_kwarg_of_call(head_txt, p)]
    if not cands: return head_txt, 0
    eq = min(cands, key=lambda p: abs(p-caret_col))
    return head_txt[:eq] + "==" + head_txt[eq+1:], 1

def insert_pass_if_needed(lines, head_i, head_j):
    base = len(lines[head_i]) - len(lines[head_i].lstrip(" "))
    k = head_j + 1
    while k < len(lines) and (lines[k].strip()=="" or lines[k].lstrip().startswith("#")):
        k += 1
    need = (k>=len(lines) or (len(lines[k]) - len(lines[k].lstrip(" ")) <= base) or NEXT_KWS.match(lines[k]))
    if need:
        lines.insert(head_j+1, " "*(base+4) + "pass\n")
        return True
    return False

def process(file):
    p=Path(file); lines=p.read_text(encoding="utf-8").splitlines(keepends=True)
    changed=False; eqc=0; pc=0
    for _ in range(32):
        try:
            compile("".join(lines), file, "exec"); break
        except IndentationError as e:
            msg=str(e)
            if "expected an indented block after 'if' statement" in msg or \
               "expected an indented block after 'elif' statement" in msg or \
               "expected an indented block after 'while' statement" in msg:
                ln=(e.lineno or 1)-1
                i=ln
                while i>=0 and not HEAD_START.match(lines[i]): i-=1
                if i<0: break
                end, head = head_span(lines, i)
                if end is None: break
                if insert_pass_if_needed(lines, i, end):
                    changed=True; pc+=1; continue
            break
        except SyntaxError as e:
            msg=str(e)
            if ("cannot assign to expression here" in msg) or ("Maybe you meant '=='" in msg) or \
               ("invalid syntax. Maybe you meant '=='" in msg) or ("invalid syntax. Maybe you meant '==' or ':='" in msg):
                ln=(e.lineno or 1)-1; col=(e.offset or 1)-1
                i=ln
                while i>=0 and not HEAD_START.match(lines[i]): i-=1
                if i<0: break
                end, head = head_span(lines, i)
                if end is None: break
                # caret position relative to start of head
                rel = col
                for k in range(i, min(end+1, ln)):
                    rel += len(lines[k])
                new_head, patched = replace_eq_near(head, rel)
                if patched:
                    chunk="".join(lines[i:end+1])
                    pre=chunk[:len(chunk)-len(head)]
                    lines[i:end+1] = (pre + new_head).splitlines(keepends=True)
                    changed=True; eqc+=1; continue
            break
    if changed:
        p.write_text("".join(lines), encoding="utf-8")
    return changed, eqc, pc

tot_eq=tot_pass=changed=0
for f in targets:
    ok, eqa, pa = process(f)
    if ok:
        changed+=1; tot_eq+=eqa; tot_pass+=pa
        print(f"[FIX] {f} (eq+={eqa}, pass+={pa})")
print(f"[RESULT] eq_changes={tot_eq} pass_inserted={tot_pass} files_changed={changed}")
PY

echo "[STEP28e] 3) Re-smoke + top erreurs"
tools/pass14_smoke_with_mapping.sh
awk -F, 'NR>1{ n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i; printf "%s: %s\n",$2,r }' "$CSV" \
  | LC_ALL=C sort | uniq -c | LC_ALL=C sort -nr | head -25
