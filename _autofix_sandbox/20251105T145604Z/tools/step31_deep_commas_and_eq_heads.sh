#!/usr/bin/env bash
set -euo pipefail
export PYTHONPATH="${PYTHONPATH:-}:$PWD"
CSV="zz-out/homog_smoke_pass14.csv"

echo "[STEP31] 0) Smoke de référence"
tools/pass14_smoke_with_mapping.sh

echo "[STEP31] 1) Deep fixer: virgules manquantes dans ()/[] + '=' dans têtes if/elif/while (robuste)"
python3 - <<'PY'
from pathlib import Path
import csv, io, tokenize, token, re, sys

CSV_PATH = Path("zz-out/homog_smoke_pass14.csv")
rows = list(csv.reader(CSV_PATH.open(encoding="utf-8")))[1:]

def reason(row):
    return ",".join(row[2:-3]) if len(row)>=6 else (row[2] if len(row)>=3 else "")

cands=set()
for r in rows:
    if len(r)<3: continue
    msg = reason(r)
    if ("SyntaxError" in msg or "IndentationError" in msg):
        p = r[0]
        if p.endswith(".py") and Path(p).exists():
            cands.add(p)

HEAD_KW = re.compile(r'^\s*(if|elif|while)\b')

def offset_table(lines):
    offs=[0]; tot=0
    for ln in lines:
        tot += len(ln)
        offs.append(tot)
    return offs

def pos_to_abs(offs, l, c):
    return offs[l-1]+c

def sanitize_backslashes(t:str)->str:
    # 1) strip trailing spaces/tabs after '\' before newline
    t = re.sub(r'\\[ \t]+(\r?\n)', r'\\\1', t)
    # 2) remove comments after '\' (they are illegal):  "\   # ...\n" -> "\n"
    t = re.sub(r'\\\s*#.*?(\r?\n)', r'\1', t)
    return t

def try_tokenize(text:str):
    rl = io.StringIO(text).readline
    try:
        return list(tokenize.generate_tokens(rl)), text, False
    except tokenize.TokenError:
        t2 = sanitize_backslashes(text)
        rl2 = io.StringIO(t2).readline
        try:
            return list(tokenize.generate_tokens(rl2)), t2, True
        except tokenize.TokenError:
            return None, text, False

def is_call_boundary(prev_tok, curr_tok):
    # prev NAME/']'/')' directly followed by '(' => function/method call; do NOT comma-insert
    if curr_tok.type==token.OP and curr_tok.string=='(':
        if prev_tok.type==token.NAME: return True
        if prev_tok.type==token.OP and prev_tok.string in (')', ']'): return True
    return False

def deep_missing_commas(text:str):
    """Return (insert_positions, possibly_sanitized_text)."""
    toks, t, sanitized = try_tokenize(text)
    if toks is None:
        return [], text  # give up on this file
    lines = t.splitlines(keepends=True)
    offs = offset_table(lines)

    ATOM_TT = {token.NAME, token.NUMBER, token.STRING}
    LPAR, RPAR, LBR, RBR = '(', ')', '[', ']'
    depth_par=depth_br=0
    prev_sig=None
    inserts=[]
    for tok in toks:
        ttype, tstr, (sl,sc), (el,ec), _ = tok
        if ttype==token.OP:
            if tstr==LPAR: depth_par+=1
            elif tstr==RPAR: depth_par=max(0, depth_par-1)
            elif tstr==LBR: depth_br+=1
            elif tstr==RBR: depth_br=max(0, depth_br-1)

        if depth_par==0 and depth_br==0:
            prev_sig=None
            continue

        is_sig = (ttype in ATOM_TT) or (ttype==token.OP and tstr in (LPAR,LBR,RPAR,RBR))
        if is_sig:
            if prev_sig is not None:
                ptype, pstr, (psl,psc), (pel,pec), _ = prev_sig
                # slice between previous end and current start in *sanitized* text
                a = pos_to_abs(offs, pel, pec)
                b = pos_to_abs(offs, sl, sc)
                between = t[a:b]
                if ',' not in between:
                    # skip call boundary like "name ("
                    if not is_call_boundary(prev_sig, tok):
                        inserts.append(b)
            prev_sig = tok
        elif ttype in (token.NL, token.NEWLINE, tokenize.COMMENT):
            continue
        else:
            prev_sig=None

    return sorted(set(inserts)), t

def find_head_end(lines, i, look=300):
    """Return (end_idx, chunk_text, head_start_idx_in_chunk, colon_idx_in_chunk)."""
    OPEN, CLOSE = "([{" , ")]}"
    depth=0; sq=dq=False
    cum=[0]
    for j in range(i, min(len(lines), i+look)):
        s = lines[j]; cum.append(cum[-1]+len(s))
        k=0
        while k<len(s):
            c=s[k]
            if sq:
                if c=='\\' and k+1<len(s): k+=2; continue
                if c=="'": sq=False; k+=1; continue
                k+=1; continue
            if dq:
                if c=='\\' and k+1<len(s): k+=2; continue
                if c=='"': dq=False; k+=1; continue
                k+=1; continue
            if c=='#': break
            if c in OPEN: depth+=1
            elif c in CLOSE: depth=max(0, depth-1)
            elif c==':' and depth==0:
                chunk="".join(lines[i:j+1])
                m = re.search(r'\b(if|elif|while)\b', chunk)
                return j, chunk, (m.start() if m else 0), cum[j-i]+k
            elif c=="'": sq=True
            elif c=='"': dq=True
            k+=1
    return None, None, None, None

