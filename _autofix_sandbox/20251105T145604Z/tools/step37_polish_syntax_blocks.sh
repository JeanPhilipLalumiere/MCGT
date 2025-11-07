#!/usr/bin/env bash
set -euo pipefail
export PYTHONPATH="${PYTHONPATH:-}:$PWD"

# Rafraîchir le CSV + la liste restante
tools/pass14_smoke_with_mapping.sh >/dev/null || true
tools/step32_report_remaining.sh   >/dev/null || true

python3 - <<'PY'
from pathlib import Path
import re, sys, traceback

lst = Path("zz-out/_remaining_files.lst")
if not lst.exists():
    print("[step37] rien à faire"); sys.exit(0)

files = [p for p in lst.read_text(encoding="utf-8").splitlines() if p and Path(p).exists()]

BASICCFG_SAFE_TPL = '{i}logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")'

def fix_basicconfig_lines(s: str) -> str:
    # Réécrit toute ligne basicConfig + nettoie traînes bizarres
    s2 = re.sub(r'(?m)^(?P<i>\s*)logging\.basicConfig[^\n]*$',
                lambda m: BASICCFG_SAFE_TPL.format(i=m.group('i')), s)
    s2 = re.sub(
        r'(?m)^(?P<i>\s*)logging\.basicConfig\(level=.*?\)\s*.*$',
        lambda m: BASICCFG_SAFE_TPL.format(i=m.group('i')), s2
    )
    return s2

def fix_triple_equals(s: str) -> str:
    # '===' -> '==' (pas de triple égal en Python)
    return s.replace('===', '==')

def fix_add_argument_calls(s: str) -> str:
    s2 = s
    # Virgule manquante avant help=
    s2 = re.sub(r'(\.add_argument\(\s*"[^"]+")\s+(help\s*=)', r'\1, \2', s2)
    # Décolle "collages" entre appels
    s2 = re.sub(r'\)\s*([\r\n]?)\s*(\w+)\.add_argument\(', r')\n\2.add_argument(', s2)
    # Supprime appels vides
    s2 = re.sub(r'(?m)^\s*\w+\.add_argument\(\s*\)\s*$', '', s2)
    s2 = re.sub(r'(?m)^\s*\w+\.add_argument\(\s*$',        '', s2)
    # Ferme une ligne simple non close
    s2 = re.sub(r'(?m)^(\s*\w+\.add_argument\([^\n\)]*)$', r'\1)', s2)
    # Nettoie ", )"
    s2 = re.sub(r'(\.add_argument\([^)]*?),\s*\)', r'\1)', s2, flags=re.S)
    # Action orpheline / inutile
    s2 = re.sub(r',\s*action\s*=\s*"(?:store_true|count)"\s*', '', s2)
    s2 = re.sub(r'(?m)^\s*action\s*=\s*"(?:store_true|count)"\s*,?\s*$', '', s2)
    return s2

def fix_for_pass_indentation(s: str) -> str:
    lines = s.splitlines(True)
    out = []
    i = 0
    n = len(lines)
    while i < n:
        ln = lines[i]
        out.append(ln)
        m = re.match(r'^(\s*)for\b.+:\s*(#.*)?\n$', ln)
        if m:
            base_indent = m.group(1)
            j = i + 1
            # trouver la prochaine ligne significative
            while j < n and re.match(r'^\s*(#.*)?\n$', lines[j]):
                out.append(lines[j])
                j += 1
            if j < n:
                next_ln = lines[j]
                if not next_ln.startswith(base_indent + "    "):
                    out.append(base_indent + "    pass\n")
            else:
                out.append(base_indent + "    pass\n")
            i = j
            continue
        i += 1
    return ''.join(out)

def fix_steps_list_closing(s: str) -> str:
    """Ferme 'steps = [' s'il manque un ']' plus loin (logic robuste, sans index out-of-range)."""
    lines = s.splitlines(True)
    i = 0
    while i < len(lines):
        ln = lines[i]
        m = re.match(r'^(\s*)steps\s*=\s*\[\s*(#.*)?\n$', ln)
        if not m:
            i += 1
            continue
        indent = m.group(1)
        depth = 1
        j = i + 1
        closed = False
        while j < len(lines):
            cur = lines[j]
            # tracking profondeur []
            for ch in cur:
                if ch == '[': depth += 1
                elif ch == ']':
                    depth -= 1
                    if depth == 0:
                        closed = True
                        break
            if closed:
                break
            j += 1
        if not closed:
            # on insère une ligne ']' à la même indentation
            insert_at = j if j <= len(lines) else len(lines)
            lines.insert(insert_at, indent + ']\n')
            i = insert_at + 1
        else:
            i = j + 1
    return ''.join(lines)

def fix_plot_style_commas(s: str) -> str:
    """
    Ajoute une virgule manquante entre le 2e vecteur et la spec de style, ex:
      .plot([..], [.. ]  "--", ...)  ->  .plot([..], [.. ], "--", ...)
    On cible .plot/.loglog (ax.* ou plt.*) et séquence ']  "...' globale.
    """
    s2 = re.sub(r'(\.(?:plot|loglog)\s*\([^\)]*\[[^\]]+\])\s+("[-+o\.\w\s:]+")',
                r'\1, \2', s)
    # Variante plus simple, globale (garde-fou)
    s2 = re.sub(r'(\[[^\]]+\])\s+("[-+o\.\w\s:]+")', r'\1, \2', s2)
    return s2

def fix_specific_numeric_glitch(s: str) -> str:
    # t_min, t_max = 1*e-6.14.0  ->  1e-6, 14.0
    return re.sub(r'\b1\*e-6\.(\d+\.\d+)\b', r'1e-6, \1', s)

def compress_orphan_pass(s: str) -> str:
    # Retire 'pass' orphelins et compresse répétitions
    lines = s.splitlines(True)
    out = []
    prev = ''
    for ln in lines:
        if re.match(r'^\s*pass\s*(#.*)?\n?$', ln):
            if not prev.rstrip().endswith(':'):
                # on jette le pass orphelin
                continue
        out.append(ln)
        if not re.match(r'^\s*$', ln) and not re.match(r'^\s*#', ln):
            prev = ln
    s2 = ''.join(out)
    s2 = re.sub(r'(?m)^(?P<i>\s*)pass\s*\n(?:(?P=i)pass\s*\n)+', r'\g<i>pass\n', s2)
    return s2

def heal_text(s: str) -> str:
    s1 = fix_basicconfig_lines(s)
    s2 = fix_triple_equals(s1)
    s3 = fix_add_argument_calls(s2)
    s4 = fix_for_pass_indentation(s3)
    s5 = fix_steps_list_closing(s4)
    s6 = fix_plot_style_commas(s5)
    s7 = fix_specific_numeric_glitch(s6)
    s8 = compress_orphan_pass(s7)
    return s8

changed = 0
for p in files:
    fp = Path(p)
    try:
        src = fp.read_text(encoding="utf-8", errors="replace")
        new = heal_text(src)
        if new != src:
            fp.write_text(new, encoding="utf-8")
            changed += 1
            print(f"[STEP37-FIX] {p}")
    except Exception as e:
        print(f"[STEP37-WARN] {p}: {e.__class__.__name__}: {e}")

print(f"[RESULT] step37_files_changed={changed}")
PY

# Re-rapport en tête pour voir ce qu'il reste
tools/step32_report_remaining.sh | sed -n '1,160p' || true
