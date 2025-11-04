#!/usr/bin/env bash
set -euo pipefail
export PYTHONPATH="${PYTHONPATH:-}:$PWD"

# Rafraîchir le CSV + la liste restante
tools/pass14_smoke_with_mapping.sh >/dev/null || true
tools/step32_report_remaining.sh   >/dev/null || true

python3 - <<'PY'
from pathlib import Path
import re, sys

lst = Path("zz-out/_remaining_files.lst")
if not lst.exists():
    print("[step36] rien à faire"); sys.exit(0)

files = [p for p in lst.read_text(encoding="utf-8").splitlines() if p and Path(p).exists()]

BASICCFG_SAFE_TPL = '{i}logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")'

PLOT_FUNCS = r'(?:plot|loglog|semilogx|semilogy|plot_date|scatter)'

def fix_logging(s: str) -> str:
    # Remplace TOUTE la ligne basicConfig par une version sûre, en gardant l'indent.
    s2 = re.sub(r'(?m)^(?P<i>\s*)logging\.basicConfig[^\n]*$',
                lambda m: BASICCFG_SAFE_TPL.format(i=m.group('i')), s)
    return s2

def fix_plot_missing_commas(s: str) -> str:
    s2 = s
    # Cas 1: deux listes adjacentes sans virgule -> déjà corrigé par step34
    # Cas 2: virgule manquante AVANT une string après la 2e liste
    #   .plot(... [..] "...")
    s2 = re.sub(
        rf'(\.{PLOT_FUNCS}\([^)]*\])\s+(["\'])',
        r'\1, \2', s2, flags=re.S
    )
    return s2

def fix_argparse(s: str) -> str:
    s2 = s
    # Décolarisation résiduelle (au cas où)
    s2 = re.sub(r'\)\s*parser\.add_argument\(', r')\nparser.add_argument(', s2)

    # Supprime fragments orphelins de type action=...
    s2 = re.sub(r'(?m)^\s*action\s*=\s*"(?:store_true|count)"\s*,?\s*$', '', s2)

    # Supprime ", action=store_true"/", action=count" dans un appel
    s2 = re.sub(r',\s*action\s*=\s*"(?:store_true|count)"\s*,?', '', s2)

    # Ferme proprement --seed / --dpi si pas de ')'
    s2 = re.sub(r'(parser\.add_argument\(\s*"--(?:seed|dpi)"[^)\n]*?)(?=\n)',
                r'\1)', s2)

    # Nettoie les virgules finales juste avant ')'
    s2 = re.sub(r'(parser\.add_argument\([^)]*?),\s*\)', r'\1)', s2, flags=re.S)

    # Supprime les appels vides
    s2 = re.sub(r'parser\.add_argument\(\s*\)\s*', r'', s2)

    return s2

def compress_orphan_pass(s: str) -> str:
    # Supprime les 'pass' indents orphelins quand la ligne précédente significative
    # ne termine PAS par ':' (ils provoquent des IndentationError).
    lines = s.splitlines(True)
    out = []
    prev_sig = ''  # dernière ligne non vide/non commentaire
    for i,ln in enumerate(lines):
        if re.match(r'^\s*pass\s*(#.*)?\n?$', ln):
            # cherche la dernière ligne significative dans 'out' si prev_sig est vide
            ps = prev_sig
            j = len(out)-1
            while ps == '' and j >= 0:
                cand = out[j]
                if re.match(r'^\s*$', cand) or re.match(r'^\s*#', cand):
                    j -= 1
                else:
                    ps = cand.rstrip()
                    break
            ends_colon = ps.rstrip().endswith(':') if ps else False
            if not ends_colon:
                # on droppe ce pass orphelin
                continue
        out.append(ln)
        # maj prev_sig
        if not re.match(r'^\s*$', ln) and not re.match(r'^\s*#', ln):
            prev_sig = ln
    # compacte les pass consécutifs à même indent
    s2 = ''.join(out)
    s2 = re.sub(r'(?m)^(?P<i>\s*)pass\s*\n(?:(?P=i)pass\s*\n)+', r'\g<i>pass\n', s2)
    return s2

def fix_tuple_lists_commas(s: str) -> str:
    # Ajoute une virgule entre deux lignes consécutives ')' + '(' quand on est
    # à l'intérieur d'une liste [...] (problème 'steps = [ ...' sans virgules).
    out = []
    sq_depth = 0
    lines = s.splitlines(True)
    for i,ln in enumerate(lines):
        # observe la profondeur [] avant traitement du couple ln-1/ln
        if i>0:
            prev = out[-1] if out else ''
            if sq_depth>0 and re.search(r'\)\s*$', prev) and re.match(r'^\s*\(', ln):
                # insère une virgule à la fin de la ligne précédente
                prev = re.sub(r'\)\s*$', r'),', prev)
                out[-1] = prev
        out.append(ln)
        # maj profondeur []
        for ch in ln:
            if ch == '[': sq_depth += 1
            elif ch == ']': sq_depth = max(0, sq_depth-1)
    return ''.join(out)

def heal_text(s: str) -> str:
    s1 = fix_logging(s)
    s2 = fix_plot_missing_commas(s1)
    s3 = fix_argparse(s2)
    s4 = compress_orphan_pass(s3)
    s5 = fix_tuple_lists_commas(s4)
    return s5

changed = 0
for p in files:
    fp = Path(p)
    src = fp.read_text(encoding="utf-8", errors="replace")
    new = heal_text(src)
    if new != src:
        fp.write_text(new, encoding="utf-8")
        changed += 1
        print(f"[STEP36-FIX] {p}")

print(f"[RESULT] step36_files_changed={changed}")
PY

# Re-rapport des erreurs en tête pour inspection rapide
tools/step32_report_remaining.sh | sed -n '1,160p' || true
