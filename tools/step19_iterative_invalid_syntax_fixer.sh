#!/usr/bin/env bash
set -euo pipefail
export PYTHONPATH="${PYTHONPATH:-}:$PWD"
CSV="zz-out/homog_smoke_pass14.csv"

echo "[STEP19] 0) Smoke de référence"
tools/pass14_smoke_with_mapping.sh

echo "[STEP19] 1) Cibler 'invalid syntax' et 'invalid decimal literal'"
awk -F, 'NR>1{
  n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i;
  if (r ~ /SyntaxError: invalid syntax/ || r ~ /invalid decimal literal/) print $1
}' "$CSV" | sort -u > zz-out/_step19_targets.lst || true
wc -l zz-out/_step19_targets.lst

echo "[STEP19] 2) Fix itératif par ligne fautive (commas, décimaux, multiplications implicites)"
python3 - <<'PY'
from pathlib import Path
import io, sys, tokenize, re, unicodedata

targets = Path("zz-out/_step19_targets.lst").read_text(encoding="utf-8").splitlines()
targets = [t for t in sorted(set(targets)) if t and Path(t).exists()]

KW = (
 "label|color|linewidth|alpha|ls|lw|marker(?:size)?|cmap|vmin|vmax|s|zorder|"
 "rasterized|clip_on|ha|va|fontsize|arrowprops|bbox|loc|bbox_to_anchor|"
 "bbox_transform|transform|extent|origin|aspect|capsize|elinewidth|fmt|where|"
 "stacked|bins|range|density|weights|cumulative|histtype|edgecolor|facecolor|"
 "fill|hatch"
)
RE_KW_GAP = re.compile(rf'(?P<pre>[)\]\w\'"])\s+(?P<key>{KW})\s*=')
RE_PAIR_GAP = re.compile(r'(?<!:)\b([A-Za-z_]\w*|(?:\d+(?:\.\d*)?|\.\d+)|[)\]])\s+([A-Za-z_]\w*|(?:\d+(?:\.\d*)?|\.\d+)|[(\[])\b')
RE_DEC_SPACE = re.compile(r'(?<!\.)\b(\d+)\s*\.\s*(\d+)\b')
RE_DEC_DOTS  = re.compile(r'\b(\d+)\.\.(\d+)\b')
RE_BAD_UNDERS = re.compile(r'(?<!\w)(\d[\d_]*\d)_(?=[\dA-Za-z])')
RE_IMPL_MUL_1 = re.compile(r'(\d)\s*(\()')           # 2(  -> 2*(
RE_IMPL_MUL_2 = re.compile(r'([)\]])\s*(\()')        # ) ( -> )*(
RE_IMPL_MUL_3 = re.compile(r'(\d)\s*([A-Za-z_])')    # 2 x -> 2*x
RE_IMPL_MUL_4 = re.compile(r'([)\]])\s*([A-Za-z_])') # ) x -> )*x

def nfkc(s: str) -> str:
    s = unicodedata.normalize("NFKC", s)
    return (s.replace("\u2212","-").replace("\u2013","-").replace("\u2014","-")
             .replace("\u00A0","").replace("\u202F","").replace("\u2009","")
             .replace("\u066B",".").replace("\u066C","")
             .replace("\uFF0E",".").replace("\uFF0C",""))

def mask_str_comm(text: str) -> str:
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
            for i in range(max(0,s), min(len(out),e)): out[i]=' '
    return ''.join(out)

def open_depth_upto(text: str, lineno: int) -> int:
    m = mask_str_comm(text)
    depth=0
    pos = 0
    for i, ch in enumerate(m):
        if ch=='\n':
            pos += 1
            if pos>=lineno-1: break
        elif ch in '([': depth+=1
        elif ch in ')]': depth=max(0, depth-1)
    return depth

def fix_line(text: str, lineno: int) -> tuple[str,bool]:
    lines = text.splitlines(True)
    if lineno<1 or lineno>len(lines): return text, False
    depth = open_depth_upto(text, lineno)
    line = lines[lineno-1]

    # 1) Unicode/decimal normalization on the line
    new = nfkc(line)
    new = RE_DEC_SPACE.sub(r'\1.\2', new)
    new = RE_DEC_DOTS.sub(r'\1.\2', new)
    new2 = new

    # 2) If inside an open call, add missing comma before common kwargs
    if depth>0:
        new2 = RE_KW_GAP.sub(lambda m: m.group('pre') + ', ' + m.group('key') + '=', new2)

    # 3) Insert commas between simple adjacent items inside (...) or [...]
    if depth>0:
        def _comma_pair(m):
            a,b = m.group(1), m.group(2)
            # Prefer comma if we’re clearly in an arg/tuple context
            return f"{a}, {b}"
        new2 = RE_PAIR_GAP.sub(_comma_pair, new2)

    # 4) Remove bad numeric underscores and fix a few implicit multiplications
    new2 = RE_BAD_UNDERS.sub(lambda m: m.group(1).replace('_',''), new2)
    new2 = RE_IMPL_MUL_1.sub(r'\1*\2', new2)
    new2 = RE_IMPL_MUL_2.sub(r'\1*\2', new2)
    new2 = RE_IMPL_MUL_3.sub(r'\1*\2', new2)
    new2 = RE_IMPL_MUL_4.sub(r'\1*\2', new2)

    if new2!=line:
        lines[lineno-1]=new2
        return ''.join(lines), True
    return text, False

def sweep_file(p: Path) -> tuple[bool,int]:
    """Iterate compile → fix offending line, up to a cap."""
    raw = p.read_text(encoding='utf-8', errors='ignore')
    txt = nfkc(raw)
    changed = 0
    for _ in range(40):  # generous cap
        try:
            compile(txt, str(p), "exec")
            break
        except SyntaxError as e:
            if not e.lineno:
                break
            before = txt
            txt, did = fix_line(txt, e.lineno)
            if not did:
                # One more chance: also try fixing previous line if we didn’t change anything
                txt, did2 = fix_line(txt, max(1, e.lineno-1))
                if not did2:
                    break
            else:
                changed += 1
                continue
        except Exception:
            break
    if txt!=raw:
        p.write_text(txt, encoding='utf-8')
        return True, changed
    return False, 0

total_changed=0; total_fixes=0
for t in targets:
    try:
        ch, n = sweep_file(Path(t))
        if ch:
            print(f"[STEP19-FIX] {t}: fixes={n}")
            total_changed += 1; total_fixes += n
    except Exception as e:
        print(f"[STEP19-WARN] {t}: {type(e).__name__}: {e}", file=sys.stderr)

print(f"[RESULT] step19_changed_files={total_changed} total_line_fixes={total_fixes}")
PY

echo "[STEP19] 3) Smoke + Top erreurs"
tools/pass14_smoke_with_mapping.sh
awk -F, 'NR>1{ n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i; printf "%s: %s\n",$2,r }' "$CSV" \
  | LC_ALL=C sort | uniq -c | LC_ALL=C sort -nr | head -25
