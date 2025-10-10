#!/usr/bin/env bash
set -euo pipefail
export PYTHONPATH="${PYTHONPATH:-}:$PWD"
CSV="zz-out/homog_smoke_pass14.csv"

echo "[STEP26] 0) Smoke de référence"
tools/pass14_smoke_with_mapping.sh

echo "[STEP26] 1) Cibler lignes précises pour:"
echo "          - cannot assign to expression here (== ?)"
echo "          - Maybe you meant '==' or ':=' instead of '='?"
echo "          - IndentationError: expected an indented block after 'if'"
python3 - <<'PY'
from pathlib import Path
import csv, re

CSV_PATH = Path("zz-out/homog_smoke_pass14.csv")
rows = list(csv.reader(CSV_PATH.open(encoding="utf-8")))
rows = rows[1:]  # header

def reconstruct_reason(r):
    return ",".join(r[2:-3]) if len(r) >= 6 else (r[2] if len(r)>=3 else "")

LINE_RE = re.compile(r"line\s+(\d+)\b")
targets = {}  # file -> sorted set of line numbers

for r in rows:
    if len(r) < 3: 
        continue
    file = r[1]
    reason = reconstruct_reason(r)
    if ("cannot assign to expression here" in reason or
        "Maybe you meant '=='" in reason or
        "Maybe you meant '==' or ':='" in reason or
        "IndentationError: expected an indented block after 'if'" in reason):
        m = LINE_RE.search(reason)
        if not m:
            continue
        ln = int(m.group(1))
        targets.setdefault(file, set()).add(ln)

# --- helpers to patch heads exactly where the error is reported ---
OPEN, CLOSE = "([{" , ")]}"
HEAD_START = re.compile(r'^(\s*)(if|elif|while)\b')
NEXT_KWS = re.compile(r'^\s*(elif|else|except|finally)\b')

def head_span(lines, i, max_look=60):
    """capture lines i..j jusqu'au ':' qui clôt la tête (niveau paren 0, hors chaînes)"""
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
    """renvoie indices des '=' (hors ==, !=, <=, >=, :=), hors chaînes/commentaires"""
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
    """heuristique: '=' dans () précédées d'un ident/.)/], donc probablement un appel"""
    stack=[]
    for i,ch in enumerate(head_text):
        if ch in OPEN:
            stack.append((ch,i))
        elif ch in CLOSE and stack:
            stack.pop()
        if i == eq_index:
            break
    if not stack:  # pas dans des ()
        return False
    opener, pos = stack[-1]
    if opener != '(':
        return False
    k = pos-1
    while k >= 0 and head_text[k].isspace():
        k -= 1
    if k < 0: 
        return False
    return (head_text[k].isalnum() or head_text[k] in '._)]')

def apply_eq_fixes(chunk, head_text):
    todo = [p for p in eq_positions_all(head_text) if not is_kwarg_of_call(head_text, p)]
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

changed_files=0; tot_eq=0; tot_pass=0
for file, line_nums in sorted(targets.items()):
    p = Path(file)
    text = p.read_text(encoding="utf-8")
    lines = text.splitlines(keepends=True)
    delta = 0
    did_change = False

    for ln in sorted(line_nums):   # traiter dans l'ordre croissant
        # recalage si des insertions ont déjà eu lieu
        i = max(0, min(ln-1 + delta, len(lines)-1))
        # remonter jusqu'au début d'une tête if/elif/while proche (fenêtre 20 lignes)
        start = None
        for k in range(i, max(-1, i-20), -1):
            if HEAD_START.match(lines[k]):
                start = k; break
        if start is None:
            continue
        end, head_text = head_span(lines, start)
        if end is None:
            continue
        chunk = "".join(lines[start:end+1])
        new_chunk, nfix = apply_eq_fixes(chunk, head_text)
        if nfix:
            new_lines = new_chunk.splitlines(keepends=True)
            lines[start:end+1] = new_lines
            delta += len(new_lines) - (end+1-start)
            tot_eq += nfix
            did_change = True
            end = start + len(new_lines) - 1  # recalcul pour insert_pass
        if insert_pass_if_needed(lines, start, end):
            delta += 1
            tot_pass += 1
            did_change = True

    if did_change:
        p.write_text("".join(lines), encoding="utf-8")
        changed_files += 1
        print(f"[STEP26-FIX] {file}: eq_fixes+=, pass_added+= (running totals: eq={tot_eq}, pass={tot_pass})")

print(f"[RESULT] step26_changed_files={changed_files} eq_total={tot_eq} pass_total={tot_pass}")
PY

echo "[STEP26] 2bis) Re-smoke + top erreurs"
tools/pass14_smoke_with_mapping.sh
awk -F, 'NR>1{ n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i; printf "%s: %s\n",$2,r }' "$CSV" \
  | LC_ALL=C sort | uniq -c | LC_ALL=C sort -nr | head -25
