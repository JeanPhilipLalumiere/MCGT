#!/usr/bin/env bash
set -euo pipefail
export PYTHONPATH="${PYTHONPATH:-}:$PWD"

tools/pass14_smoke_with_mapping.sh >/dev/null || true
tools/step32_report_remaining.sh   >/dev/null || true

python3 - <<'PY'
from pathlib import Path
import re, sys

lst = Path("zz-out/_remaining_files.lst")
if not lst.exists():
    print("[step39] rien à faire"); sys.exit(0)
files = [p for p in lst.read_text(encoding="utf-8").splitlines() if p and Path(p).exists()]

BASIC = 'logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")'

def split_passexcept(s:str)->str:
    # "passexcept" -> "pass\nexcept"
    return re.sub(r'(?m)^(?P<ind>\s*)pass\s*except\b', r'\g<ind>pass\n\g<ind>except', s)

def kill_empty_try_blocks(s:str)->str:
    # try: (vide) / except: pass  -> supprime le bloc
    return re.sub(
        r'(?ms)^\s*try:\s*(?:#.*\n|\s*\n)*\s*pass\s*\n\s*except[^\n]*:\s*\n\s*pass\s*\n?',
        '', s)

def normalize_basicconfig(s:str)->str:
    # Remplace le bloc logging.basicConfig(...) (mono ou multi-ligne) par BASIC
    # IMPORTANT: pas de version "ligne seule" pour éviter les restes collés
    return re.sub(r'(?ms)^\s*logging\.basicConfig\([^)]*\)\s*', BASIC+'\n', s)

def comma_before_style(s:str)->str:
    # .plot([..], [..]  "--", ...) -> insère virgule avant la chaîne de style
    pat = (r'(\b(?:plt|ax)\.(?:plot|loglog|semilogx|semilogy)\s*'
           r'\(\s*\[[^\]]+\]\s*,\s*\[[^\]]+\]\s*)'
           r'(?P<q>["\'])'
           r'(?P<style>[-.:+x*oSD^v<>_| ]{1,4})'
           r'(?P=q)')
    return re.sub(pat, r'\1, \g<q>\g<style>\g<q>', s)

def strip_leading_comma_on_ax_lines(s:str)->str:
    # enlève une virgule en tête de ligne avant ax./plt.
    return re.sub(r'(?m)^\s*,\s*(?=(ax|plt)\.)', '', s)

def close_datapath_blocks(s:str)->str:
    # Referme "x = (Path(...\n / '...'\n / '...')" non clos par ')'
    lines = s.splitlines(True)
    out=[]; i=0
    while i < len(lines):
        ln = lines[i]
        out.append(ln)
        m = re.match(r'^(\s*\w+\s*=\s*\()(?:pathlib\.Path|Path)\b', ln)
        if not m:
            i+=1; continue
        depth = ln.count('(') - ln.count(')')
        j = i+1
        saw_slash = ('/ "' in ln or "/ '" in ln)
        while j < len(lines):
            saw_slash |= ('/ "' in lines[j] or "/ '" in lines[j])
            depth += lines[j].count('(') - lines[j].count(')')
            out.append(lines[j])
            if depth <= 0: break
            j += 1
        if depth > 0 and saw_slash:
            out[-1] = out[-1].rstrip() + ')\n'
        i = j+1
    return ''.join(out)

def ensure_main_pass(s:str)->str:
    # Ajoute un pass si le bloc __main__ est vide
    lines = s.splitlines(True)
    out=[]; n=len(lines); i=0
    while i<n:
        ln = lines[i]
        out.append(ln)
        m = re.match(r'^(\s*)if\s+__name__\s*==\s*[\'"]__main__[\'"]\s*:\s*(#.*)?\n$', ln)
        if m:
            indent = m.group(1)
            nxt = lines[i+1] if i+1<n else ''
            if not nxt.startswith(indent+'    '):
                out.append(indent+'    pass\n')
        i+=1
    return ''.join(out)

def fix_text(s:str)->str:
    s1 = split_passexcept(s)
    s2 = kill_empty_try_blocks(s1)
    s3 = normalize_basicconfig(s2)
    s4 = comma_before_style(s3)
    s5 = strip_leading_comma_on_ax_lines(s4)
    s6 = close_datapath_blocks(s5)
    s7 = ensure_main_pass(s6)
    return s7

changed = 0
for p in files:
    fp = Path(p)
    try:
        src = fp.read_text(encoding='utf-8', errors='replace')
        new = fix_text(src)
        if new != src:
            fp.write_text(new, encoding='utf-8')
            changed += 1
            print(f"[STEP39-FIX] {p}")
    except Exception as e:
        print(f"[STEP39-WARN] {p}: {e.__class__.__name__}: {e}")

print(f"[RESULT] step39_files_changed={changed}")
PY

# Rapport court
tools/step32_report_remaining.sh | sed -n '1,140p' || true
