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
    print("[step42] rien à faire"); sys.exit(0)
files = [p for p in lst.read_text(encoding="utf-8").splitlines() if p and Path(p).exists()]

def rm_basicconfig_tail(s: str) -> str:
    # Ligne résiduelle dupliquée après basicConfig
    s = re.sub(r'(?m)^\s*s:\s*%\(\s*message\s*\)s"\)\s*$', '', s)
    return s

def fix_except_pass_indent(s: str) -> str:
    # except/finally/else/elif suivis d’un pass non indenté
    s = re.sub(r'(?m)^(\s*(?:except[^\n]*|finally|else|elif[^\n]*):\s*)\n\s*pass\b', r'\1\n    pass', s)
    return s

def split_joined_statements(s: str) -> str:
    # Insère un \n manquant entre deux statements collés: ...))_default_dir = ...
    s = re.sub(r'(\)\))\s*(_default_dir\s*=)', r'\1\n\2', s)
    return s

def fix_data_path_paren(s: str) -> str:
    # data_path = (Path(__file__).resolve().parents[2] / "a" / "b" / "c"  → ajoute ')'
    s = re.sub(
        r'(?m)^(?P<i>\s*\w+\s*=\s*\()\s*pathlib\.Path\(\s*__file__\s*\)\.resolve\(\)\.parents\[\s*\d+\s*\](?:\s*/\s*"[^\n"]+"\s*)+(?P<tail>)$',
        lambda m: m.group(0)+')',
    s)
    return s

def fix_generate_ch01_csv_arg(fp: Path, s: str) -> str:
    # zz-scripts/chapter01/generate_data_chapter01.py : reconstruire l'add_argument("--csv", ...)
    if fp.name != "generate_data_chapter01.py": return s
    pat = re.compile(
        r'(?s)parser\.add_argument\(\s*"--csv"\s*,.*?(?=parser\.add_argument\(|\Z)'
    )
    if not pat.search(s): return s
    repl = (
        'parser.add_argument(\n'
        '    "--csv",\n'
        '    type=pathlib.Path,\n'
        '    default=(pathlib.Path(__file__).resolve().parents[2]\n'
        '             / "zz-data" / "chapter01" / "01_timeline_milestones.csv"),\n'
        '    help="Chemin du CSV des jalons"\n'
        ')\n'
    )
    s = pat.sub(repl, s, count=1)
    return s

def fix_chi2col_block(s: str) -> str:
    # Remplace le bloc cassé par une compréhension correcte
    s = re.sub(
        r'(?s)chi2col\s*=\s*next\(\s*.*?for\s+c\s+in\s+chi2\*df\.columns.*?\)\s*',
        'chi2col = next(\n'
        '    (c for c in df.columns if "chi2" in c.lower()\n'
        '     and not any(k in c.lower() for k in ("d", "deriv"))),\n'
        '    None\n'
        ')\n',
        s
    )
    return s

def fix_params_else_orphan(s: str) -> str:
    # Transforme 'else:' orphelin en bloc "if not exists(...):"
    s = re.sub(
        r'(?s)(params\s*=\s*json\.load\([^\n]+\)\s*.*?\n)\s*else:\s*\n\s*pass[^\n]*\n\s*max_ep_primary\s*=\s*None\s*\n\s*max_ep_order2\s*=\s*None',
        r'\1if not os.path.exists(params_path):\n    max_ep_primary = None\n    max_ep_order2 = None',
        s
    )
    return s

def fix_pchip_open_close(s: str) -> str:
    # Assure une parenthèse fermante sur PchipInterpolator(
    s = re.sub(
        r'(?s)(PchipInterpolator\(\s*\n\s*[^()]*?\n\s*[^()]*?extrapolate=True\s*)(\n)',
        r'\1)\2',
        s
    )
    return s

def fix_pdots_main_try(s: str) -> str:
    # Réécrit le bloc final d'exécution main pour être valide
    s = re.sub(
        r'(?s)args\s*=\s*parser\.parse_args\(\)\s*\n\s*try:\s*\n\s*pass[^\n]*\n\s*except\s+Exception:\s*\n\s*pass[^\n]*\n\s*_main\(\s*args\s*\)\s*\n\s*except\s+SystemExit:',
        'args = parser.parse_args()\n'
        'try:\n'
        '    _main(args)\n'
        'except SystemExit:\n'
        '    pass\n'
        'except Exception:\n'
        '    pass',
        s
    )
    return s

def comment_bare_cli_flags(s: str) -> str:
    # Commente des lignes isolées du type  "--q0star",  (qu’on ne peut pas récupérer automatiquement)
    s = re.sub(r'(?m)^\s*"--[A-Za-z0-9][^"]*",\s*$', lambda m: '# ' + m.group(0), s)
    return s

def close_text_call_before_fig(s: str) -> str:
    # Si une ligne 'fontsize=...' est suivie de 'fig=plt.gcf()', ajoute ')'
    s = re.sub(
        r'(?m)^(?P<i>\s*fontsize\s*=\s*[0-9.]+\s*,\s*)\n(\s*fig\s*=\s*plt\.gcf\(\))',
        lambda m: m.group('i').rstrip(', ') + ')\n' + m.group(2),
        s
    )
    return s

changed = 0
for p in files:
    fp = Path(p)
    s = fp.read_text(encoding='utf-8', errors='replace')

    s2 = s
    s2 = rm_basicconfig_tail(s2)
    s2 = fix_except_pass_indent(s2)
    s2 = split_joined_statements(s2)
    s2 = fix_data_path_paren(s2)
    s2 = fix_generate_ch01_csv_arg(fp, s2)
    s2 = fix_chi2col_block(s2)
    s2 = fix_params_else_orphan(s2)
    s2 = fix_pchip_open_close(s2)
    s2 = fix_pdots_main_try(s2)
    s2 = comment_bare_cli_flags(s2)
    s2 = close_text_call_before_fig(s2)

    if s2 != s:
        fp.write_text(s2, encoding='utf-8')
        changed += 1
        print(f"[STEP42-FIX] {p}")

print(f"[RESULT] step42_files_changed={changed}")
PY
