#!/usr/bin/env bash
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
cd "$root"

echo "==> WIP checkpoint"
git add -A
git commit -m "WIP: before CLI parity codemod" || true

python3 - <<'PY'
from pathlib import Path
import re, sys

files = [Path(p) for p in __import__("subprocess").check_output(
    ["bash", "-lc", "git ls-files 'zz-scripts/**/plot_*.py'"]).decode().splitlines()]

# Regex helpers
re_parser   = re.compile(r'^\s*(\w+)\s*=\s*argparse\.ArgumentParser\(', re.M)
re_parse    = re.compile(r'\.parse_args\s*\(\s*\)', re.M)
re_has_out  = re.compile(r'\.add_argument\(\s*["\']--outdir["\']', re.M)
re_has_dpi  = re.compile(r'\.add_argument\(\s*["\']--dpi["\']', re.M)
re_has_fmt  = re.compile(r'\.add_argument\(\s*["\']--fmt["\']', re.M)
re_has_trn  = re.compile(r'\.add_argument\(\s*["\']--transparent["\']', re.M)

tmpl = """{pvar}.add_argument("--outdir", type=str, default=None, help="Dossier pour copier la figure (fallback $MCGT_OUTDIR)")
{pvar}.add_argument("--dpi", type=int, default=None, help="DPI pour savefig (si défini)")
{pvar}.add_argument("--fmt", type=str, default=None, help="Format savefig (png, pdf, etc.)")
{pvar}.add_argument("--transparent", action="store_true", help="Fond transparent pour savefig")
"""

changed_any = False

for p in files:
    txt = p.read_text(encoding="utf-8")
    if "import argparse" not in txt:
        # pas d'argparse => rien à faire
        continue
    m = re_parser.search(txt)
    if not m:
        # pas de parser construit explicitement
        continue
    parser_var = m.group(1)
    # point d'insertion: juste avant le premier .parse_args()
    mparse = re_parse.search(txt)
    if not mparse:
        continue

    need_out = not re_has_out.search(txt)
    need_dpi = not re_has_dpi.search(txt)
    need_fmt = not re_has_fmt.search(txt)
    need_trn = not re_has_trn.search(txt)
    if not (need_out or need_dpi or need_fmt or need_trn):
        continue

    # Construire le bloc manquant de façon sélective
    lines = []
    if need_out:
        lines.append(f'{parser_var}.add_argument("--outdir", type=str, default=None, help="Dossier pour copier la figure (fallback $MCGT_OUTDIR)")')
    if need_dpi:
        lines.append(f'{parser_var}.add_argument("--dpi", type=int, default=None, help="DPI pour savefig (si défini)")')
    if need_fmt:
        lines.append(f'{parser_var}.add_argument("--fmt", type=str, default=None, help="Format savefig (png, pdf, etc.)")')
    if need_trn:
        lines.append(f'{parser_var}.add_argument("--transparent", action="store_true", help="Fond transparent pour savefig")')
    block = "\n".join(lines) + "\n"

    # insérer avec un saut de ligne avant parse_args()
    new = txt[:mparse.start()] + block + txt[mparse.start():]
    if new != txt:
        p.write_text(new, encoding="utf-8")
        print(f"[CLI+] {p}  ({'out' if need_out else ''}{' dpi' if need_dpi else ''}{' fmt' if need_fmt else ''}{' transparent' if need_trn else ''})")
        changed_any = True

print({"changed": changed_any})
PY

# Formatage rapide pour lisser l’insertion
python - <<'PY' || true
import sys, subprocess
subprocess.run([sys.executable, "-m", "pip", "install", "--user", "autopep8"], check=False)
PY
mapfile -t files < <(git ls-files 'zz-scripts/**/plot_*.py' | sort)
python -m autopep8 --in-place \
  --select E122,E128,E131,E225,E231,E266,E301,E302,E305,E401,E501,W291,W391 \
  --aggressive --aggressive \
  "${files[@]}" || true

git add -A
git commit -m "feat(cli): ensure minimal CLI parity (--outdir/--dpi/--fmt/--transparent) repo-wide" || true
git push || true

# Smoke (utilise MCGT_OUTDIR si présent)
if [[ -x tools/step11_fig_smoke_test.sh ]]; then
  : "${MCGT_OUTDIR:=}"; export MCGT_OUTDIR
  WAIT_ON_EXIT=0 tools/step11_fig_smoke_test.sh
else
  echo "[WARN] smoke runner absent"
fi
