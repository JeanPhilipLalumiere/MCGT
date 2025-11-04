#!/usr/bin/env bash
set -euo pipefail
export PYTHONPATH="${PYTHONPATH:-}:$PWD"

# Listes à jour
tools/pass14_smoke_with_mapping.sh >/dev/null || true
tools/step32_report_remaining.sh   >/dev/null || true

python3 - <<'PY'
from pathlib import Path
import re, sys

lst = Path("zz-out/_remaining_files.lst")
if not lst.exists():
    print("[step40] rien à faire"); sys.exit(0)
files = [p for p in lst.read_text(encoding="utf-8").splitlines() if p and Path(p).exists()]

HEADER_RE = re.compile(r'^(\s*)(def|class|if|for|while|try|with)\b.*:\s*(#.*)?$')
EXCEPT_LIKE = re.compile(r'^\s*(except|finally|elif|else)\b')

def ensure_suite_after_header(lines):
    """Si une ligne '...:' n'a pas de suite indentée, on indente la 1re ligne suivante non vide."""
    i = 0
    while i < len(lines):
        m = HEADER_RE.match(lines[i])
        if not m:
            i += 1; continue
        base = len(m.group(1).expandtabs(4))
        # Cherche la prochaine ligne non vide/non commentaire
        j = i + 1
        while j < len(lines) and (lines[j].strip() == '' or lines[j].lstrip().startswith('#')):
            j += 1
        if j >= len(lines): 
            i += 1; continue
        cur_indent = len(lines[j][:len(lines[j]) - len(lines[j].lstrip())].expandtabs(4))
        if cur_indent <= base:
            # Indente la ligne j
            lines[j] = ' ' * (base + 4) + lines[j].lstrip()
            # Cas particulier: try: → indenter en bloc jusqu’à except/finally au même niveau
            if lines[i].lstrip().startswith('try:'):
                k = j + 1
                while k < len(lines):
                    if lines[k].strip()=='':
                        k += 1; continue
                    indk = len(lines[k][:len(lines[k]) - len(lines[k].lstrip())].expandtabs(4))
                    if indk <= base and EXCEPT_LIKE.match(lines[k]):  # stop au except/finally/elif/else
                        break
                    if indk <= base:  # contenu prévu du try non indenté → on indente
                        lines[k] = ' ' * (base + 4) + lines[k].lstrip()
                    k += 1
        i += 1
    return lines

def fix_passexcept(s:str)->str:
    # "pass" collé à "except"
    s = re.sub(r'(?m)^(?P<i>\s*)pass\s*except\b', r'\g<i>pass\n\g<i>except', s)
    return s

def drop_empty_try_blocks(s:str)->str:
    # supprime try/except vides (éventuels commentaires “auto-added” tolérés)
    pat = (r'(?ms)^\s*try:\s*(?:#.*\n|\s*\n)*pass\s*\n'
           r'\s*except[^\n]*:\s*(?:#.*\n|\s*\n)*pass\s*\n?')
    return re.sub(pat, '', s)

def comment_orphan_else(lines):
    """Commente 'else:' orphelin (pas d'if/try/for/while au même niveau dans les ~8 lignes au-dessus)."""
    out = lines[:]
    for i, ln in enumerate(lines):
        m = re.match(r'^(\s*)else\s*:\s*(#.*)?$', ln)
        if not m: 
            continue
        indent = len(m.group(1).expandtabs(4))
        # regarde en arrière
        ok = False
        back = 1; seen = 0
        while i-back >= 0 and seen < 12:
            prev = lines[i-back]
            if prev.strip():
                seen += 1
                if re.match(r'^(\s*)(if|try|for|while)\b.*:\s*', prev) and \
                   len(re.match(r'^(\s*)', prev).group(1).expandtabs(4)) == indent:
                    ok = True; break
            back += 1
        if not ok:
            out[i] = m.group(1) + '# [mcgt] else: (orphelin – commenté)\n'
    return out

def dedupe_pass(lines):
    """Condense des séquences de 'pass' consécutifs."""
    out = []
    prev_pass = False
    for ln in lines:
        if ln.lstrip().startswith('pass'):
            if prev_pass:
                continue
            prev_pass = True
            out.append(ln)
        else:
            prev_pass = False
            out.append(ln)
    return out

def ensure_main_has_body(lines):
    """Ajoute/assure un corps indenté après if __name__ == '__main__':"""
    out = []
    i = 0
    while i < len(lines):
        out.append(lines[i])
        m = re.match(r'^(\s*)if\s+__name__\s*==\s*[\'"]__main__[\'"]\s*:\s*(#.*)?$', lines[i])
        if m:
            base = len(m.group(1).expandtabs(4))
            j = i + 1
            # Cherche 1re ligne “réelle”
            while j < len(lines) and (lines[j].strip()=='' or lines[j].lstrip().startswith('#')):
                out.append(lines[j]); j += 1
            if j >= len(lines) or len(lines[j][:len(lines[j]) - len(lines[j].lstrip())].expandtabs(4)) <= base:
                out.append(' ' * (base + 4) + 'pass\n')
            i = j
            continue
        i += 1
    return out

changed = 0
for p in files:
    fp = Path(p)
    try:
        s = fp.read_text(encoding='utf-8', errors='replace')
        s = fix_passexcept(s)
        s = drop_empty_try_blocks(s)
        lines = s.splitlines(True)
        lines = ensure_suite_after_header(lines)
        lines = comment_orphan_else(lines)
        lines = dedupe_pass(lines)
        lines = ensure_main_has_body(lines)
        new = ''.join(lines)
        if new != s:
            fp.write_text(new, encoding='utf-8')
            changed += 1
            print(f"[STEP40-FIX] {p}")
    except Exception as e:
        print(f"[STEP40-WARN] {p}: {e.__class__.__name__}: {e}")

print(f"[RESULT] step40_files_changed={changed}")
PY

