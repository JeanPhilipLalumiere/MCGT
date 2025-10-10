#!/usr/bin/env bash
set -euo pipefail

export PYTHONPATH="${PYTHONPATH:-}:$PWD"
CSV="zz-out/homog_smoke_pass14.csv"

echo "[STEP17] 0) Smoke de référence"
tools/pass14_smoke_with_mapping.sh

echo "[STEP17] 1) Cibler encore 'invalid syntax'"
awk -F, 'NR>1{
  n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i;
  if (r ~ /SyntaxError: invalid syntax/) print $1
}' "$CSV" | sort -u > zz-out/_step17_targets.lst || true
wc -l zz-out/_step17_targets.lst

echo "[STEP17] 2) Recoller les kwargs orphelins aux appels ouverts (sinon commenter) + fix numériques '_'"
python3 - <<'PY'
from pathlib import Path
import io, re, tokenize, unicodedata

targets = Path("zz-out/_step17_targets.lst").read_text(encoding="utf-8").splitlines()
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
    # remplace chaînes/commentaires par des espaces (longueur conservée)
    out=list(text)
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
            for i in range(s,e): out[i]=' '
    return ''.join(out)

def process_file(p: Path) -> tuple[bool,int,int,int]:
    raw=p.read_text(encoding='utf-8', errors='ignore')
    txt=nfkc(raw)
    lines=txt.splitlines(True)
    mask=mask_str_comm(txt).splitlines(True)

    changed=False; joins=0; comments=0

    # pré-calc du solde ()[]{} par ligne (sur version masquée)
    balances=[]
    pbal=bbl=cbl=0
    for mline in mask:
        for ch in mline:
            if ch=='(' : pbal+=1
            elif ch==')': pbal-=1
            elif ch=='[': bbl+=1
            elif ch==']': bbl-=1
            elif ch=='{': cbl+=1
            elif ch=='}': cbl-=1
        balances.append((pbal,bbl,cbl))

    for i, (L, M) in enumerate(zip(lines, mask)):
        m = RE_ORPHAN.match(M)
        if not m:
            continue

        # ligne précédente "porteuse"
        j=i-1
        while j>=0 and RE_WS_ONLY.match(mask[j]): j-=1

        in_group = (i>0) and (balances[i-1][0] > 0 or balances[i-1][1] > 0)  # '(' ou '[' ouvert
        if j>=0 and in_group:
            prev = lines[j].rstrip('\n')
            # injecte ", <kw>=..." sur la ligne précédente
            lines[j] = prev + (', ' if not re.search(r'[,\(\[\{=]\s*$', prev) else '') + lines[i].lstrip()
            lines[i] = ''  # absorbée
            joins+=1; changed=True
        else:
            # pas dans un appel: commenter prudemment
            if not lines[i].lstrip().startswith('#'):
                lines[i] = m.group('indent') + '# ' + lines[i].lstrip()
                comments+=1; changed=True

    whole=''.join(lines)

    # --- Fix underscores numériques sans look-behind ---
    mask2 = mask_str_comm(whole)
    buf = list(whole)
    deleted = 0
    for k, ch in enumerate(mask2):
        if ch != '_':
            continue
        prev  = mask2[k-1] if k>0 else ''
        prev2 = mask2[k-2] if k>1 else ''
        nxt   = mask2[k+1] if k+1 < len(mask2) else ''
        # cas 1: digit _ (digit|.|e|E)
        if prev.isdigit() and (nxt.isdigit() or nxt in '.eE'):
            buf[k] = '' ; deleted += 1
        # cas 2: 1e_3  ou 1e+_3  (underscore juste après e/E ou après signe suivant e/E)
        elif ((prev in 'eE') or (prev in '+-' and prev2 in 'eE')) and nxt.isdigit():
            buf[k] = '' ; deleted += 1
    if deleted:
        whole = ''.join(buf); changed=True

    if changed:
        p.write_text(whole, encoding='utf-8')

    return changed, joins, comments, deleted

tot_changed=tot_joins=tot_comments=tot_del=0
for t in targets:
    ch,j,c,d = process_file(Path(t))
    if ch:
        print(f"[KW-JOIN] {t}: joined={j}, commented={c}, num_us_unders_removed={d}")
        tot_changed+=1; tot_joins+=j; tot_comments+=c; tot_del+=d

print(f"[RESULT] step17_changed_files={tot_changed} joined={tot_joins} commented={tot_comments} removed_num_unders={tot_del}")
PY

echo "[STEP17] 3) Smoke + Top erreurs"
tools/pass14_smoke_with_mapping.sh
awk -F, 'NR>1{
  n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i;
  printf "%s: %s\n",$2,r
}' "$CSV" | LC_ALL=C sort | uniq -c | LC_ALL=C sort -nr | head -25
