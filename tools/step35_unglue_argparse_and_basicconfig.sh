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
    print("[step35] rien à faire"); sys.exit(0)

files = [p for p in lst.read_text(encoding="utf-8").splitlines() if p and Path(p).exists()]

BASICCFG_SAFE = 'logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")'

def fix_text(s: str) -> str:
    s2 = s

    # 1) Décolle les appels argparse collés
    s2 = re.sub(r'\)\s*parser\.add_argument\(', r')\nparser.add_argument(', s2)

    # 2) Supprime les appels vides parser.add_argument()
    s2 = re.sub(r'parser\.add_argument\(\s*\)\s*', r'', s2)

    # 3) )action=  -> , action=
    s2 = re.sub(r'\)\s*action\s*=', r', action=', s2)

    # 4) normalise logging.basicConfig( … ) → appel minimal sûr
    #    - non-greedy sur le contenu
    s2 = re.sub(r'logging\.basicConfig\s*\((.*?)\)', BASICCFG_SAFE, s2, flags=re.S)

    # 5) Compacter les pass consécutifs à indent égal
    s2 = re.sub(r'(?m)^(?P<i>\s*)pass\s*\n(?:(?P=i)pass\s*\n)+', r'\g<i>pass\n', s2)

    return s2

changed = 0
for p in files:
    fp = Path(p)
    try:
        src = fp.read_text(encoding="utf-8", errors="replace")
    except Exception:
        continue
    new = fix_text(src)
    if new != src:
        fp.write_text(new, encoding="utf-8")
        changed += 1
        print(f"[STEP35-FIX] {p}")

print(f"[RESULT] step35_files_changed={changed}")
PY

tools/step32_report_remaining.sh | sed -n '1,140p' || true
