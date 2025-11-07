#!/usr/bin/env bash
set -euo pipefail

export PYTHONPATH="${PYTHONPATH:-}:$PWD"
CSV="zz-out/homog_smoke_pass14.csv"

echo "[STEP16] 0) Smoke de référence"
tools/pass14_smoke_with_mapping.sh

echo "[STEP16] 1) Cibler 'invalid syntax' (post-STEP15)"
awk -F, 'NR>1{
  n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i;
  if (r ~ /SyntaxError: invalid syntax/) print $1
}' "$CSV" | sort -u > zz-out/_step16_targets.lst || true
wc -l zz-out/_step16_targets.lst

echo "[STEP16] 2) Insertion de virgules manquantes à l’intérieur de (...) et [...] (niveau 1) + fix numériques"
python3 - <<'PY'
from pathlib import Path
import io, tokenize, unicodedata, re

targets = Path("zz-out/_step16_targets.lst").read_text(encoding="utf-8").splitlines()
targets = [t for t in sorted(set(targets)) if t and Path(t).exists()]

OPEN = {'(' : ')', '[' : ']'}          # on évite { } pour ne pas casser les dicts
CLOSE = {v:k for k,v in OPEN.items()}

def nfkc(s: str) -> str:
    s = unicodedata.normalize("NFKC", s)
    return (s.replace("\u2212","-").replace("\u2013","-").replace("\u2014","-")
             .replace("\u00A0","").replace("\u202F","").replace("\u2009","")
             .replace("\u066B",".").replace("\u066C","").replace("\uFF0E",".").replace("\uFF0C",""))

def line_offsets(text: str):
    offs=[0]
    for L in text.splitlines(True): offs.append(offs[-1]+len(L))
    return offs

def abs_pos(offs, row, col):
    return offs[row-1]+col

def mask_str_comm(text: str) -> str:
    out=list(text); offs=line_offsets(text)
    try:
        toks=list(tokenize.generate_tokens(io.StringIO(text).readline))
    except Exception:
        return text
    for t in toks:
        if t.type in (tokenize.STRING, tokenize.COMMENT):
            s=abs_pos(offs,*t.start); e=abs_pos(offs,*t.end)
            for i in range(s,e): out[i]=' '
    return ''.join(out)

def collect_commas(text: str):
    """Insère des virgules manquantes à l’intérieur de () ou [] au niveau 1 du groupe courant."""
    offs=line_offsets(text)
    try:
        toks=list(tokenize.generate_tokens(io.StringIO(text).readline))
    except Exception:
        return []

    insert=[]
    n=len(toks)
    m=0
    stack=[]  # pile de ('(', depth_rel) ou ('[', depth_rel)
    # depth_rel=1 => on est dans le groupe courant niveau 1
    while m<n:
        t=toks[m]
        if t.type==tokenize.OP and t.string in OPEN:
            stack.append((t.string, 1))               # on entre dans un nouveau groupe
            # on mémorise l’indice d’ouverture pour ce groupe
            m+=1; prev_expr_tok=None; last_end=None
            # scanner jusqu’à sa fermeture
            inner=m
            depth=1
            while inner<n and depth>0:
                ti=toks[inner]
                if ti.type==tokenize.OP and ti.string==t.string:      # même opener -> sous-groupe
                    depth+=1
                elif ti.type==tokenize.OP and ti.string==OPEN[t.string]:
                    depth-=1
                    if depth==0: break

                # niveau relatif 1 ?
                if depth==1:
                    is_end = (
                        ti.type in (tokenize.NAME, tokenize.NUMBER, tokenize.STRING)
                        or (ti.type==tokenize.OP and ti.string in (']',')'))
                    )
                    is_comma = (ti.type==tokenize.OP and ti.string==',')
                    is_real_op = (ti.type==tokenize.OP and ti.string not in (',',')','(','[',']','.'))
                    if is_end:
                        prev_expr_tok=ti
                        last_end=ti.end
                        # sauter espaces/nouveaux lignes/indentations
                        p=inner+1
                        while p<n and toks[p].type in (tokenize.NL, tokenize.NEWLINE, tokenize.INDENT, tokenize.DEDENT):
                            p+=1
                        # ignorer commentaires (déjà masqués pour pos, mais tokens existent)
                        while p<n and toks[p].type==tokenize.COMMENT:
                            p+=1
                        if p<n:
                            tp=toks[p]
                            # début plausible d’une nouvelle expression
                            begins_expr = (
                                tp.type in (tokenize.NAME, tokenize.NUMBER, tokenize.STRING)
                                or (tp.type==tokenize.OP and tp.string in ('(', '['))
                            )
                            # vérifier s’il y a un séparateur explicite entre inner et p
                            sep_ok=False
                            q=inner+1
                            while q<p:
                                tq=toks[q]
                                if tq.type==tokenize.OP and tq.string==',':
                                    sep_ok=True; break
                                if tq.type==tokenize.OP and tq.string not in ('(',')','[',']','.'):
                                    sep_ok=True; break
                                q+=1
                            if begins_expr and not sep_ok:
                                ins=abs_pos(offs, *prev_expr_tok.end)
                                insert.append(ins)
                    if is_comma or is_real_op:
                        prev_expr_tok=None
                inner+=1
            m = inner  # se placer sur la fermeture
        m+=1
    return sorted(set(insert))

def fix_bad_numeric_underscores(mask: str, raw: str):
    patches=[]
    # underscore juste avant '.' ou 'e/E'
    for m in re.finditer(r'(?<=\d)_(?=[eE\.])', mask):
        patches.append((m.start(), m.end(), ''))
    # underscore immédiatement après e/E+/- (e.g. 1e-_3)
    for m in re.finditer(r'(?<=[eE][\+\-])_', mask):
        patches.append((m.start(), m.end(), ''))
    if not patches: return raw, 0
    buf=list(raw)
    for s,e,rep in sorted(patches, key=lambda x:x[0], reverse=True):
        buf[s:e]=list(rep)
    return ''.join(buf), len(patches)

total_ins=0; total_files=0; total_dec=0
for t in targets:
    p=Path(t)
    raw=p.read_text(encoding='utf-8', errors='ignore')
    txt=nfkc(raw)
    # 1) virgules dans () et []
    ins=collect_commas(txt)
    if ins:
        buf=list(txt)
        for pos in reversed(ins):
            buf.insert(pos, ',')
        txt=''.join(buf)
        total_ins += len(ins)
        total_files += 1
    # 2) micro-fix numériques
    mask=mask_str_comm(txt)
    txt2, cdec = fix_bad_numeric_underscores(mask, txt)
    total_dec += cdec
    if ins or cdec:
        p.write_text(txt2, encoding='utf-8')
        print(f"[BRACK-COMMAs] {t}: +{len(ins)} insertions, bad_num_underscores={cdec}")

print(f"[RESULT] step16_commas={total_ins} files_changed={total_files} dec_patches={total_dec}")
PY

echo "[STEP16] 3) Smoke + Top erreurs"
tools/pass14_smoke_with_mapping.sh
awk -F, 'NR>1{
  n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i;
  printf "%s: %s\n",$2,r
}' "$CSV" | LC_ALL=C sort | uniq -c | LC_ALL=C sort -nr | head -25
