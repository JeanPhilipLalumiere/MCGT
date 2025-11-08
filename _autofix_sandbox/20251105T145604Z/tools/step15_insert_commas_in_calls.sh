#!/usr/bin/env bash
set -euo pipefail

export PYTHONPATH="${PYTHONPATH:-}:$PWD"
CSV="zz-out/homog_smoke_pass14.csv"

echo "[STEP15] 0) Smoke de référence"
tools/pass14_smoke_with_mapping.sh

echo "[STEP15] 1) Cibler 'invalid syntax' (on limite le scope)"
awk -F, 'NR>1{
  n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i;
  if (r ~ /SyntaxError: invalid syntax/) print $1
}' "$CSV" | sort -u > zz-out/_step15_targets.lst || true
wc -l zz-out/_step15_targets.lst

echo "[STEP15] 2) Insertion de virgules manquantes dans appels + fix décimaux résiduels"
python3 - <<'PY'
from pathlib import Path
import io, tokenize, re, unicodedata

targets = Path("zz-out/_step15_targets.lst").read_text(encoding="utf-8").splitlines()
targets = [t for t in sorted(set(targets)) if t and Path(t).exists()]

ALLOW_LAST = {
    # matplotlib.pyplot & axes methods courants
    'plot','scatter','hist','imshow','errorbar','fill_between','contour','contourf',
    'pcolormesh','semilogx','semilogy','loglog','axhline','axvline','axhspan','axvspan',
    'annotate','text','bar','barh','stem','stairs','violinplot','boxplot','quiver',
    'imshow','tricontour','tricontourf','tripcolor','triplot','stackplot',
    # axes setters souvent mal formés
    'set_title','set_xlabel','set_ylabel','set_xlim','set_ylim','legend',
    # misc
    'figure','subplots','add_subplot'
}
# on accepte aussi 'plt.plot', 'ax.plot', 'axs.plot' etc.
ALLOW_FULL = {f"plt.{n}" for n in ALLOW_LAST} | {f"ax.{n}" for n in ALLOW_LAST} | {f"axs.{n}" for n in ALLOW_LAST}

def nfkc(s: str) -> str:
    s = unicodedata.normalize("NFKC", s)
    return (s.replace("\u2212","-").replace("\u2013","-").replace("\u2014","-")
             .replace("\u00A0","").replace("\u202F","").replace("\u2009","")
             .replace("\u066B",".").replace("\u066C","").replace("\uFF0E",".").replace("\uFF0C",""))

def line_offsets(text: str):
    offs=[0]
    for L in text.splitlines(True):
        offs.append(offs[-1]+len(L))
    return offs

def abs_pos(offs, row, col):
    return offs[row-1]+col

def mask_str_comm(text: str) -> str:
    out=list(text)
    offs=line_offsets(text)
    try:
        toks=list(tokenize.generate_tokens(io.StringIO(text).readline))
    except Exception:
        return text
    for t in toks:
        if t.type in (tokenize.STRING, tokenize.COMMENT):
            s=abs_pos(offs,*t.start); e=abs_pos(offs,*t.end)
            for i in range(s,e): out[i]=' '
    return ''.join(out)

