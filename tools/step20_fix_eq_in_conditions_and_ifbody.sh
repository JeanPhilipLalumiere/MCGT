#!/usr/bin/env bash
set -euo pipefail
export PYTHONPATH="${PYTHONPATH:-}:$PWD"
CSV="zz-out/homog_smoke_pass14.csv"

echo "[STEP20] 0) Smoke de référence"
tools/pass14_smoke_with_mapping.sh

echo "[STEP20] 1) Cibler fichiers avec '=' suspect en condition ou IndentationError(after if)"
awk -F, 'NR>1{
  n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i;
  if (r ~ /cannot assign to expression here/ ||
      r ~ /Maybe you meant '\''=='\''/ ||
      r ~ /Maybe you meant '\''=='\'' or '\':'='\'' instead of '\''='\''/ ||
      r ~ /IndentationError: expected an indented block after '\''if'\''/) print $1"|"r
}' "$CSV" > zz-out/_step20_targets_full.lst || true

cut -d'|' -f1 zz-out/_step20_targets_full.lst | sort -u > zz-out/_step20_targets.lst || true
wc -l zz-out/_step20_targets.lst

echo "[STEP20] 2) Patch '=' dans if/elif/while + 'pass' aux lignes fautives (token-based)"
python3 - <<'PY'
from pathlib import Path
import io, re, tokenize, unicodedata, sys

FULL = Path("zz-out/_step20_targets_full.lst")
if not FULL.exists():
    print("[INFO] rien à patcher"); raise SystemExit(0)

def nfkc(s: str) -> str:
    s = unicodedata.normalize("NFKC", s)
    return (s.replace("\u2212","-").replace("\u2013","-").replace("\u2014","-")
             .replace("\u00A0","").replace("\u202F","").replace("\u2009","")
             .replace("\u066B",".").replace("\u066C","").replace("\uFF0E",".")
             .replace("\uFF0C",""))

def abs_offsets(text: str):
    # table des offsets absolus (début de chaque ligne)
    offs=[0]; 
    for L in text.splitlines(True): offs.append(offs[-1]+len(L))
    return offs

def to_abs(offs, pos):  # pos = (row, col) 1-indexed
    r,c = pos
    r = max(1, min(r, len(offs)-1))
    return offs[r-1] + c

def fix_equals_in_heads(text: str) -> tuple[str,int]:
    """Remplace les '=' dans l'en-tête if/elif/while (jusqu'au ':', profondeur 0)."""
    src = nfkc(text)
    # tokenisation
    try:
        toks=list(tokenize.generate_tokens(io.StringIO(src).readline))
    except Exception:
        return text, 0

    offs = abs_offsets(src)
    repl = []  # (abs_start, abs_end, '==')
    i=0; n=len(toks)
    while i<n:
        t=toks[i]
        if t.type==tokenize.NAME and t.string in ('if','elif','while'):
            # avancer jusqu'au ':', profondeur 0
            depth=0; j=i+1
            while j<n:
                tj=toks[j]
                if tj.type==tokenize.OP:
                    if tj.string in '([{': depth += 1
                    elif tj.string in ')]}': depth -= 1
                    elif tj.string==':' and depth<=0:
                        break
                    elif tj.string=='=' and depth>=0:
                        # '=' isolé (les '==' arrivent en un seul token '==', donc on ne touche pas)
                        s = to_abs(offs, tj.start)
                        e = to_abs(offs, tj.end)
                        repl.append((s, e, '=='))
                j += 1
            i = j  # repartir après ce bloc
        i += 1

    if not repl:
        return text, 0

    # appliquer de la fin vers le début (offsets absolus stables)
    out = list(src)
    for s,e,val in sorted(repl, key=lambda x:x[0], reverse=True):
        out[s:e] = list(val)
    return ''.join(out), len(repl)

def collect_indent_lines() -> dict[str,set[int]]:
    need={}
    for row in FULL.read_text(encoding="utf-8").splitlines():
        if 'IndentationError: expected an indented block after \'if\'' in row:
            f = row.split('|',1)[0]
            m = re.search(r'on line (\d+)', row)
            if f and m:
                need.setdefault(f,set()).add(int(m.group(1)))
    return need

def insert_pass(txt: str, lines_to_fix: set[int]) -> tuple[str,int]:
    if not lines_to_fix: return txt,0
    arr = txt.splitlines(True)
    added=0
    for ln in sorted(lines_to_fix, reverse=True):
        if 1<=ln<=len(arr):
            head = arr[ln-1]
            indent = re.match(r'^([ \t]*)', head).group(1)
            unit = "    " if "\t" not in indent else "\t"
            arr.insert(ln, indent + unit + "pass\n")
            added += 1
    return ''.join(arr), added

targets = [p for p in sorted(set(Path("zz-out/_step20_targets.lst").read_text().splitlines())) if p and Path(p).exists()]
indent_map = collect_indent_lines()

tot_files=0; tot_eq=0; tot_pass=0
for t in targets:
    path = Path(t)
    raw = path.read_text(encoding='utf-8', errors='ignore')
    fixed, eqc = fix_equals_in_heads(raw)
    fixed2, pas = insert_pass(fixed, indent_map.get(t, set()))
    if fixed2 != raw:
        path.write_text(fixed2, encoding='utf-8')
        tot_files += 1; tot_eq += eqc; tot_pass += pas
        print(f"[STEP20-FIX] {t}: eq_fixed={eqc} pass_added={pas}")

print(f"[RESULT] step20_changed_files={tot_files} eq_total={tot_eq} pass_total={tot_pass}")
PY

echo "[STEP20] 3) Smoke + Top erreurs"
tools/pass14_smoke_with_mapping.sh
awk -F, 'NR>1{ n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i; printf "%s: %s\n",$2,r }' "$CSV" \
  | LC_ALL=C sort | uniq -c | LC_ALL=C sort -nr | head -25
