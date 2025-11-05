#!/usr/bin/env bash
set -euo pipefail
root="$(git rev-parse --show-toplevel)"
cd "$root"

echo "==> WIP checkpoint"
git add -A
git commit -m "WIP: before safe argparse window rebuild" || true

python3 - <<'PY'
from pathlib import Path
import re, subprocess, io, tokenize

files = subprocess.check_output(
    ["bash","-lc","git ls-files 'zz-scripts/**/plot_*.py'"]
).decode().splitlines()

# patterns
re_parser_decl = re.compile(r'^(\s*)([A-Za-z_]\w*)\s*=\s*argparse\.ArgumentParser\(', re.M)
re_parse_args_canon = lambda pvar: re.compile(rf'^\s*args\s*=\s*{re.escape(pvar)}\.parse_args\(\)\s*$', re.M)
re_parse_args_bare  = lambda pvar: re.compile(rf'^\s*{re.escape(pvar)}\.parse_args\(\)\s*$', re.M)
re_addarg_start = lambda pvar: re.compile(rf'^\s*{re.escape(pvar)}\.add_argument\(')

def ensure_import_argparse(lines):
    txt=''.join(lines)
    if 'import argparse' in txt:
        return lines
    # insérer après le dernier import si possible
    m_last = None
    for m in re.finditer(r'^(?:from\s+\S+\s+import\s+\S+|import\s+\S[^\n]*)\n', txt, re.M):
        m_last = m
    if m_last:
        insert_line = txt[:m_last.end()].count('\n')
        lines.insert(insert_line, 'import argparse\n')
    else:
        lines.insert(0, 'import argparse\n')
    return lines

def token_ok(text):
    try:
        list(tokenize.generate_tokens(io.StringIO(text).readline))
        return True
    except Exception:
        return False

def extract_window_bounds(lines, pstart_idx, pvar):
    """Trouve un 'parse_args' ; si absent, on coupe jusqu'au prochain 'if __name__' ou def/class, sinon fenêtre courte."""
    txt = ''.join(lines)
    m_canon = re_parse_args_canon(pvar).search(txt)
    m_bare  = re_parse_args_bare(pvar).search(txt)
    if m_canon:
        end_ln = txt[:m_canon.start()].count('\n')
        end_ln_incl = end_ln  # on remplacera aussi la ligne parse_args
        return pstart_idx, end_ln_incl
    if m_bare:
        end_ln = txt[:m_bare.start()].count('\n')
        end_ln_incl = end_ln
        return pstart_idx, end_ln_incl
    # fallback: coupe jusqu'au premier gros séparateur
    for i in range(pstart_idx+1, min(len(lines), pstart_idx+200)):
        if re.match(r'^\s*(if\s+__name__|def\s+|class\s+)', lines[i]):
            return pstart_idx, i-1
    return pstart_idx, min(len(lines)-1, pstart_idx+80)

def collect_add_argument_blocks(lines, start, end, pvar):
    """Récupère uniquement des blocs add_argument() bien parenthésés dans [start+1, end]."""
    out_blocks=[]
    i = start+1
    while i <= end and i < len(lines):
        if re_addarg_start(pvar).match(lines[i]):
            depth = lines[i].count('(') - lines[i].count(')')
            blk = [lines[i]]
            i += 1
            while i <= end and i < len(lines) and depth>0:
                depth += lines[i].count('(') - lines[i].count(')')
                blk.append(lines[i]); i += 1
            out_blocks.append(blk)
        else:
            i += 1
    return out_blocks

def flags_of_block(blk):
    # simple: cherche les '--xxx' sur la 1ère ligne
    f = re.findall(r"'(--[A-Za-z0-9\-]+)'", blk[0])
    if not f:
        f = re.findall(r'"(--[A-Za-z0-9\-]+)"', blk[0])
    return tuple(sorted(set(f)))

def build_canonical_adds(pvar, indent):
    can = []
    can.append(f"{indent}{pvar}.add_argument('--fmt','--format', dest='fmt', "
               "choices=['png','pdf','svg'], default=None, "
               "help='Format du fichier de sortie')\n")
    can.append(f"{indent}{pvar}.add_argument('--dpi', type=int, default=None, "
               "help='DPI pour la sauvegarde')\n")
    can.append(f"{indent}{pvar}.add_argument('--outdir', type=str, default=None, "
               "help='Dossier pour copier la figure (fallback $MCGT_OUTDIR)')\n")
    can.append(f"{indent}{pvar}.add_argument('--transparent', action='store_true', "
               "help='Fond transparent lors de la sauvegarde')\n")
    can.append(f"{indent}{pvar}.add_argument('--style', choices=['paper','talk','mono','none'], "
               "default='none', help='Style de figure (opt-in)')\n")
    can.append(f"{indent}{pvar}.add_argument('--verbose', action='store_true', "
               "help='Verbosity CLI (logs supplémentaires)')\n")
    return can

touched = 0
for fp in files:
    p = Path(fp)
    src = p.read_text(encoding='utf-8')
    m = re_parser_decl.search(src)
    if not m:
        continue
    indent, pvar = m.group(1), m.group(2)
    lines = src.splitlines(True)

    # index ligne de la déclaration parser
    parser_ln_idx = ''.join(lines)[:m.start()].count('\n')
    # borne de fin
    start, end = extract_window_bounds(lines, parser_ln_idx, pvar)

    # collecter blocs add_argument existants (propres)
    keep_blocks = collect_add_argument_blocks(lines, start, end, pvar)

    # supprimer la fenêtre actuelle (tout après la déclaration jusqu'à parse_args/bornes)
    head = lines[:start+1]
    tail = lines[end+1:]

    # nettoyer imports
    head = ensure_import_argparse(head)

    # dédoublonner les flags vs canoniques
    existing_flags = set()
    for blk in keep_blocks:
        for f in flags_of_block(blk):
            existing_flags.add(f)

    # canoniques (ajoutés si absents)
    canonical = []
    for addline in build_canonical_adds(pvar, indent):
        # détecte le flag principal de la ligne
        main_flags = re.findall(r"'(--[A-Za-z0-9\-]+)'", addline)
        main_flags += re.findall(r'"(--[A-Za-z0-9\-]+)"', addline)
        # on ajoute si aucun de ces flags n'existe déjà
        if not any(f in existing_flags for f in main_flags):
            canonical.append(addline)

    # reconstruire fenêtre sûre
    new_win = []
    # 1) blocs existants conservés tels quels
    for blk in keep_blocks:
        new_win.extend(blk if blk[-1].endswith('\n') else [blk[-1] + '\n'])
    # 2) nos canoniques
    new_win.extend(canonical)
    # 3) ligne parse_args canonique
    new_win.append(f"{indent}args = {pvar}.parse_args()\n")

    new_src = ''.join(head + new_win + tail)

    # sanity via tokenizer
    if token_ok(new_src) and new_src != src:
        p.write_text(new_src, encoding='utf-8')
        touched += 1

print({"files_touched": touched})
PY

git add -A
git commit -m "fix(cli): rebuild argparse windows safely; add --verbose; keep existing add_argument blocks" || true
git push || true

# re-smoke
: "${MCGT_OUTDIR:=}"; export MCGT_OUTDIR
tools/step11_fig_smoke_test.sh || true
