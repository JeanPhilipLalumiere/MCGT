#!/usr/bin/env python3
from __future__ import annotations
# One-shot fixer for zz-scripts/chapter07/plot_fig04_dcs2_vs_k.py
# - Ensure `from __future__ import annotations
` is placed at the top (after shebang/encoding and optional docstring).
# - Replace the entire `if __name__ == "__main__":` tail with a clean CLI seed.
# - Create a timestamped .bak backup and verify syntax with py_compile.

import sys, re, time, py_compile
from pathlib import Path

DEFAULT_TARGET = Path('zz-scripts/chapter07/plot_fig04_dcs2_vs_k.py')

FUTLINE = 'from __future__ import annotations
\n'

CLEAN_MAIN_TAIL = (
    'if __name__ == "__main__":\n'
    '    def _mcgt_cli_seed():\n'
    '        import os, argparse, sys, traceback\n'
    '        import matplotlib as mpl\n\n'
    '        parser = argparse.ArgumentParser(description="Standard CLI seed (non-intrusif).")\n'
    '        parser.add_argument("--outdir", default=os.environ.get("MCGT_OUTDIR", ".ci-out"), '
    'help="Dossier de sortie (par défaut: .ci-out)")\n'
    '        parser.add_argument("--dry-run", action="store_true", '
    'help="Ne rien écrire, juste afficher les actions.")\n'
    '        parser.add_argument("--seed", type=int, default=None, '
    'help="Graine aléatoire (optionnelle).")\n'
    '        parser.add_argument("--force", action="store_true", '
    'help="Écraser les sorties existantes si nécessaire.")\n'
    '        parser.add_argument("-v", "--verbose", action="count", default=0, '
    'help="Verbosity cumulable (-v, -vv).")\n'
    '        parser.add_argument("--dpi", type=int, default=150, '
    'help="Figure DPI (default: 150)")\n'
    '        parser.add_argument("--format", choices=["png", "pdf", "svg"], default="png", '
    'help="Figure format")\n'
    '        parser.add_argument("--transparent", action="store_true", '
    'help="Transparent background")\n\n'
    '        args = parser.parse_args()\n'
    '        try:\n'
    '            os.makedirs(args.outdir, exist_ok=True)\n'
    '            os.environ["MCGT_OUTDIR"] = args.outdir\n'
    '            mpl.rcParams["savefig.dpi"] = args.dpi\n'
    '            mpl.rcParams["savefig.format"] = args.format\n'
    '            mpl.rcParams["savefig.transparent"] = args.transparent\n'
    '        except Exception:\n'
    '            pass\n\n'
    '        main_fn = globals().get("main")\n'
    '        if callable(main_fn):\n'
    '            try:\n'
    '                main_fn(args)\n'
    '            except SystemExit:\n'
    '                raise\n'
    '            except Exception as e:\n'
    '                print(f"[CLI seed] main() a levé: {e}", file=sys.stderr)\n'
    '                traceback.print_exc()\n\n'
    '    _mcgt_cli_seed()\n'
)

def split_header(text: str):
    lines = text.splitlines(True)
    header = []
    i = 0
    while i < len(lines):
        s = lines[i]
        if i == 0 and s.startswith('#!'):
            header.append(s); i += 1; continue
        if re.match(r'^\s*#.*coding[:=]\s*[-\w.]+', s):
            header.append(s); i += 1; continue
        break
    return header, ''.join(lines[i:])

def extract_module_docstring(body: str):
    lines = body.splitlines(True)
    i = 0
    while i < len(lines) and (lines[i].strip() == '' or lines[i].lstrip().startswith('#')):
        i += 1
    if i >= len(lines):
        return None, body
    start = lines[i].lstrip()
    if start.startswith('"""') or start.startswith("'''"):
        quote = '"""' if start.startswith('"""') else "'''"
        doc = [lines[i]]; i += 1; closed = False
        while i < len(lines):
            doc.append(lines[i])
            if quote in lines[i]:
                closed = True; i += 1; break
            i += 1
        if closed:
            return ''.join(doc), ''.join(lines[i:])
    return None, body

def ensure_future_annotations(header, doc, rest):
    rebuilt = ''.join(header)
    if doc:
        rebuilt += doc
    lines = rest.splitlines(True)
    kept = []
    for s in lines:
        if s.strip().startswith('from __future__ import annotations
'):
            continue
        kept.append(s)
    j = 0
    while j < len(kept) and (kept[j].strip() == '' or kept[j].lstrip().startswith('#')):
        rebuilt += kept[j]; j += 1
    rebuilt += FUTLINE
    rebuilt += ''.join(kept[j:])
    return rebuilt

def replace_main_tail(text: str) -> str:
    anchor = 'if __name__ == "__main__":'
    pos = text.find(anchor)
    if pos == -1:
        return text.rstrip() + '\n\n' + CLEAN_MAIN_TAIL
    return text[:pos] + CLEAN_MAIN_TAIL

def main(path: Path) -> None:
    src = path.read_text(encoding='utf-8')
    header, body = split_header(src)
    doc, rest = extract_module_docstring(body)
    rebuilt = ensure_future_annotations(header, doc, rest)
    rebuilt = replace_main_tail(rebuilt)

    stamp = time.strftime('%Y%m%dT%H%M%SZ', time.gmtime())
    backup = path.with_suffix(path.suffix + f'.bak.{stamp}') .with_name(path.name + f'.bak.{stamp}')
    # ensure backup path different from original; write backup alongside file
    backup.write_text(src, encoding='utf-8')
    path.write_text(rebuilt, encoding='utf-8')

    try:
        py_compile.compile(str(path), doraise=True)
        print(f'[ok] Patched and compiled: {path}')
        print(f'[bak] Backup saved at: {backup}')
if __name__ == '__main__':
    target = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_TARGET
    if not target.exists():
        print(f'[err] Target not found: {target}')
        sys.exit(2)
    main(target)
