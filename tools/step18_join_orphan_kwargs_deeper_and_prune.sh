#!/usr/bin/env bash
set -euo pipefail

export PYTHONPATH="${PYTHONPATH:-}:$PWD"
CSV="zz-out/homog_smoke_pass14.csv"

echo "[STEP18] 0) Smoke de référence"
tools/pass14_smoke_with_mapping.sh

echo "[STEP18] 1) Cibler encore 'invalid syntax' + 'unmatched')' + 'invalid decimal literal'"
awk -F, 'NR>1{
  n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i;
  if (r ~ /SyntaxError: invalid syntax/ ||
      r ~ /SyntaxError: unmatched \047\)\047/ ||
      r ~ /invalid decimal literal/) print $1
}' "$CSV" | sort -u > zz-out/_step18_targets.lst || true
wc -l zz-out/_step18_targets.lst

echo "[STEP18] 2) Joins profonds de kwargs orphelins, prune des ')' fautives, nettoyage numériques"
python3 - <<'PY'
from pathlib import Path
import io, re, tokenize, unicodedata, sys

targets = Path("zz-out/_step18_targets.lst").read_text(encoding="utf-8").splitlines()
targets = [t for t in sorted(set(targets)) if t and Path(t).exists()]

KW = (
 "label|color|linewidth|alpha|ls|lw|marker(?:size)?|cmap|vmin|vmax|s|zorder|"
 "rasterized|clip_on|ha|va|fontsize|arrowprops|bbox|loc|bbox_to_anchor|"
 "bbox_transform|transform|extent|origin|aspect|capsize|elinewidth|fmt|where|"
 "stacked|bins|range|density|weights|cumulative|histtype|edgecolor|facecolor|"
 "fill|hatch"
)
RE_ORPHAN = re.compile(rf'^(?P<indent>\s*)(?P<kw>{KW})\s*=')
RE_WS_ONLY = re.compile(r'^\s*(#.*)?$')

def nfkc(s: str) -> str:
    s = unicodedata.normalize("NFKC", s)
    return (s.replace("\u2212","-").replace("\u2013","-").replace("\u2014","-")
             .replace("\u00A0","").replace("\u202F","").replace("\u2009","")
             .replace("\u066B",".").replace("\u066C","")
             .replace("\uFF0E",".").replace("\uFF0C",""))

def mask_str_comm(text: str) -> str:
    # Remplace chaînes/commentaires par des espaces (longueur conservée)
    out=list(text)
    # map (row,col) -> absolute idx
    offs=[0]
    for L in text.splitlines(True):
        offs.append(offs[-1]+len(L))
    def apos(r,c): return offs[r-1]+c
    try:
        toks=list(tokenize.generate_tokens(io.StringIO(text).readline))
    except Exception:
        return text
    for t in toks:
        if t.type in (tokenize.STRING, tokenize.COMMENT):
            s=apos(*t.start); e=apos(*t.end)
            for i in range(max(0,s), min(len(out),e)):
                out[i]=' '
    return ''.join(out)

def prune_unmatched_parens(whole: str) -> tuple[str,int]:
    m = mask_str_comm(whole)
    buf=list(whole); removed=0; bal=0
    for i,ch in enumerate(m):
        if ch=='(':
            bal+=1
        elif ch==')':
            if bal<=0:
                buf[i]=''; removed+=1
            else:
                bal-=1
    return ''.join(buf), removed

def sweep_bad_numeric_underscores(whole: str) -> tuple[str,int]:
    m = mask_str_comm(whole)
    buf=list(whole); deleted=0
    for k, ch in enumerate(m):
        if ch != '_': continue
        prev  = m[k-1] if k>0 else ''
        prev2 = m[k-2] if k>1 else ''
        nxt   = m[k+1] if k+1 < len(m) else ''
        if prev.isdigit() and (nxt.isdigit() or nxt in '.eE'):
            buf[k]=''; deleted+=1
        elif ((prev in 'eE') or (prev in '+-' and prev2 in 'eE')) and nxt.isdigit():
            buf[k]=''; deleted+=1
    return ''.join(buf), deleted

def deep_join_kwargs(txt: str) -> tuple[str,int,int]:
    lines = txt.splitlines(True)
    mfull = mask_str_comm(txt)
    mask  = mfull.splitlines(True)

    # Égaliser longueurs (source de l'IndexError rencontré)
    if len(mask) < len(lines):
        mask += [''] * (len(lines) - len(mask))
    elif len(lines) < len(mask):
        lines += [''] * (len(mask) - len(lines))

    # balances par ligne
    balances=[]
    pbal=bbl=0
    for mline in mask:
        for ch in mline:
            if ch=='(' : pbal+=1
            elif ch==')': pbal-=1
            elif ch=='[': bbl+=1
            elif ch==']': bbl-=1
        balances.append((pbal,bbl))

    changed=False; joins=0; comments=0
    i=0; LN=len(lines)
    while i < LN:
        M = mask[i] if i < len(mask) else ''
        mo = RE_ORPHAN.match(M)
        if not mo:
            i+=1; continue

        # remonter au bloc ouvert (fenêtre max 20 lignes)
        j = min(i-1, len(mask)-1, len(balances)-1)
        picked = -1; steps=0
        while j>=0 and steps<20:
            this_mask = mask[j] if j < len(mask) else ''
            if not RE_WS_ONLY.match(this_mask):
                bal = balances[j] if j < len(balances) else (0,0)
                if bal[0] > 0 or bal[1] > 0:
                    picked = j; break
            j-=1; steps+=1

        if picked>=0 and picked < len(lines):
            prev = lines[picked].rstrip('\n')
            need_comma = not re.search(r'[,\(\[\{=]\s*$', prev)
            payload = lines[i].lstrip()
            lines[picked] = prev + (', ' if need_comma else ' ') + payload
            lines[i] = ''  # absorbée
            joins+=1; changed=True
        else:
            # commenter prudemment si rien à coller
            cur = lines[i]
            if not cur.lstrip().startswith('#'):
                lines[i] = mo.group('indent') + '# ' + cur.lstrip()
                comments+=1; changed=True
        i+=1

    return (''.join(lines), joins, comments)

tot_changed=tot_joins=tot_comments=tot_pruned=tot_nums=0
for t in targets:
    p = Path(t)
    try:
        raw = p.read_text(encoding='utf-8', errors='ignore')
        txt = nfkc(raw)

        txt2, j, c = deep_join_kwargs(txt)
        txt3, pr = prune_unmatched_parens(txt2)
        txt4, nu = sweep_bad_numeric_underscores(txt3)

        if txt4 != txt:
            p.write_text(txt4, encoding='utf-8')
            print(f"[STEP18-FIX] {t}: kwargs_joined={j}, commented={c}, pruned_paren={pr}, num_us_removed={nu}")
            tot_changed+=1; tot_joins+=j; tot_comments+=c; tot_pruned+=pr; tot_nums+=nu
    except Exception as e:
        print(f"[STEP18-WARN] {t}: {type(e).__name__}: {e}", file=sys.stderr)
        continue

print(f"[RESULT] step18_changed_files={tot_changed} joins={tot_joins} comments={tot_comments} pruned_paren={tot_pruned} removed_num_unders={tot_nums}")
PY

echo "[STEP18] 3) Smoke + Top erreurs"
tools/pass14_smoke_with_mapping.sh
awk -F, 'NR>1{
  n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i;
  printf "%s: %s\n",$2,r
}' "$CSV" | LC_ALL=C sort | uniq -c | LC_ALL=C sort -nr | head -25