def collect_insertions_for_file(src: str):
    insert_at=[]  # absolute positions where to insert ','
    offs=line_offsets(src)
    try:
        toks=list(tokenize.generate_tokens(io.StringIO(src).readline))
    except Exception:
        return insert_at
    # Trouver cibles d'appel: (<name>|<name>.<name>...) '('
    i=0
    n=len(toks)
    while i<n:
        t=toks[i]
        # construire le qualifié juste avant une paren ouvrante
        if t.type==tokenize.NAME:
            j=i
            name_parts=[t.string]
            while j+2<n and toks[j+1].type==tokenize.OP and toks[j+1].string=='.' and toks[j+2].type==tokenize.NAME:
                name_parts.append(toks[j+2].string)
                j+=2
            k=j+1
            if k<n and toks[k].type==tokenize.OP and toks[k].string=='(':
                qual='.'.join(name_parts)
                last=name_parts[-1]
                if qual in ALLOW_FULL or last in ALLOW_LAST:
                    # scanner jusqu'à la ) fermante correspondante
                    depth=0
                    start_k=k
                    # on ne veut corriger qu'au NIVEAU 1 de cette paire
                    m=k
                    prev_expr_tok=None
                    last_end=None
                    while m<n:
                        tm=toks[m]
                        if tm.type==tokenize.OP and tm.string=='(':
                            depth+=1
                        elif tm.type==tokenize.OP and tm.string==')':
                            depth-=1
                            if depth==0:
                                break
                        # on est au niveau 1 quand depth==1
                        if depth==1:
                            # définir ce qui "termine" une expression
                            is_expr_end = (
                                tm.type in (tokenize.NAME, tokenize.NUMBER, tokenize.STRING)
                                or (tm.type==tokenize.OP and tm.string in (']','}',' )'.strip()))
                            )
                            is_comma = tm.type==tokenize.OP and tm.string==','
                            is_op = tm.type==tokenize.OP and tm.string not in (',',')','(')
                            if is_expr_end:
                                prev_expr_tok=tm
                                last_end=tm.end
                                # regarder le prochain "début d'expression"
                                # on cherche le prochain token non-trivial
                                p=m+1
                                while p<n and toks[p].type in (tokenize.NL, tokenize.NEWLINE, tokenize.INDENT, tokenize.DEDENT):
                                    p+=1
                                # ignorer commentaires/chaînes collées (concat littérale) -> pas de virgule
                                while p<n and toks[p].type in (tokenize.COMMENT,):
                                    p+=1
                                if p<n:
                                    tp=toks[p]
                                    is_next_start = (
                                        tp.type in (tokenize.NAME, tokenize.NUMBER, tokenize.STRING)
                                        or (tp.type==tokenize.OP and tp.string in ('(', '[', '{'))
                                    )
                                    sep_is_ok = False
                                    # vérifier s'il existe un séparateur explicite entre les deux
                                    # dans [m+1, p), s'il y a une virgule ou un opérateur "vrai", on ne touche pas
                                    for q in range(m+1, p+1):
                                        tq=toks[q]
                                        if tq.type==tokenize.OP and tq.string==',':
                                            sep_is_ok=True; break
                                        if tq.type==tokenize.OP and tq.string not in ('(',')','[',']','{','}','.'):
                                            # opérateur, donc pas un collage d'arguments
                                            sep_is_ok=True; break
                                    # cas à corriger: expr_end ... expr_start SANS séparateur
                                    if is_next_start and not sep_is_ok:
                                        # position d'insertion: juste après prev_expr_tok
                                        ins = abs_pos(offs, *prev_expr_tok.end)
                                        insert_at.append(ins)
                            # si on croise une virgule/opérateur on “oublie” l'expression précédente
                            if is_comma or is_op:
                                prev_expr_tok=None
                        m+=1
                i=j  # on saute les parties du nom déjà lues
        i+=1
    # dédoublonner et trier
    insert_at=sorted(set(insert_at))
    return insert_at

def fix_decimals_bad_underscores(text_mask: str, text_raw: str):
    patches=[]
    # underscore mal placé juste avant . ou e/E
    for m in re.finditer(r'(?<=\d)_(?=[eE\.])', text_mask):
        patches.append((m.start(), m.end(), ''))
    # underscore juste après e/E(+/-)
    for m in re.finditer(r'(?<=[eE][\+\-])_', text_mask):
        patches.append((m.start(), m.end(), ''))
    if not patches: return text_raw,0
    buf=list(text_raw)
    for s,e,rep in sorted(patches, key=lambda t:t[0], reverse=True):
        buf[s:e]=list(rep)
    return ''.join(buf), len(patches)

total_commas=0; total_files=0; total_dec=0
for t in targets:
    p=Path(t)
    raw=p.read_text(encoding='utf-8', errors='ignore')
    txt=nfkc(raw)
    # 1) insérer des virgules manquantes dans appels ciblés
    ins=collect_insertions_for_file(txt)
    if ins:
        buf=list(txt)
        for pos in reversed(ins):
            buf.insert(pos, ',')
        txt=''.join(buf)
        total_commas += len(ins)
        total_files += 1
    # 2) retouche décimaux/underscores invalides
    mask=mask_str_comm(txt)
    txt2, cdec = fix_decimals_bad_underscores(mask, txt)
    total_dec += cdec
    if ins or cdec:
        p.write_text(txt2, encoding='utf-8')
        print(f"[COMMAs] {t}: +{len(ins)} insertions, bad_dec_underscores={cdec}")

print(f"[RESULT] step15_commas={total_commas} files_changed={total_files} dec_patches={total_dec}")
PY

echo "[STEP15] 3) Smoke + Top erreurs"
tools/pass14_smoke_with_mapping.sh
awk -F, 'NR>1{
  n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i;
  printf "%s: %s\n",$2,r
}' "$CSV" | LC_ALL=C sort | uniq -c | LC_ALL=C sort -nr | head -25
