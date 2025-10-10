#!/usr/bin/env bash
set -euo pipefail

export PYTHONPATH="${PYTHONPATH:-}:$PWD"
CSV="zz-out/homog_smoke_pass14.csv"

echo "[STEP13] 0) Smoke de référence"
tools/pass14_smoke_with_mapping.sh

echo "[STEP13] 1) Cibler 'invalid syntax' et 'invalid decimal literal'"
awk -F, 'NR>1{
  n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i;
  if (r ~ /SyntaxError: invalid syntax/ || r ~ /invalid decimal literal/) print $1
}' "$CSV" | sort -u > zz-out/_step13_targets.lst || true
wc -l zz-out/_step13_targets.lst

echo "[STEP13] 2) Auto-fix prudent: virgule avant args nommés (plt/ax/np usuels) + décimaux"
python3 - <<'PY'
from pathlib import Path
import io, tokenize, re, unicodedata

KW = r'(label|color|linewidth|alpha|ls|lw|marker(?:size)?|cmap|vmin|vmax|s|zorder|rasterized|clip_on|ha|va|fontsize|arrowprops|bbox|loc|bbox_to_anchor|bbox_transform|transform|extent|origin|aspect|capsize|elinewidth|fmt|where|stacked|bins|range|density|weights|cumulative|histtype|edgecolor|facecolor|fill|hatch)'
# motif: ...<token qui finit un argument><espaces>KW=
RE_KW = re.compile(rf'(?P<pre>[)\]\w\'"])(?P<ws>\s+)(?P<key>{KW})\s*=')
RE_DEC = re.compile(r'(?<!\w)(\d+)\s*,\s*(\d+)(?!\w)')

def normalize_nfkc(s: str) -> str:
    s = unicodedata.normalize("NFKC", s)
    return (s.replace("\u2212","-").replace("\u2013","-").replace("\u2014","-")
             .replace("\u00A0","").replace("\u202F","").replace("\u2009","")
             .replace("\u066B",".").replace("\u066C","").replace("\uFF0E",".").replace("\uFF0C","")
             .replace("\u00B7","."))

def masked(text: str) -> str:
    """Masque chaînes & commentaires par des espaces (longueur conservée)."""
    out = list(text)
    lines = text.splitlines(True)
    offs = []
    p=0
    for L in lines:
        offs.append(p); p += len(L)
    try:
        toks = list(tokenize.generate_tokens(io.StringIO(text).readline))
    except Exception:
        return text  # on ne change rien si tokenize échoue
    for tok in toks:
        if tok.type in (tokenize.STRING, tokenize.COMMENT):
            (srow, scol) = tok.start; (erow, ecol) = tok.end
            for row in range(srow, erow+1):
                start = scol if row == srow else 0
                end = ecol if row == erow else len(lines[row-1])
                i = offs[row-1] + start
                j = offs[row-1] + end
                for k in range(i, j):
                    out[k] = ' '
    return ''.join(out)

def apply_patches(text: str, patches):
    """Patches = [(i,j,repl), ...] appliqués en ordre inverse pour ne pas décaler."""
    buf = list(text)
    for i,j,repl in sorted(patches, key=lambda t: t[0], reverse=True):
        buf[i:j] = list(repl)
    return ''.join(buf)

targets = Path("zz-out/_step13_targets.lst").read_text(encoding="utf-8").splitlines()
targets = [t for t in sorted(set(targets)) if t and Path(t).exists()]
changed_any = False

for t in targets:
    p = Path(t)
    raw = p.read_text(encoding='utf-8', errors='ignore')
    txt = normalize_nfkc(raw)
    msk = masked(txt)
    patches = []

    # 1) Insert ', ' avant les args nommés usuels s'il manque une virgule
    for m in RE_KW.finditer(msk):
        # position de l'espace entre l'argument précédent et le mot-clé
        i, j = m.start('ws'), m.end('ws')
        # sécurité: ne pas insérer si déjà une virgule dans l'espace (cas rare)
        if ',' in txt[i:j]:
            continue
        patches.append((i, j, ', '))

    # 2) Décimaux à virgule -> point (hors chaînes/commentaires)
    for m in RE_DEC.finditer(msk):
        # remplacer exactement la virgule (la première)
        span = m.span()
        seg = txt[span[0]:span[1]]
        # retrouver la virgule dans ce segment et sa position absolue
        rel = seg.find(',')
        if rel >= 0:
            i = span[0] + rel
            patches.append((i, i+1, '.'))

    if patches:
        new_txt = apply_patches(txt, patches)
        if new_txt != raw:
            p.write_text(new_txt, encoding='utf-8')
            print(f"[AUTO*] {t} (+{len(patches)} patch{'es' if len(patches)>1 else ''})")
            changed_any = True

print(f"[RESULT] step13_changed={changed_any}")
PY

echo "[STEP13] 3) Smoke + top erreurs"
tools/pass14_smoke_with_mapping.sh
awk -F, 'NR>1{
  n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i;
  printf "%s: %s\n",$2,r
}' "$CSV" | LC_ALL=C sort | uniq -c | LC_ALL=C sort -nr | head -25
