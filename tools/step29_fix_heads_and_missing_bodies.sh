#!/usr/bin/env bash
set -euo pipefail
export PYTHONPATH="${PYTHONPATH:-}:$PWD"
CSV="zz-out/homog_smoke_pass14.csv"

echo "[STEP29] 0) Smoke de référence"
tools/pass14_smoke_with_mapping.sh

echo "[STEP29] 1) Cibler fichiers avec: cannot-assign / '== ?' / invalid syntax / expected body after if"
awk -F, 'NR>1{
  n=NF; r=$3; for (i=4;i<=n-3;i++) r=r","$i;
  if (r ~ /cannot assign to expression here/ ||
      r ~ /Maybe you meant '\''=='\''/ ||
      r ~ /invalid syntax/ ||
      r ~ /IndentationError: expected an indented block after '\''(if|elif|while)'\''/) print $1
}' "$CSV" | sort -u > zz-out/_step29_targets.lst || true
wc -l zz-out/_step29_targets.lst

echo "[STEP29] 2) Remplacer '=' dans têtes if/elif/while (multi-ligne, hors kwargs) + ajouter 'pass' si corps manquant"
python3 - <<'PY'
from pathlib import Path
import re

targets = Path("zz-out/_step29_targets.lst").read_text(encoding="utf-8").splitlines()
targets = [t for t in sorted(set(targets)) if t and Path(t).exists()]

OPEN, CLOSE = "([{" , ")]}"
HEAD_START = re.compile(r'^\s*(if|elif|while)\b')
NEXT_KWS   = re.compile(r'^\s*(elif|else|except|finally)\b')

def find_head_end(lines, i, max_look=200):
    """Return (end_line_index, chunk_text, colon_idx_in_chunk) for the head ending with ':' at depth 0."""
    depth = 0; sq = False; dq = False
    # precompute cumulative lengths for chunk index math
    cum_len = [0]
    for j in range(i, min(len(lines), i+max_look)):
        cum_len.append(cum_len[-1] + len(lines[j]))
        s = lines[j]; k = 0
        while k < len(s):
            c = s[k]
            if sq:
                if c == "\\" and k+1 < len(s): k += 2; continue
                if c == "'": sq = False
                k += 1; continue
            if dq:
                if c == "\\" and k+1 < len(s): k += 2; continue
                if c == '"': dq = False
                k += 1; continue
            if c == '#': break
            if c in OPEN: depth += 1
            elif c in CLOSE: depth = max(0, depth-1)
            elif c == "'": sq = True
            elif c == '"': dq = True
            elif c == ':' and depth == 0:
                chunk = "".join(lines[i:j+1])
                colon_idx = cum_len[j-i] + k
                return j, chunk, colon_idx
            k += 1
    return None, None, None

def lone_eq_positions(txt):
    """Indices of '=' not part of ==, !=, <=, >=, :=, => and outside strings/comments."""
    pos=[]; depth=0; sq=False; dq=False
    i=0
    while i < len(txt):
        c = txt[i]
        if sq:
            if c == "\\" and i+1 < len(txt): i += 2; continue
            if c == "'": sq = False
            i += 1; continue
        if dq:
            if c == "\\" and i+1 < len(txt): i += 2; continue
            if c == '"': dq = False
            i += 1; continue
        if c == '#': break
        if c in OPEN: depth += 1
        elif c in CLOSE: depth = max(0, depth-1)
        elif c == "'": sq = True
        elif c == '"': dq = True
        elif c == '=':
            prev = txt[i-1] if i>0 else ''
            nxt  = txt[i+1] if i+1<len(txt) else ''
            if nxt in ('=','>') or prev in ('=','!','<','>') or (prev==':' and nxt==' '):
                i += 1; continue
            pos.append(i)
        i += 1
    return pos

