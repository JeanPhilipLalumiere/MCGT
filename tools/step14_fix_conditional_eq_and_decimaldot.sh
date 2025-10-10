#!/usr/bin/env bash
set -euo pipefail
export PYTHONPATH="${PYTHONPATH:-}:$PWD"
CSV="zz-out/homog_smoke_pass14.csv"

echo "[STEP14] 0) Smoke de référence"
tools/pass14_smoke_with_mapping.sh

echo "[STEP14] 1) Cibler 'invalid syntax' / 'invalid decimal literal' / 'Perhaps you forgot a comma?'"
awk -F, 'NR>1{
  n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i;
  if (r ~ /invalid syntax/ || r ~ /invalid decimal literal/ || r ~ /Perhaps you forgot a comma\?/) print $1
}' "$CSV" | sort -u > zz-out/_step14_targets.lst || true
wc -l zz-out/_step14_targets.lst

echo "[STEP14] 2) Fix '=' dans if/while + points décimaux espacés + NFKC"
python3 - <<'PY'
from pathlib import Path
import io, tokenize, re, unicodedata

targets = Path("zz-out/_step14_targets.lst").read_text(encoding="utf-8").splitlines()
targets = [t for t in sorted(set(targets)) if t and Path(t).exists()]

def nfkc(s: str) -> str:
    s = unicodedata.normalize("NFKC", s)
    return (s.replace("\u2212","-").replace("\u2013","-").replace("\u2014","-")
             .replace("\u00A0","").replace("\u202F","").replace("\u2009","")
             .replace("\u066B",".").replace("\u066C","").replace("\uFF0E",".").replace("\uFF0C",""))

def mask_strings_comments(text: str) -> str:
    out = list(text)
    lines = text.splitlines(True)
    offs = [0]
    for L in lines:
        offs.append(offs[-1] + len(L))
    try:
        toks = list(tokenize.generate_tokens(io.StringIO(text).readline))
    except Exception:
        return text
    for tok in toks:
        if tok.type in (tokenize.STRING, tokenize.COMMENT):
            (srow, scol) = tok.start; (erow, ecol) = tok.end
            sidx = offs[srow-1] + scol
            eidx = offs[erow-1] + ecol
            for i in range(sidx, eidx):
                out[i] = ' '
    return ''.join(out)

def fix_line_conditional_eq(line_mask: str, line_raw: str) -> tuple[str,int]:
    # Ne traite que les lignes commençant par if/while jusqu'au ':'
    import re
    m = re.match(r'^(\s*)(if|while)\b(.*)$', line_mask)
    if not m:
        return line_raw, 0
    head = line_mask
    colon = head.find(':')
    if colon != -1:
        head = head[:colon]
    changed = 0
    chars = list(line_raw)
    i = 0
    while i < len(head):
        if head[i] == '=':
            prev = head[i-1] if i > 0 else ''
            nxt = head[i+1] if i+1 < len(head) else ''
            # Skip ==, >=, <=, !=, := (on ne touche pas aux comparaisons/assignations valides)
            if prev not in ('=', '!', '<', '>', ':') and nxt != '=':
                chars[i] = chars[i] + '='  # '=' -> '=='
                changed += 1
        i += 1
    return ''.join(chars), changed

def fix_decimal_dots(text_mask: str, text_raw: str) -> tuple[str,int]:
    patches = []
    # 1) Réduire espaces autour d'un '.' entre deux chiffres
    for m in re.finditer(r'(?<=\d)\s*\.\s*(?=\d)', text_mask):
        patches.append((m.start(), m.end(), '.'))
    # 2) Virgule décimale -> point (12,34 -> 12.34)
    for m in re.finditer(r'(?<!\w)(\d+)\s*,\s*(\d+)(?!\w)', text_mask):
        s, e = m.span()
        seg = text_raw[s:e]
        rel = seg.find(',')
        if rel >= 0:
            patches.append((s+rel, s+rel+1, '.'))
    # 3) Underscore final mal placé dans un nombre (ex: 123_.)
    for m in re.finditer(r'(?<=\d)_(?=\D)', text_mask):
        patches.append((m.start(), m.end(), ''))
    if not patches:
        return text_raw, 0
    buf = list(text_raw)
    for s, e, rep in sorted(patches, key=lambda t: t[0], reverse=True):
        buf[s:e] = list(rep)
    return ''.join(buf), len(patches)

total_changes = 0
for t in targets:
    p = Path(t)
    raw = p.read_text(encoding='utf-8', errors='ignore')
    txt = nfkc(raw)
    lines = txt.splitlines(True)
    mask = mask_strings_comments(txt).splitlines(True)
    changed = False
    count_eq = 0

    # 1) '=' dans if/while
    for idx,(lm,lr) in enumerate(zip(mask, lines)):
        new_line, c = fix_line_conditional_eq(lm, lr)
        if c:
            lines[idx] = new_line
            changed = True
            count_eq += c

    txt2 = ''.join(lines)
    # 2) Décimaux (sur tout le fichier)
    mask2 = mask_strings_comments(txt2)
    txt3, cdec = fix_decimal_dots(mask2, txt2)
    if cdec:
        changed = True

    if changed:
        p.write_text(txt3, encoding='utf-8')
        print(f"[FIX14] {t}: eq_fixes={count_eq}, decimal_patches={cdec}")
        total_changes += count_eq + cdec

print(f"[RESULT] step14_total_changes={total_changes}")
PY

echo "[STEP14] 3) Smoke + top erreurs"
tools/pass14_smoke_with_mapping.sh
awk -F, 'NR>1{
  n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i;
  printf "%s: %s\n",$2,r
}' "$CSV" | LC_ALL=C sort | uniq -c | LC_ALL=C sort -nr | head -25