def lone_eq_positions(head_txt):
    pos=[]; OPEN="([{"; CLOSE=")]}"
    depth=0; sq=dq=False; i=0
    while i<len(head_txt):
        c=head_txt[i]
        if sq:
            if c=='\\' and i+1<len(head_txt): i+=2; continue
            if c=="'": sq=False; i+=1; continue
            i+=1; continue
        if dq:
            if c=='\\' and i+1<len(head_txt): i+=2; continue
            if c=='"': dq=False; i+=1; continue
            i+=1; continue
        if c=='#': break
        if c in OPEN: depth+=1
        elif c in CLOSE: depth=max(0, depth-1)
        elif c=='=':
            prev=head_txt[i-1] if i>0 else ''
            nxt =head_txt[i+1] if i+1<len(head_txt) else ''
            if nxt in ('=','>') or prev in ('=','!','<','>') or (prev==':' and nxt==' '):
                i+=1; continue
            pos.append(i)
        i+=1
    return pos

def call_paren_map(head_txt):
    stack=[]; ranges=[]; i=0; sq=dq=False
    while i<len(head_txt):
        c=head_txt[i]
        if sq:
            if c=='\\' and i+1<len(head_txt): i+=2; continue
            if c=="'": sq=False; i+=1; continue
            i+=1; continue
        if dq:
            if c=='\\' and i+1<len(head_txt): i+=2; continue
            if c=='"': dq=False; i+=1; continue
            i+=1; continue
        if c=="'": sq=True; i+=1; continue
        if c=='"': dq=True; i+=1; continue
        if c=='(':
            k=i-1
            while k>=0 and head_txt[k].isspace(): k-=1
            is_call = k>=0 and (head_txt[k].isalnum() or head_txt[k] in '._])}')
            stack.append(('(', i, is_call)); i+=1; continue
        if c in ')]}' and stack:
            op, start, is_call = stack.pop()
            if op=='(' and is_call:
                ranges.append((start, i))
            i+=1; continue
        i+=1
    inside=set()
    for a,b in ranges:
        inside.update(range(a,b+1))
    return inside

def replace_eq_in_head(head_txt):
    call_inside = call_paren_map(head_txt)
    eqs=set(lone_eq_positions(head_txt))
    if not eqs: return head_txt,0
    out=[]; last=0; changed=0
    for i,ch in enumerate(head_txt):
        if i in eqs and i not in call_inside:
            out.append(head_txt[last:i]); out.append('==')
            last=i+1; changed+=1
    out.append(head_txt[last:])
    return "".join(out), changed

total_files=total_commas=total_eq=0
for path in sorted(cands):
    p=Path(path)
    text=p.read_text(encoding='utf-8')
    lines=text.splitlines(keepends=True)
    changed=False; commas=0; eqfix=0

    for _ in range(10):  # iterate a few times
        try:
            compile("".join(lines), str(p), "exec")
            break
        except SyntaxError:
            pass

        # deep commas (robuste & safe)
        t="".join(lines)
        ins, t = deep_missing_commas(t)
        if t != "".join(lines):
            lines = t.splitlines(keepends=True)
            changed=True
        if ins:
            s=list(t)
            for pos in reversed(ins):
                s.insert(pos, ',')
            t="".join(s)
            lines=t.splitlines(keepends=True)
            changed=True; commas += len(ins)
            # re-iterate after a commas round
            continue

        # '=' in heads (scan tout le fichier)
        i=0; applied=False
        while i<len(lines):
            if HEAD_KW.match(lines[i]):
                end, chunk, head_start, colon = find_head_end(lines, i)
                if end is not None:
                    head_txt = chunk[head_start:colon]
                    new_head, c = replace_eq_in_head(head_txt)
                    if c:
                        new_chunk = chunk[:head_start] + new_head + ":" + chunk[colon+1:]
                        lines[i:end+1] = new_chunk.splitlines(keepends=True)
                        changed=True; eqfix+=c; applied=True
                        i = end
            i+=1
        if not applied:
            # plus rien à tenter pour ce fichier
            break

    if changed:
        p.write_text("".join(lines), encoding='utf-8')
        total_files+=1; total_commas+=commas; total_eq+=eqfix
        print(f"[STEP31-FIX] {p}: commas+={commas} eq_in_heads+={eqfix}")

print(f"[RESULT] step31_files_changed={total_files} commas_inserted={total_commas} eq_head_changes={total_eq}")
PY

echo "[STEP31] 2) Re-smoke + top erreurs"
tools/pass14_smoke_with_mapping.sh
awk -F, 'NR>1{ n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i; printf "%s: %s\n",$2,r }' "$CSV" \
  | LC_ALL=C sort | uniq -c | LC_ALL=C sort -nr | head -25