def call_paren_map(txt):
    """Return set of indices inside parentheses that belong to a function/method call."""
    stack=[]; call_ranges=[]; i=0; sq=False; dq=False
    while i < len(txt):
        c=txt[i]
        if sq:
            if c=="\\" and i+1<len(txt): i+=2; continue
            if c=="'": sq=False
            i+=1; continue
        if dq:
            if c=="\\" and i+1<len(txt): i+=2; continue
            if c=='"': dq=False
            i+=1; continue
        if c=="'": sq=True; i+=1; continue
        if c=='"': dq=True; i+=1; continue
        if c in OPEN:
            if c=='(':
                k=i-1
                while k>=0 and txt[k].isspace(): k-=1
                is_call = k>=0 and (txt[k].isalnum() or txt[k] in '._])}')
                stack.append(('(', i, is_call))
            else:
                stack.append((c, i, False))
            i+=1; continue
        if c in CLOSE and stack:
            op, start, is_call = stack.pop()
            if op=='(' and is_call:
                call_ranges.append((start, i))
            i+=1; continue
        i+=1
    inside=set()
    for a,b in call_ranges:
        inside.update(range(a, b+1))
    return inside

def replace_eq_in_head(head_txt):
    call_inside = call_paren_map(head_txt)
    eqs = set(lone_eq_positions(head_txt))
    if not eqs: return head_txt, 0
    out=[]; last=0; changed=0
    for idx,ch in enumerate(head_txt):
        if idx in eqs and idx not in call_inside:
            out.append(head_txt[last:idx]); out.append("==")
            last = idx+1; changed += 1
    out.append(head_txt[last:])
    return "".join(out), changed

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

def fix_file(file):
    p=Path(file)
    lines=p.read_text(encoding="utf-8").splitlines(keepends=True)
    changed=False; eqc=0; pc=0

    i=0
    while i < len(lines):
        if not HEAD_START.match(lines[i]): i+=1; continue
        end, chunk, colon_idx = find_head_end(lines, i)
        if end is None: break
        # find keyword start
        m = re.search(r'\b(if|elif|while)\b', chunk)
        if not m:
            i=end+1; continue
        head_start_idx = m.start()
        head_txt = chunk[head_start_idx:colon_idx]
        new_head, c = replace_eq_in_head(head_txt)
        if c:
            new_chunk = chunk[:head_start_idx] + new_head + ":" + chunk[colon_idx+1:]
            lines[i:end+1] = new_chunk.splitlines(keepends=True)
            changed=True; eqc+=c
            # re-scan from same i (structure may have shifted)
            continue
        i=end+1

    # Add 'pass' where needed beneath conditionals
    for _ in range(32):
        try:
            compile("".join(lines), file, "exec")
            break
        except IndentationError as e:
            msg=str(e)
            if ("expected an indented block after 'if' statement" in msg or
                "expected an indented block after 'elif' statement" in msg or
                "expected an indented block after 'while' statement" in msg):
                ln=(e.lineno or 1)-1
                j=ln
                while j>=0 and not HEAD_START.match(lines[j]):
                    j-=1
                if j<0: break
                end, _, _ = find_head_end(lines, j)
                if end is None: break
                if insert_pass_if_needed(lines, j, end):
                    changed=True; pc+=1
                    continue
            break
        except SyntaxError:
            break

    if changed:
        p.write_text("".join(lines), encoding="utf-8")
    return changed, eqc, pc

tot_files=tot_eq=tot_pass=0
for f in targets:
    ch, e, pa = fix_file(f)
    if ch:
        tot_files+=1; tot_eq+=e; tot_pass+=pa
        print(f"[FIX] {f} (eq+={e}, pass+={pa})")
print(f"[RESULT] files_changed={tot_files} eq_changes={tot_eq} pass_inserted={tot_pass}")
PY

echo "[STEP29] 3) Re-smoke + top erreurs"
tools/pass14_smoke_with_mapping.sh
awk -F, 'NR>1{ n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i; printf "%s: %s\n",$2,r }' "$CSV" \
  | LC_ALL=C sort | uniq -c | LC_ALL=C sort -nr | head -25
