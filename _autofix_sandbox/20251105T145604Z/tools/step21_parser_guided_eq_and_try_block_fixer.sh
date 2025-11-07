#!/usr/bin/env bash
set -euo pipefail
export PYTHONPATH="${PYTHONPATH:-}:$PWD"
CSV="zz-out/homog_smoke_pass14.csv"

echo "[STEP21] 0) Smoke de référence"
tools/pass14_smoke_with_mapping.sh

echo "[STEP21] 1) Cibler: '=' en expression + IndentationError après try/if"
awk -F, 'NR>1{
  n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i;
  if (r ~ /cannot assign to expression here/ ||
      r ~ /Maybe you meant '\''=='\''/ ||
      r ~ /Maybe you meant '\''=='\'' or '\':'='\'' instead of '\''='\''/ ||
      r ~ /IndentationError: expected an indented block after '\''try'\''/ ||
      r ~ /IndentationError: expected an indented block after '\''if'\''/) print $1"|"r
}' "$CSV" > zz-out/_step21_targets_full.lst || true

cut -d'|' -f1 zz-out/_step21_targets_full.lst | sort -u > zz-out/_step21_targets.lst || true
wc -l zz-out/_step21_targets.lst

echo "[STEP21] 2) Corrections pilotées par compile(): '=' -> '==' au caret + pass après try/if"
python3 - <<'PY'
from pathlib import Path
import io, sys, re, tokenize

FULL = Path("zz-out/_step21_targets_full.lst")
TARG = Path("zz-out/_step21_targets.lst")

if not TARG.exists():
    print("[INFO] rien à faire"); raise SystemExit(0)

targets = [p for p in sorted(set(TARG.read_text(encoding="utf-8").splitlines())) if p and Path(p).exists()]

def insert_pass_after(line_text:str)->str:
    indent = re.match(r'^([ \t]*)', line_text).group(1)
    unit = "    " if "\t" not in indent else "\t"
    return indent + unit + "pass\n"

def patch_eq_at_offset(line:str, off:int)->tuple[str,bool]:
    """off est 1-indexed (comme dans SyntaxError). Remplace un '=' isolé par '==' si approprié."""
    if off is None or off<1 or off>len(line):
        return line, False
    i = off-1
    # Si pointé juste après un espace, recule d'un cran vers '='
    if line[i-1:i] == " " and i>=1: i -= 1
    # Cherche '=' localement (±2)
    window = range(max(0,i-2), min(len(line), i+3))
    pos = None
    for j in window:
        if line[j] == '=':
            pos = j; break
    if pos is None: 
        return line, False
    # Ne pas toucher '==', '!=', '<=', '>=' ou ':='
    if (pos>0 and line[pos-1] in ('=','!','<','>',':')) or (pos+1<len(line) and line[pos+1]=='='):
        return line, False
    # Remplacement
    return line[:pos] + '==' + line[pos+1:], True

def try_fix_loop(text:str, filename:str)->tuple[str,int,int]:
    """Boucle compile -> patch -> recompile. Retourne (txt, nb_eq_fixes, nb_pass_added)."""
    arr = text.splitlines(True)
    eq_fix = 0
    pass_fix = 0
    for _ in range(50):  # borne dure
        try:
            compile(''.join(arr), filename, 'exec')
            break
        except IndentationError as e:
            msg = e.msg or ""
            ln = (e.lineno or 1)
            if "expected an indented block after 'try' statement" in msg:
                if 1 <= ln <= len(arr):
                    arr.insert(ln, insert_pass_after(arr[ln-1]))
                    pass_fix += 1
                    continue
            if "expected an indented block after 'if' statement" in msg:
                if 1 <= ln <= len(arr):
                    arr.insert(ln, insert_pass_after(arr[ln-1]))
                    pass_fix += 1
                    continue
            # autre IndentationError -> on s'arrête
            break
        except SyntaxError as e:
            msg = e.msg or ""
            ln = (e.lineno or 1)
            off = e.offset
            if ("cannot assign to expression here" in msg) or ("Maybe you meant '=='" in msg):
                if 1 <= ln <= len(arr):
                    new_line, changed = patch_eq_at_offset(arr[ln-1], off)
                    if changed:
                        arr[ln-1] = new_line
                        eq_fix += 1
                        continue
            # pas notre cas -> sortie
            break
    return ''.join(arr), eq_fix, pass_fix

tot_files = tot_eq = tot_pass = 0
for t in targets:
    p = Path(t)
    raw = p.read_text(encoding='utf-8', errors='ignore')
    fixed, ne, npass = try_fix_loop(raw, str(p))
    if fixed != raw:
        p.write_text(fixed, encoding='utf-8')
        tot_files += 1; tot_eq += ne; tot_pass += npass
        print(f"[STEP21-FIX] {t}: eq_patched={ne} pass_added={npass}")

print(f"[RESULT] step21_changed_files={tot_files} eq_total={tot_eq} pass_total={tot_pass}")
PY

echo "[STEP21] 3) Smoke + Top erreurs"
tools/pass14_smoke_with_mapping.sh
awk -F, 'NR>1{ n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i; printf "%s: %s\n",$2,r }' "$CSV" \
  | LC_ALL=C sort | uniq -c | LC_ALL=C sort -nr | head -25
